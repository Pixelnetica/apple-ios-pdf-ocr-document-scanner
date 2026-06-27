// Copyright © 2012–2026 Pixelnetica™.
//
// Part of the EasyScanner sample app for the Pixelnetica Document
// Scanning SDK. Provided as sample code: you may use, modify, and
// incorporate it into applications that integrate the SDK. Provided
// "as is", without warranty of any kind.

import CoreGraphics
import DocScanningSDK_UI
import PDFKit
import PhotosUI
import SwiftUI

/// Failure modes for `ContentModel.writeProcessedFile`. `licenseBlocked` is the only
/// case that may legitimately fall back to the watermarked `<base>-preview.png`
/// in `saveResultToTestContainer`. Every other case carries diagnostic detail
/// (path, message, stage) so a failure surfaces to the user instead of being
/// absorbed by a catch-all fallback.
///
/// `stage` is `"primary"` for single-cycle formats, `"png-intermediate"` and
/// `"pdf-final"` for the two cycles of `saveFormat == 1` (PDF-from-PNG).
enum WriteFailureReason: Error {
    case licenseBlocked( format: Int )
    case unknownSaveFormat( format: Int )
    case missingPicture
    case missingScanResultForTXT
    case openFailed( path: String, message: String, stage: String )
    case writeFailed( path: String, message: String, stage: String )
    case closeFailed( path: String, message: String, stage: String )
    case writerReturnedNil( path: String, stage: String )
    case txtWriteFailed( path: String, message: String )
}

// One-shot session warning when bundled fonts are absent. Shared by
// ContentModel and PdfReproducer: exactly one log line per app session
// regardless of how many PDFs are exported across either entry point.
// Module-internal so PdfReproducer can call it.
enum PxFontGuard {
    nonisolated(unsafe) static var fontWarningLogged = false

    static func warnOnceIfFontsMissing( _ paths: [String] ) {
        guard paths.isEmpty, !fontWarningLogged else { return }
        fontWarningLogged = true
        AppLog.pdf.notice( "PDF text layer disabled: no .ttf fonts in the demo bundle" )
    }
}

final class ContentModel: NSObject, ObservableObject {
    static let inst = ContentModel()

    // Bundled font files. Empty when the demo's `Fonts/` folder ships no
    // TTFs — at which point all four PDF writer call sites skip
    // setFonts(...) and pass nil for andTextResult/with: res so the
    // engine never hits its "fonts.empty()" throw. .ttf-only by design.
    private var bundledFontPaths: [String] {
        Bundle.main.paths( forResourcesOfType: "ttf", inDirectory: "Fonts" )
    }

    /// Wraps `img_writer.setFonts(...)` with the test override from
    /// `--uitesting-font-handling <mode>`. Returns the path-vector the engine
    /// will see; callers use that to decide whether to pass `scanResult` (non-nil
    /// only when the path-vector is non-empty, mirroring production behaviour).
    ///
    /// In production (override == nil): identical to the PxFontGuard call site.
    /// In test override: skips PxFontGuard, calls setFonts with the requested vector
    /// (or skips the call entirely for `.omit`).
    @discardableResult
    private func applyFontPolicy( to img_writer: PxImageWriter ) -> [String] {
        if let mode = AppEnvironment.shared.fontHandlingOverride {
            switch mode {
            case .present:
                let fonts = bundledFontPaths
                img_writer.setFonts( fonts )
                return fonts
            case .empty:
                img_writer.setFonts( [] )
                return []
            case .omit:
                return []
            }
        }
        // Production: call setFonts only when non-empty (existing PxFontGuard path).
        let fonts = bundledFontPaths
        PxFontGuard.warnOnceIfFontsMissing( fonts )
        if !fonts.isEmpty {
            img_writer.setFonts( fonts )
        }
        return fonts
    }

    var cutUiImage: UIImage?
    @Published var cutImage: Image?

    var binarizedUiImage: UIImage?
    @Published var binarizedImage: Image?

    var picture: PxPicture?
    var cutout: PxCutout?
    private var processed = false

    @Published var showImagePicker = false

    @Published var smartCrop  = UserDefaults.standard.bool( forKey: "cropState" )

    @Published var colorProfile = UserDefaults.standard.integer( forKey: "selectedProfile" )

