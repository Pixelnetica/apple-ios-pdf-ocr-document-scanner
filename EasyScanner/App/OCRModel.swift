// Copyright © 2012–2026 Pixelnetica™.
//
// Part of the EasyScanner sample app for the Pixelnetica Document
// Scanning SDK. Provided as sample code: you may use, modify, and
// incorporate it into applications that integrate the SDK. Provided
// "as is", without warranty of any kind.

import SwiftUI

let langugaeDownloadUrl = "https://www.pixelnetica.com/products/OCR/dst"

final class OCRModel: NSObject, PxLanguageDownloaderDelegate, PxTextReaderDisplayCallback, PxTextReaderProgressCallback, ObservableObject {
    static let inst = OCRModel()
    
    static let osdLang = "osd"

    @Published var loadedLanguages: [String]
    
    @Published var loadProgress = Dictionary<String, CGFloat>()
    @Published var loadFailed = Set<String>()
    var loaders = Dictionary<String, PxLanguageDownloader>()

    @Published var selectedLanguages: Set<String>
    @Published var selectedLanguagesString:String

    @Published var detectTextOrientation = false

    @Published var viewShown = false
    @Published var alert = false

    private let scanQueue = DispatchQueue( label: "OCR" )
    private var scanState = 0
    @Published var scanImage: Image?
    @Published var scanProgress = 0.0
    var scanResult: PxTextResult?
    var scannedSelectedLanguagesString = ""
    // Monotonic edge bumped on each scan completion. scanResult is not @Published, and
    // the framework OCR editor now owns the highlighted text + preview, so the host
    // observes this to present the editor (initial scan) and refresh it (re-scan).
    @Published var scanResultVersion: UInt = 0
    // The attributed text the user last dismissed from the editor (confidence colours on
    // unedited spans, neutral on typed runs). Held here (the singleton survives the
    // OCRTextView teardown) so re-opening seeds from it instead of re-deriving from
    // scanResult — whose per-word ranges no longer match an edited string, and which a
    // previous empty render could poison. Cleared when a fresh scan produces a new result.
    var lastEditedText: NSAttributedString?

    @Published var languagesShown = false

    private var savedSelectedLanguagesString: String = ""

    private let langDirUrl: URL?

    // Directory holding the SDK-bundled OSD data (osd.traineddata), resolved off
    // the main thread on launch via PxBundledOcrData; nil until that completes.
    // Read only by preparePicture (always on the main thread).
    private var osdDir: String?

    private override init() {
        var loaded_languages = UserDefaults.standard.stringArray( forKey: "loadedOcrLanguages" ) ?? []

        var selected_languages = Set( UserDefaults.standard.stringArray( forKey: "selectedOcrLanguages" ) ?? [] )

        let file_mgr = FileManager.default

        let lang_dir_url = file_mgr.urls( for: .documentDirectory, in: .userDomainMask )[0]
            .appendingPathComponent( "pixelnetica.DocScanningSDK" )
            .appendingPathComponent( "languages" )

        var lang_dir_ok = false
        do {
            try file_mgr.createDirectory( at: lang_dir_url, withIntermediateDirectories: true )
            lang_dir_ok = true
        } catch let error {
            AppLog.ocr.error( "Failed to create OCR languages directory '\(lang_dir_url.relativeString)': \(error.localizedDescription)" )
        }
        self.langDirUrl = lang_dir_ok ? lang_dir_url : nil

        // Reconcile UserDefaults with the on-disk language files. After --uitesting-reset-state
        // (or any UserDefaults wipe) the cached arrays go to []; re-populating them from the
        // .traineddata files preserves user-installed languages across resets and avoids
        // shipping ghost entries that the model can't actually load.
        if lang_dir_ok,
           let entries = try? file_mgr.contentsOfDirectory( atPath: lang_dir_url.path ) {
            let on_disk_langs = entries
                .filter { $0.hasSuffix( ".traineddata" ) }
                .map { String( $0.dropLast( ".traineddata".count ) ) }
                .filter { $0 != OCRModel.osdLang }

            for lang in on_disk_langs where !loaded_languages.contains( lang ) {
                loaded_languages.append( lang )
            }
            // Drop entries the model claims to have but disk doesn't.
            loaded_languages = loaded_languages.filter { on_disk_langs.contains( $0 ) }
            selected_languages = selected_languages.intersection( loaded_languages )

            UserDefaults.standard.setValue( Array( loaded_languages ), forKey: "loadedOcrLanguages" )
            UserDefaults.standard.setValue( Array( selected_languages ), forKey: "selectedOcrLanguages" )
        }

        self.loadedLanguages = loaded_languages
        self.selectedLanguages = selected_languages
        self.selectedLanguagesString = OCRModel.buildSelectedLanguagesString( loadedLanguages: loaded_languages, selectedLanguages: selected_languages )
        
        // OSD ships bundled with the SDK, so text-orientation detection works
        // offline on a fresh install. Default the toggle ON for a first install
        // (no stored preference); honour an explicit prior choice otherwise.
        if UserDefaults.standard.object( forKey: "detectTextOrientation" ) == nil {
            self.detectTextOrientation = true
        } else {
            self.detectTextOrientation = UserDefaults.standard.bool( forKey: "detectTextOrientation" )
        }

        super.init()

        // Resolve (and, on first use, decrypt) the bundled OSD directory off the
        // main thread; preparePicture reads osdDir once it is ready.
        PxBundledOcrData.osdDirectory( completion: { [weak self] dir, error in
            if let error = error {
                AppLog.ocr.error( "Failed to resolve bundled OSD data: \(error.localizedDescription)" )
                return
            }
            DispatchQueue.main.async {
                self?.osdDir = dir
            }
        } )
    }