    @Published var saveFormat = UserDefaults.standard.integer( forKey: "selectedSaveFormat" )
    @Published var pdfCompressionLevel = UserDefaults.standard.integer( forKey: "pdfCompressionLevel" )
    @Published var simulateMultipageFile = UserDefaults.standard.bool( forKey: "simulateMultipageFile" )

    @Published var showShareSheet = false
    var shareUrl: URL?

    @Published var showSettings = false
    @Published var showAbout = false

    // Drives the borders-editor cover. Both entry points — the manual crop
    // toolbar button and loadPicture's auto-open fallback — set this; ContentView's
    // .fullScreenCover binds to it.
    @Published var showEditor = false

    var ocrAlert = false

    @Published var showAlert = false
    var alertTitle: String?
    var alertMessage: String?

    private override init() {
    }

    public func handleAlbumButton() {
        AppAnalytics.log( .scanStarted( source: .photoLibrary ) )

        if AppEnvironment.shared.isUITesting || PHPhotoLibrary.authorizationStatus() == .authorized {
            self.showImagePicker = true
        } else {
            PHPhotoLibrary.requestAuthorization() { [self] status in
                DispatchQueue.main.async { [self] in
                    if status != .authorized {
                        AppAnalytics.log( .scanCompleted( source: .photoLibrary, result: .failure ) )
                        showError( "photo-access-denied" )
                        return
                    }

                    self.showImagePicker = true
                }
            }
        }
    }

    public func loadPhoto( _ data: Data?, _ error: Error? ) {
        // The photo-picker data callback can arrive off the main thread; hop to
        // main for analytics + UI state (@Published / SwiftUI).
        DispatchQueue.main.async {
            guard let data = data else {
                AppAnalytics.log( .scanCompleted( source: .photoLibrary, result: .failure ) )
                self.showAlert( title: "photo-image-load-error", message: error?.localizedDescription ?? "generic-unknown-error" )
                return
            }

            AppAnalytics.log( .scanCompleted( source: .photoLibrary, result: .success ) )

            self.loadPicture( PxPicture( from: data ), source: .photoLibrary )
        }
    }

    /// The user dismissed the photo-library picker without choosing an image.
    public func handlePhotoPickerCancelled() {
        AppAnalytics.log( .scanCompleted( source: .photoLibrary, result: .cancelled ) )
    }

    private(set) var lastFixtureStem: String?

    public func loadUITestFixture( index: Int ) {
        let names = [
            "ti-doc-bw-no_rot-con_back",
            "ti-doc-bw-rot-con_back",
            "ti-doc-jpn-color-rot-receipt",
        ]
        guard index >= 0, index < names.count else { return }
        guard let url = Bundle.main.url( forResource: names[index],
                                         withExtension: "png",
                                         subdirectory: "test-imageset" ),
              let data = try? Data( contentsOf: url ) else {
            showAlert( title: "photo-image-load-error", message: "fixture not found: \(names[index])" )
            return
        }
        lastFixtureStem = names[index]
        loadPhoto( data, nil )
    }

    /// Synthesises a solid-white 1024x1024 image and feeds it through `loadPhoto`
    /// as if it came from the photo library. The SDK detector returns
    /// `isDefined == false` on a plain image, so the editor opens with a
    /// full-image fallback cutout and the no-document banner is shown.
    public func loadN14NoDocFixture() {
        let size = CGSize(width: 1024, height: 1024)
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        defer { UIGraphicsEndImageContext() }
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        guard let image = UIGraphicsGetImageFromCurrentImageContext(),
              let data = image.pngData() else {
            showAlert(title: "photo-image-load-error", message: "n14 fixture: failed to synthesise image")
            return
        }
        lastFixtureStem = "n14-no-doc"
        loadPhoto(data, nil)
    }

    public func loadImage( _ image: UIImage?, cutout: PxCutout ) {
        guard let image = image else {
            showError( "camera-picture-failed" )
            return
        }
        
        DispatchQueue.main.async {
            self.loadPicture( PxPicture( image ), cutout, source: .camera )
        }
    }

    private func loadPicture( _ pic: PxPicture!, source: AnalyticsSource ) {
        return self.loadPicture( pic, nil, source: source )
    }

    private func loadPicture( _ pic: PxPicture!, _ cut: PxCutout?, source: AnalyticsSource ) {
        self.cutUiImage = nil
        self.cutImage = nil

        self.binarizedUiImage = nil
        self.binarizedImage = nil

        //OCRModel.inst.preparePicture( pic, cut )
        
        self.picture = pic

        self.processed = false
        
        autoreleasepool {
            let cut = cut ?? pic.detect()

            self.cutout = cut

            AppAnalytics.log( .borderDetected( detected: cut.isDefined, source: source ) )

            if self.smartCrop && cut.isDefined {
                processDocument()
            } else {
                AppAnalytics.log( .editorOpened( trigger: .auto ) )
                self.showEditor = true
            }
        }
    }

    public func selectColorProfile( _ color_profile: PxColorProfile ) {
        AppAnalytics.log( .colorProfileSelected( profile: Self.profileShortCode( for: color_profile ) ) )

        UserDefaults.standard.setValue( color_profile.rawValue, forKey: "selectedProfile" )
        
        self.colorProfile = Int( color_profile.rawValue )
        
        if( self.processed ) {
            processDocument( true )
        }
    }

    public func commitEditedPicture( _ image: UIImage, cutout: PxCutout ) {
        self.picture!.orientation = exifFromUIOrientation( image.imageOrientation )
        self.cutout = cutout

        processDocument()
    }
    
    private func processDocument( _ cut: Bool = false ) {
        let pic = picture!

        autoreleasepool {
            if processed {
                pic.reset()
            }

            let refine_features = PxRefineFeatures()
            
            refine_features.rectify( with: cutout!.copy() )
            
            pic.refine( refine_features )
            
            if !processed {
                OCRModel.inst.preparePicture( pic, cutout )

                processed = true
            }
            
            if !cut || self.cutUiImage == nil {
                updateCutImage( pic.extractImage() )
            }
        }

        autoreleasepool {
            let refine_features = PxRefineFeatures()
            
            let color_profile = PxColorProfile( UInt32( self.colorProfile ) )
            
            refine_features.use( color_profile, forPic: pic )
            
            pic.refine( refine_features )

            updateBinarizedImage( pic.extractImage() )
        }
    }

    public func rotateImageCCW() {
        self.rotateImage( -1 )
    }

    private func rotateImage( _ steps: Int32 ) {
        guard let pic = self.picture else { return }

        let orientation = rotateExifOrientation( pic.orientation, steps )
        
        updateOrientation( pic, orientation )
    }
    
    public func updateOrientation( _ pic: PxPicture!, _ orientation: PxOrientation ) {
        pic.orientation = orientation

        cutout!.transform( to: pic.orientation );
        cutout!.reorder();

        let ui_orientation = exifToUIOrientation( pic.orientation )

        updateCutImage( cutUiImage?.withOrientation( ui_orientation ) )
        updateBinarizedImage( binarizedUiImage?.withOrientation( ui_orientation ) )
    }
    
    private func updateCutImage( _ ui_image: UIImage? ) {
        self.cutUiImage = ui_image
        
        if let ui_image = ui_image {
            self.cutImage = Image( uiImage: ui_image )
        } else {
            self.cutImage = nil
        }
    }

    private func updateBinarizedImage( _ ui_image: UIImage? ) {
        self.binarizedUiImage = ui_image
        
        if let ui_image = ui_image {
            self.binarizedImage = Image( uiImage: ui_image )
        } else {
            self.binarizedImage = nil
        }
    }

    /// The export format token for the active save format (pdf/tiff/png/jpg/txt).
    var exportFormatToken: String { Self.formatToken( for: saveFormat ) }

    /// The PDF compression token when exporting PDF; nil for non-PDF formats.
    private var exportCompressionToken: String? {
        saveFormat == 0 ? Self.compressionToken( for: pdfCompressionLevel ) : nil
    }

    /// Pages the active export writes: 3 when simulating a multi-page file for the
    /// eligible formats (PDF / PDF-from-PNG / TIFF), otherwise 1.
    private var exportPageCount: Int {
        ( simulateMultipageFile && saveFormat <= 2 ) ? 3 : 1
    }