    // Selecting / reordering / deleting languages is handled by the framework
    // PxUiLanguagePickerScreen. The demo presents that screen and reconciles via
    // reloadSelectionFromDefaults() on return.

    func updateLoadedLanguages() {
        UserDefaults.standard.setValue( Array( loadedLanguages ), forKey: "loadedOcrLanguages" )
    }

    /// The full, ordered Tesseract-input signature for the current selection.
    /// This is the engine input itself (loadedLanguages filtered by selected, joined
    /// with "+") — NOT the collapsible display string, which renders "..." at >= 3
    /// languages and would make distinct selections compare equal. Use this for the
    /// re-scan gate.
    var selectedLanguagesSignature: String {
        loadedLanguages.filter { selectedLanguages.contains( $0 ) }.joined( separator: "+" )
    }

    /// Re-read installed + selected languages from UserDefaults into the in-memory
    /// @Published state. Required after the framework PxUiLanguagePickerScreen writes
    /// those keys through its selection store: updateSelectedLanguages() is write-only,
    /// so without an explicit read-back the model's in-memory state goes stale and the
    /// scan path keeps the old selection. Call this on the picker's return (both
    /// .finished and .cancelled — a cancel can still leave a changed/just-installed
    /// selection) before deciding whether to re-scan.
    func reloadSelectionFromDefaults() {
        loadedLanguages = UserDefaults.standard.stringArray( forKey: "loadedOcrLanguages" ) ?? []
        selectedLanguages = Set( UserDefaults.standard.stringArray( forKey: "selectedOcrLanguages" ) ?? [] )
        selectedLanguagesString = OCRModel.buildSelectedLanguagesString( loadedLanguages: loadedLanguages, selectedLanguages: selectedLanguages )
    }

    /// Re-read selection from the framework picker's store and re-run OCR iff the full
    /// ordered signature differs from what was last scanned. The gate is the signature,
    /// not the display string and not the picker's advisory `didChange`.
    func applyLanguagePickerReturn() {
        reloadSelectionFromDefaults()
        // Re-scan only when there is actually a document to scan. The picker is reachable
        // from BOTH the OCR editor (a document is loaded) and Settings (none) — calling
        // startScan() without a document force-unwraps a nil ContentModel.cutUiImage and
        // crashes (the Settings → change-language path). Guard on document presence.
        guard ContentModel.inst.cutUiImage != nil else { return }
        if scanResult == nil || scannedSelectedLanguagesString != selectedLanguagesSignature {
            startScan()
        }
    }
    
    private static func buildSelectedLanguagesString( loadedLanguages: [String], selectedLanguages: Set<String> ) -> String {
        if selectedLanguages.isEmpty {
            return "Select languages"
        }
        
        var s = ""

        var n = 0
        
        for lang in loadedLanguages {
            if !selectedLanguages.contains( lang ) {
                continue
            }
            
            if s != "" {
                s += ", "
            }
            
            n += 1
            
            if n >= 3 {
                s += "..."
                break
            }
            
            s += String( lang.prefix( 1 ) ).capitalized
            s += String( lang.dropFirst() )
        }
        
        return s
    }
    
    func downloadLanguage( _ lang: String ) {
        if let lang_dir_url = langDirUrl {
            loadFailed.remove( lang )

            loadProgress[lang] = -1
            
            let downloader = PxLanguageDownloader( lang, from: langugaeDownloadUrl, withOutDir: lang_dir_url.relativePath, andDelegate: self )
            
            loaders[lang] = downloader
            
            downloader.start()
        } else {
            showError( "ocr-cannot-download-language", lang )
        }
    }

    func downloadLanguageCancel( _ lang: String ) {
        guard let downloader = finalizeDownload( lang ) else { return }
        
        downloader.cancel()
    }

    func onLanguageDownloadProgress( _ lang:String, progress: Double ) {
        if loadProgress.keys.contains( lang ) {
            loadProgress[lang] = progress
        }
    }
    
    func onLanguageDownloadFinished( _ lang:String, error: Error? ) {
        if finalizeDownload( lang ) == nil {
            return
        }

        if let error = error {
            loadFailed.insert( lang )

            showError( "ocr-language-download-error", lang, error.localizedDescription )
        } else {
            loadedLanguages.append( lang )
            loadedLanguages = NSOrderedSet( array: loadedLanguages ).array as! [String]

            updateLoadedLanguages()
        }
    }
    
    
    
    private func finalizeDownload( _ lang:String ) -> PxLanguageDownloader? {
        guard let downloader = loaders[lang] else { return nil }

        loaders.removeValue( forKey: lang )

        loadProgress.removeValue( forKey: lang )
        
        return downloader
    }

    public func openView() {
        self.viewShown = true
    }

    public func closeView() {
        self.viewShown = false

        cancelScan()
    }
    
    public func preparePicture( _ pic: PxPicture!, _ cut: PxCutout? ) {
        self.clearScanResult( true );

        // osdDir may still be nil during the first-launch decrypt window; skip
        // orientation for that one early capture rather than crash.
        if self.detectTextOrientation, let osd_dir = self.osdDir {
            let detector = PxTextDetector( osd_dir )

            let orientation = detector.detectTextOrientation( pic )

            if orientation.rawValue > 0 && pic.orientation != orientation {
                pic.orientation = orientation
                
                if let cut = cut {
                    cut.transform( to: orientation )
                    cut.reorder()
                }
            }
        }
    }

    public func startScanIfNotScanned() {
        // Gate on the full ordered signature, not the collapsible display string
        // (which renders "..." at >= 3 languages and would skip a needed re-scan).
        if scanResult == nil || scannedSelectedLanguagesString != selectedLanguagesSignature {
            startScan()
        }
    }

    public func startScan() {
        self.scanState = 0
        self.scanImage = nil
        self.scanProgress = 0
        self.scanResult = nil

        self.alert = false
        
        // Derive the Tesseract input from loadedLanguages filtered by selectedLanguages
        // so the order is deterministic (matches the display string built by
        // buildSelectedLanguagesString). Set iteration order is not stable across
        // launches and IS engine input, not just display text.
        let languages = self.loadedLanguages
            .filter { self.selectedLanguages.contains( $0 ) }
            .joined( separator: "+" )
        if languages == "" {
            DispatchQueue.main.async {
                self.alert = true
            }
            
            return
        }

        self.scanState = 1
        self.scanImage = ContentModel.inst.cutImage

        let scanStart = Date()

        scanQueue.async { [self] in
            let reader = PxTextReader( langDirUrl!.relativePath, languages: languages )

            reader.progressCallback = self

            let pic = ContentModel.inst.picture!

            reader.scanText( pic, with: self )

            DispatchQueue.main.async {
                self.scanProgress = 0

                let state = self.scanState

                self.scanState = 0
                
                if( state < 0 ) {
                    return
                }

                let res = pic.scanResult!

                self.scanResult = res
                // A fresh recognition supersedes any previously-edited text.
                self.lastEditedText = nil
                // Record the full ordered SIGNATURE (the engine input), not the
                // collapsible display string — the re-scan gate compares signatures.
                self.scannedSelectedLanguagesString = languages
                // The colour-highlighted attributed text is now built by the framework
                // OCR editor (PxUiOcrEditorScreen) from this PxTextResult. scanResult is
                // not @Published, so bump an explicit edge the host observes to present
                // the editor (initial scan) and refresh it (re-scan completion).
                self.scanResultVersion &+= 1

                let langCodes = languages.split( separator: "+" )
                // Sort so equivalent selections (eng+jpn / jpn+eng) collapse to one
                // analytics value; the engine input `languages` keeps its own order.
                AppAnalytics.log( .ocrRun( language: langCodes.sorted().joined( separator: "+" ),
                                           languageCount: langCodes.count,
                                           durationMs: Int( Date().timeIntervalSince( scanStart ) * 1000 ) ) )
            }
        }
    }

    public func cancelScan() {
        if self.scanState > 0 {
            self.scanState = -1

            self.clearScanResult( true )
        }
    }

    public func clearScanResult( _ reset: Bool = false ) {
        if reset {
            self.scanImage = nil
        }

        self.scanResult = nil
        self.scannedSelectedLanguagesString = ""
    }

    func onScanDisplay( _ pic: PxPicture ) -> Bool {
        DispatchQueue.main.async { [self] in
            if self.scanState < 0 {
                return
            }
        }
        
        return false
    }
    
    func onScanProgress( _ page: UInt32, _ progress: Int32, _ box: UnsafePointer<PxRectF>? ) {
        if progress < 0 {
            return
        }
        
        DispatchQueue.main.async { [self] in
            self.scanProgress = Double( progress )
        }
    }

    func onScanCancel( _ page: UInt32, _ words: UInt32 ) -> Bool {
        return self.scanState < 0
    }
    
    // The edit-mode state machine, preview geometry, and colour-highlighted text
    // construction live in the framework OCR editor (PxUiOcrEditorScreen). The host
    // only orchestrates the scan and feeds the finished PxTextResult + image to the
    // editor screen.

    func showError( _ message: String, _ args: CVarArg... ) {
        let s = String( format: message.localized, arguments: args )
        
        AppLog.ocr.error( s )
    }
}