    public func handleShareButton() {
        switch writeProcessedFile( toDirectory: NSTemporaryDirectory(), baseName: "image" ) {
        case .success( let url ):
            AppAnalytics.log( .exportDocument( format: exportFormatToken,
                                               compression: exportCompressionToken,
                                               pageCount: exportPageCount ) )
            self.shareUrl = url
            self.showShareSheet = true
        case .failure( .missingScanResultForTXT ):
            self.ocrAlert = true
            self.showAlert = true
        case .failure( let reason ):
            // Share path has no PNG fallback by design — every failure surfaces to the user,
            // including licenseBlocked.
            showErrorForReason( reason )
        }
    }

    public func saveResultToTestContainer() {
        guard let docs = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).first else { return }

        let profileName = Self.profileDirectoryName( for: PxColorProfile( UInt32( colorProfile ) ) )
        // Group all writes from one xcodebuild test invocation under a dated subfolder.
        // The stamp arrives via --uitesting-results-wave; fall back to "current" when the
        // launch arg is absent (manual app launch under --uitesting without a test runner).
        let wave = AppEnvironment.shared.resultsWave.isEmpty ? "current" : AppEnvironment.shared.resultsWave
        let dir = docs.appendingPathComponent( "test-results" ).appendingPathComponent( wave ).appendingPathComponent( profileName )

        do {
            try FileManager.default.createDirectory( at: dir, withIntermediateDirectories: true )
        } catch {
            showError( "share-write-error", dir.path, error.localizedDescription )
            return
        }

        let baseName = makeTestResultBaseName()

        switch writeProcessedFile( toDirectory: dir.path, baseName: baseName ) {
        case .success( let url ):
            let size = Self.fileSize( at: url )
            Self.recordSavedFile( at: url, size: size, pdf: Self.pdfMirrors( for: url ) )

        case .failure( .licenseBlocked ):
            // A blocked license is the only failure that falls back to the PNG preview.
            guard let uiImage = binarizedUiImage, let data = uiImage.pngData() else { return }
            let fallbackURL = dir.appendingPathComponent( baseName + "-preview.png" )
            do {
                try data.write( to: fallbackURL )
                Self.recordSavedFile( at: fallbackURL, size: data.count,
                                      pdf: ( pageCount: 0, magicValid: false, textChars: 0 ) )
            } catch {
                // Best effort; mirrors stay at their previous values for the test to notice.
            }

        case .failure( .missingScanResultForTXT ):
            self.ocrAlert = true
            self.showAlert = true

        case .failure( let reason ):
            // EndPDF, open errors, exceptions etc. surface to the user.
            // A catch-all fallback here would mask real write failures.
            showErrorForReason( reason )
        }
    }

    private static func fileSize( at url: URL ) -> Int {
        let attrs = try? FileManager.default.attributesOfItem( atPath: url.path )
        return ( attrs?[ .size ] as? NSNumber )?.intValue ?? 0
    }

    private static func pdfMirrors( for url: URL ) -> ( pageCount: Int, magicValid: Bool, textChars: Int ) {
        guard url.pathExtension.lowercased() == "pdf" else { return ( 0, false, 0 ) }

        let magicValid: Bool = {
            guard let fh = try? FileHandle( forReadingFrom: url ) else { return false }
            defer { try? fh.close() }
            let head = ( try? fh.read( upToCount: 5 ) ) ?? Data()
            return head == Data( "%PDF-".utf8 )
        }()

        let pageCount = CGPDFDocument( url as CFURL )?.numberOfPages ?? 0
        // Character count of selectable text extracted via PDFKit.
        // Zero = image-only PDF (engine skipped text-layer rendering);
        // > 0 = text-layer present.
        let textChars = PDFDocument( url: url )?.string?.count ?? 0
        return ( pageCount: pageCount, magicValid: magicValid, textChars: textChars )
    }

    /// All five mirror fields publish in a single main-queue update so a test cannot read
    /// a fresh `.pdf` path next to stale page-count/magic/textChars from a previous save.
    /// Non-PDF and license-fallback PNG saves explicitly pass `(0, false, 0)`.
    private static func recordSavedFile( at url: URL,
                                         size: Int,
                                         pdf: ( pageCount: Int, magicValid: Bool, textChars: Int ) ) {
        DispatchQueue.main.async {
            AppEnvironment.shared.lastSavedFilePath = url.path
            AppEnvironment.shared.lastSavedFileSize = size
            AppEnvironment.shared.savedFilePdfPageCount = pdf.pageCount
            AppEnvironment.shared.savedFilePdfMagicValid = pdf.magicValid
            AppEnvironment.shared.savedFilePdfTextChars = pdf.textChars
        }
    }

    private func showErrorForReason( _ reason: WriteFailureReason ) {
        switch reason {
        case .licenseBlocked:
            showError( "share-license-blocked" )
        case .unknownSaveFormat( let format ):
            showError( "share-unknown-save-format", format )
        case .missingPicture:
            showError( "share-no-image" )
        case .missingScanResultForTXT:
            // Caller handles this case directly via the OCR-prompt alert; routing it here is a
            // safety net so future callers can't silently swallow it.
            self.ocrAlert = true
            self.showAlert = true
        case .openFailed( let path, let message, _ ):
            showError( "share-open-error", path, message )
        case .writeFailed( let path, let message, _ ),
             .closeFailed( let path, let message, _ ),
             .txtWriteFailed( let path, let message ):
            showError( "share-write-error", path, message )
        case .writerReturnedNil( let path, _ ):
            showError( "share-write-error", path, "writer returned nil" )
        }
    }

    private func makeTestResultBaseName() -> String {
        // The format is already carried by writeProcessedFile's extension append, so the
        // stem only needs to disambiguate within a given extension: the profile, the PDF
        // compression token (when relevant), and the -multi suffix for multi-page saves.
        let stem = lastFixtureStem ?? "result"
        let profileShort = Self.profileShortCode( for: PxColorProfile( UInt32( colorProfile ) ) )

        var parts = [stem, profileShort]

        if saveFormat == 0, let comp = Self.compressionToken( for: pdfCompressionLevel ) {
            parts.append( comp )
        }

        let multipageEligible = saveFormat <= 2
        if multipageEligible && simulateMultipageFile {
            parts.append( "multi" )
        }

        return parts.joined( separator: "-" )
    }

    private static func profileDirectoryName( for profile: PxColorProfile ) -> String {
        switch profile {
        case PxColorProfile_None:  return "original"
        case PxColorProfile_BW:    return "black-and-white"
        case PxColorProfile_Gray:  return "gray"
        case PxColorProfile_Color: return "color"
        default:                   return "unknown"
        }
    }

    static func profileShortCode( for profile: PxColorProfile ) -> String {
        switch profile {
        case PxColorProfile_None:  return "original"
        case PxColorProfile_BW:    return "bw"
        case PxColorProfile_Gray:  return "gray"
        case PxColorProfile_Color: return "color"
        default:                   return "unknown"
        }
    }

    private static func formatToken( for saveFormat: Int ) -> String {
        switch saveFormat {
        case 0: return "pdf"
        case 1: return "pdf"
        case 2: return "tiff"
        case 3: return "png"
        case 4: return "jpg"
        case 5: return "txt"
        default: return "bin"
        }
    }

    private static func compressionToken( for level: Int ) -> String? {
        if level == 0 { return "lossless" }
        if level == Int( PxImageWriter_CompressionLevel_Low.rawValue ) { return "low" }
        if level == Int( PxImageWriter_CompressionLevel_Medium.rawValue ) { return "medium" }
        if level == Int( PxImageWriter_CompressionLevel_High.rawValue ) { return "high" }
        if level == Int( PxImageWriter_CompressionLevel_Extreme.rawValue ) { return "extreme" }
        return nil
    }

    /// Writes the processed picture to disk and returns the saved URL on success or a
    /// `WriteFailureReason` on failure. **Pure**: this function does NOT raise alerts; the
    /// caller (`handleShareButton` / `saveResultToTestContainer`) decides how to surface the
    /// outcome. The `<base>-preview.png` fallback is gated on `.licenseBlocked` only —
    /// every other failure must reach the user via `showErrorForReason`.
    private func writeProcessedFile( toDirectory dirPath: String, baseName: String ) -> Result<URL, WriteFailureReason> {
        guard let pic = self.picture else { return .failure( .missingPicture ) }

        var img_writer_type:PxImageWriter_Type
        var file_ext:String

        let save_format = self.saveFormat

        switch save_format {
            case 0:
                img_writer_type = PxImageWriter_Type_PDF
                file_ext = "pdf"
            case 1:
                img_writer_type = PxImageWriter_Type_PNG
                file_ext = "pdf"
            case 2:
                img_writer_type = PxImageWriter_Type_TIFF
                file_ext = "tiff"
            case 3:
                img_writer_type = PxImageWriter_Type_PNG
                file_ext = "png"
            case 4:
                img_writer_type = PxImageWriter_Type_JPEG
                file_ext = "jpg"
            case 5:
                img_writer_type = PxImageWriter_Type_JPEG
                file_ext = "txt"
            default:
                return .failure( .unknownSaveFormat( format: save_format ) )
        }

        // License preflight via the SDK feature bitmask. `PxLicense.info().features` is the
        // *allowed* set; the complement gives disabled bits. Only PDF / PDF-from-PNG / TIFF /
        // PNG are gated; JPEG (4) and TXT (5) are not. EndPDF and other write-time failures
        // on a license-permitted format never map to .licenseBlocked.
        if let blockedFormat = Self.licenseBlockedFormat( for: save_format ) {
            return .failure( .licenseBlocked( format: blockedFormat ) )
        }

        let file_name = baseName + "." + file_ext

        let file_local_path = URL( fileURLWithPath: dirPath ).appendingPathComponent( file_name ).path

        let file_mgr = FileManager.default;

        do {
            try file_mgr.removeItem( atPath: file_local_path );
        } catch {
        }

        let url: URL

        if save_format != 5 {
            var file_local_path2 = file_local_path

            if save_format == 1 {
                // PDF from PNG => build PNG file first
                file_local_path2 = file_local_path + ".png"

                do {
                    try file_mgr.removeItem( atPath: file_local_path2 )
                } catch {
                }
            }

            // Stage label for the first open/write/close cycle: PNG intermediate when
            // save_format == 1, primary otherwise.
            let firstStage = ( save_format == 1 ) ? "png-intermediate" : "primary"

            var img_writer = PxImageWriter.new( img_writer_type )

            do {
                try PxCatchExceptions.do {
                    img_writer.open( file_local_path2 )
                }
            } catch let error {
                return .failure( .openFailed( path: file_local_path2,
                                              message: error.localizedDescription,
                                              stage: firstStage ) )
            }

            // applyFontPolicy honours --uitesting-font-handling when set, otherwise
            // behaves identically to the PxFontGuard call. Returns the path vector
            // the engine will see (used below to decide whether to pass scanResult).
            var firstStageFonts: [String] = []
            if save_format == 0 {
                firstStageFonts = applyFontPolicy( to: img_writer )

                let level = self.pdfCompressionLevel

                var comp:Float = 1.0
                if( level < 0 ) {
                    comp = Float( level )
                }

                img_writer.setCompressionLevel( comp );
            }

            var simulate_multi_page_file = self.simulateMultipageFile
            if save_format > 2 {
                simulate_multi_page_file = false
            }

            var c = 1
            if simulate_multi_page_file && save_format != 1 {
                c = 3
            }

            // Pick original orientation
            let original_orientation = pic.orientation

            if save_format == 1 {
                pic.orientation = PxOrientation_Normal
            }

            var s: String?
            var firstStageFailure: WriteFailureReason?

            do {
                // Drop OCR text when no fonts will be presented to the engine.
                // The engine already warns and skips on empty mTextFonts; this
                // mirrors that behaviour explicitly for clarity.
                let res = ( save_format != 0 || firstStageFonts.isEmpty ) ? nil : pic.scanResult

                repeat {
                    try PxCatchExceptions.do {
                        s = img_writer.write( pic, with: res );
                    }

                    if( s == nil ) {
                        break;
                    }

                    c -= 1
                } while c > 0
            } catch let error {
                firstStageFailure = .writeFailed( path: file_local_path2,
                                                  message: error.localizedDescription,
                                                  stage: firstStage )
                s = nil
            }

            do {
                try PxCatchExceptions.do {
                    img_writer.close()
                }
            } catch let error {
                if firstStageFailure == nil {
                    firstStageFailure = .closeFailed( path: file_local_path2,
                                                      message: error.localizedDescription,
                                                      stage: firstStage )
                }
                s = nil
            }

            if save_format == 1 {
                pic.orientation = original_orientation
            }

            if let failure = firstStageFailure {
                return .failure( failure )
            }
            if s == nil {
                return .failure( .writerReturnedNil( path: file_local_path2, stage: firstStage ) )
            }

            if save_format == 1 {
                let secondStage = "pdf-final"

                img_writer = PxImageWriter.new( PxImageWriter_Type_PDF )

                do {
                    try PxCatchExceptions.do {
                        img_writer.open( file_local_path )
                    }
                } catch let error {
                    return .failure( .openFailed( path: file_local_path,
                                                  message: error.localizedDescription,
                                                  stage: secondStage ) )
                }

                let secondStageFonts = applyFontPolicy( to: img_writer )

                c = 1
                if simulate_multi_page_file {
                    c += 2
                }

                var secondStageFailure: WriteFailureReason?

                do {
                    repeat {
                        try PxCatchExceptions.do {
                            // Drop OCR text when no fonts are bundled.
                            let res: PxTextResult? = secondStageFonts.isEmpty ? nil : pic.scanResult

                            s = img_writer.writeFile( file_local_path2, with: original_orientation, andTextResult:res, andTextOrientation:res == nil ? PxOrientation_Normal : res!.orientation )
                        }

                        if s == nil {
                            break
                        }

                        c -= 1
                    } while c > 0
                } catch let error {
                    secondStageFailure = .writeFailed( path: file_local_path,
                                                       message: error.localizedDescription,
                                                       stage: secondStage )
                    s = nil
                }

                do {
                    try PxCatchExceptions.do {
                        img_writer.close()
                    }
                } catch let error {
                    if secondStageFailure == nil {
                        secondStageFailure = .closeFailed( path: file_local_path,
                                                           message: error.localizedDescription,
                                                           stage: secondStage )
                    }
                    s = nil
                }

                if let failure = secondStageFailure {
                    return .failure( failure )
                }
                if s == nil {
                    return .failure( .writerReturnedNil( path: file_local_path, stage: secondStage ) )
                }
            }

            url = URL( fileURLWithPath: s! )
        } else {
            guard let res = pic.scanResult else {
                return .failure( .missingScanResultForTXT )
            }

            url = URL( fileURLWithPath: file_local_path )

            do {
                try res.text.write( to: url, atomically: true, encoding: String.Encoding.utf8 )
            } catch {
                return .failure( .txtWriteFailed( path: file_local_path,
                                                  message: error.localizedDescription ) )
            }
        }

        return .success( url )
    }

    /// Returns the format index if the active license blocks it; nil otherwise.
    /// Mirrors the SDK's own license gate so the demo can preflight before writing.
    private static func licenseBlockedFormat( for save_format: Int ) -> Int? {
        // PxLicense.info().features is the *allowed* set; complement gives disabled bits.
        let allowed = UInt( PxLicense.info().features )
        let disabled = ~allowed & 0xFFFF
        let bit: UInt
        switch save_format {
        case 0, 1: bit = UInt( PxLicenseFeature_PDF.rawValue )
        case 2:    bit = UInt( PxLicenseFeature_TIFF.rawValue )
        case 3:    bit = UInt( PxLicenseFeature_PNG.rawValue )
        default:   return nil
        }
        return ( disabled & bit ) != 0 ? save_format : nil
    }

    public func openSettings() {
        self.showSettings = true
    }

    public func openAbout() {
        self.showAbout = true
    }

    public func closeAbout() {
        self.showAbout = false
    }

    public func showError( _ message: String, _ args: CVarArg... ) {
        showAlert( title: "alert-error", message: message, args )
    }

    public func showAlert( title: String, message: String, _ args: CVarArg... ) {
        let s = String( format: message.localized, arguments: args )

        AppLog.general.notice( s )
        
        self.ocrAlert = false
        
        self.alertTitle = title.localized;
        self.alertMessage = s;
        self.showAlert = true
    }

    public func hideAlert() {
        self.showAlert = false

        self.ocrAlert = false
    }
}
