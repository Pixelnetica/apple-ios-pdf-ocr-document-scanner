// Copyright © 2012–2026 Pixelnetica™.
//
// Part of the EasyScanner sample app for the Pixelnetica Document
// Scanning SDK. Provided as sample code: you may use, modify, and
// incorporate it into applications that integrate the SDK. Provided
// "as is", without warranty of any kind.

// EndPDF reproducer. Iterates an axis sweep against PxImageWriter
// to characterize the EndPDF failure: format, profile, compression, multipage,
// OCR/textResult, fixture. Writes a report to Documents/test-results/_repro/<wave>/.
// Compiled into Debug builds only and only effective when both --uitesting and
// --uitesting-debug-pdf-reproducer launch args are present.
//
// To run on simulator:
//   xcrun simctl launch <SIM_UDID> com.pixelnetica.DSSDK-app \
//       --uitesting --uitesting-debug-pdf-reproducer \
//       --uitesting-license <fixture-name>
//
// Pull report:
//   xcrun simctl get_app_container <SIM_UDID> com.pixelnetica.DSSDK-app data
//   then look under Documents/test-results/_repro/<wave>/repro.txt

#if DEBUG

import Foundation
import PDFKit
import UIKit

enum PdfReproducer {

    // Font-absent guard: same contract as ContentModel — when no TTFs
    // are bundled, skip setFonts(...) and pass nil for andTextResult so
    // the shared engine never hits its "fonts.empty()" throw. .ttf-only by design.
    private static var bundledFontPaths: [String] {
        Bundle.main.paths( forResourcesOfType: "ttf", inDirectory: "Fonts" )
    }

    private static let fixtures = [
        "ti-doc-bw-no_rot-con_back",
        "ti-doc-bw-rot-con_back",
        "ti-doc-jpn-color-rot-receipt",
    ]

    private static let profiles: [(label: String, raw: UInt32)] = [
        ("none",  PxColorProfile_None.rawValue),
        ("bw",    PxColorProfile_BW.rawValue),
        ("gray",  PxColorProfile_Gray.rawValue),
        ("color", PxColorProfile_Color.rawValue),
    ]

    private static let compressionLevels: [(label: String, value: Float)] = [
        ("lossless", 1.0),
        ("low",      Float(PxImageWriter_CompressionLevel_Low.rawValue)),
        ("medium",   Float(PxImageWriter_CompressionLevel_Medium.rawValue)),
        ("high",     Float(PxImageWriter_CompressionLevel_High.rawValue)),
        ("extreme",  Float(PxImageWriter_CompressionLevel_Extreme.rawValue)),
    ]

    /// Run on app launch when the launch flag is set. Idempotent — guards against
    /// re-entry within a single process via `started`.
    private static var started = false

    static func runIfRequested() {
        guard AppEnvironment.shared.runPdfReproducer else { return }
        guard AppEnvironment.shared.isUITesting else { return }
        guard !started else { return }
        started = true

        DispatchQueue.global(qos: .userInitiated).async {
            run()
        }
    }

    private static func run() {
        guard let dir = reportDirectory() else {
            AppLog.pdf.debug("Cannot create PDF reproducer report directory")
            return
        }

        let log = LogSink(reportPath: dir.appendingPathComponent("repro.txt"))

        log.write("# EndPDF reproducer — wave=\(AppEnvironment.shared.resultsWave)")
        log.write("license_token=\(AppEnvironment.shared.lastLicenseLog)")
        log.write("license_features=\(licenseFeaturesDescription())")
        log.write("license_disabled_features=\(licenseDisabledFeaturesDescription())")
        log.write("")
        log.write("col\tfixture\tformat\tprofile\tcompression\tmultipage\tocr\toutcome\tdetail")

        // The matrix is intentionally narrow: we vary one axis at a time from a
        // baseline (BW + lossless + single + no-OCR + first fixture). When a cell
        // fails, the failure cell pins the axis. Cartesian explosion is wasted work.

        let baseline = AxisCell(fixture: fixtures[0],
                                saveFormat: 0,                  // PDF direct
                                profile: profiles[1],            // BW
                                compression: compressionLevels[0], // lossless
                                multipage: false,
                                ocr: false)

        // Sweep 1: format only (PDF direct vs PDF-from-PNG).
        for fmt in [0, 1] {
            run(cell: baseline.with(saveFormat: fmt), label: "fmt=\(fmt)", log: log, dir: dir)
        }

        // Sweep 2: color profile (with PDF direct, lossless).
        for prof in profiles {
            run(cell: baseline.with(profile: prof), label: "profile=\(prof.label)", log: log, dir: dir)
        }

        // Sweep 3: compression level (with PDF direct, BW).
        for comp in compressionLevels {
            run(cell: baseline.with(compression: comp), label: "comp=\(comp.label)", log: log, dir: dir)
        }

        // Sweep 4: multipage (PDF direct + PDF-from-PNG).
        for fmt in [0, 1] {
            run(cell: baseline.with(saveFormat: fmt, multipage: true),
                label: "multi=true,fmt=\(fmt)", log: log, dir: dir)
        }

        // Sweep 5: fixture variation.
        for fx in fixtures {
            run(cell: baseline.with(fixture: fx), label: "fixture=\(fx)", log: log, dir: dir)
        }

        // Sweep 6 — fonts optional in the shared PdfWriter.
        // These two cells deliberately bypass the demo's font-absent guard
        // (no setFonts call, andTextResult non-nil for text-layer; explicit
        // configureFooter for footer) so the shared engine path is what
        // we're actually exercising. They should produce a valid image-only
        // or footer-less PDF and emit exactly one "PDF font set is empty"
        // warning via NSLog.
        runN2(label: "n2-engine-skip-textlayer",
              kind: .textLayerSkip,
              fixture: fixtures[0],
              log: log,
              dir: dir)
        runN2(label: "n2-engine-skip-footer",
              kind: .footerSkip,
              fixture: fixtures[0],
              log: log,
              dir: dir)

        log.write("")
        log.write("# done")
        log.flush()
        AppLog.pdf.debug("PDF reproducer report written: \(dir.path)/repro.txt")
    }

    private struct AxisCell {
        var fixture: String
        var saveFormat: Int
        var profile: (label: String, raw: UInt32)
        var compression: (label: String, value: Float)
        var multipage: Bool
        var ocr: Bool

        func with(fixture: String? = nil,
                  saveFormat: Int? = nil,
                  profile: (label: String, raw: UInt32)? = nil,
                  compression: (label: String, value: Float)? = nil,
                  multipage: Bool? = nil,
                  ocr: Bool? = nil) -> AxisCell {
            return AxisCell(
                fixture: fixture ?? self.fixture,
                saveFormat: saveFormat ?? self.saveFormat,
                profile: profile ?? self.profile,
                compression: compression ?? self.compression,
                multipage: multipage ?? self.multipage,
                ocr: ocr ?? self.ocr
            )
        }
    }

    private static func run(cell: AxisCell, label: String, log: LogSink, dir: URL) {
        let row = "\(label)\t\(cell.fixture)\t\(cell.saveFormat)\t\(cell.profile.label)\t\(cell.compression.label)\t\(cell.multipage)\t\(cell.ocr)"
        guard let pic = loadPicture(named: cell.fixture) else {
            log.write("\(row)\tFIXTURE_MISSING\t-")
            return
        }
        autoreleasepool {
            let cut = pic.detect()
            let refine = PxRefineFeatures()
            refine.rectify(with: cut.copy())
            pic.refine(refine)

            let colorRefine = PxRefineFeatures()
            colorRefine.use(PxColorProfile(cell.profile.raw), forPic: pic)
            pic.refine(colorRefine)

            let outcome = attemptWrite(pic: pic, cell: cell, label: label, dir: dir)
            log.write("\(row)\t\(outcome.tag)\t\(outcome.detail)")
        }
    }

    private struct Outcome {
        let tag: String
        let detail: String
    }

    private static func attemptWrite(pic: PxPicture, cell: AxisCell, label: String, dir: URL) -> Outcome {
        let baseName = "\(label.replacingOccurrences(of: "/", with: "_"))-\(cell.fixture)"
        let fileExt: String
        let writerType: PxImageWriter_Type

        switch cell.saveFormat {
        case 0: writerType = PxImageWriter_Type_PDF;  fileExt = "pdf"
        case 1: writerType = PxImageWriter_Type_PNG;  fileExt = "pdf" // intermediate then PDF
        default: return Outcome(tag: "UNKNOWN_FORMAT", detail: "saveFormat=\(cell.saveFormat)")
        }

        let outputPath = dir.appendingPathComponent("\(baseName).\(fileExt)").path
        let intermediatePath = (cell.saveFormat == 1) ? outputPath + ".png" : outputPath

        // Cycle 1 (always): primary writer (PDF or PNG-intermediate).
        let firstStage = (cell.saveFormat == 1) ? "png-intermediate" : "primary"
        var img_writer = PxImageWriter.new(writerType)

        do {
            try PxCatchExceptions.do { img_writer.open(intermediatePath) }
        } catch let error {
            return Outcome(tag: "OPEN_FAILED",
                           detail: "stage=\(firstStage) err=\(error.localizedDescription)")
        }

        // Font-absent guard: setFonts only matters for the PDF writer
        // (PNG intermediate ignores text), so gate on writerType *and*
        // bundledFontPaths.isEmpty.
        let firstStageFonts = bundledFontPaths
        if writerType == PxImageWriter_Type_PDF {
            PxFontGuard.warnOnceIfFontsMissing(firstStageFonts)
            if !firstStageFonts.isEmpty {
                img_writer.setFonts(firstStageFonts)
            }
        }

        if cell.saveFormat == 0 {
            img_writer.setCompressionLevel(cell.compression.value)
        }

        let pageCount = (cell.saveFormat == 0 && cell.multipage) ? 3 : 1
        var resultName: String?
        for _ in 0..<pageCount {
            do {
                try PxCatchExceptions.do {
                    // Gate OCR text on bundled fonts as well as saveFormat.
                    let txt = (cell.saveFormat == 0 && !firstStageFonts.isEmpty) ? pic.scanResult : nil
                    resultName = img_writer.write(pic, with: txt)
                }
            } catch let error {
                _ = try? PxCatchExceptions.do { img_writer.close() }
                return Outcome(tag: "WRITE_FAILED",
                               detail: "stage=\(firstStage) err=\(error.localizedDescription)")
            }
            if resultName == nil { break }
        }

        do {
            try PxCatchExceptions.do { img_writer.close() }
        } catch let error {
            return Outcome(tag: "CLOSE_FAILED",
                           detail: "stage=\(firstStage) err=\(error.localizedDescription)")
        }

        guard resultName != nil else {
            return Outcome(tag: "WRITER_RETURNED_NIL", detail: "stage=\(firstStage)")
        }

        // Cycle 2 (only saveFormat == 1): wrap the PNG into a PDF.
        if cell.saveFormat == 1 {
            img_writer = PxImageWriter.new(PxImageWriter_Type_PDF)
            do {
                try PxCatchExceptions.do { img_writer.open(outputPath) }
            } catch let error {
                return Outcome(tag: "OPEN_FAILED",
                               detail: "stage=pdf-final err=\(error.localizedDescription)")
            }

            let secondStageFonts = bundledFontPaths
            PxFontGuard.warnOnceIfFontsMissing(secondStageFonts)
            if !secondStageFonts.isEmpty {
                img_writer.setFonts(secondStageFonts)
            }

            let pages = cell.multipage ? 3 : 1
            for _ in 0..<pages {
                do {
                    try PxCatchExceptions.do {
                        // Gate OCR text on bundled fonts.
                        let res: PxTextResult? = secondStageFonts.isEmpty ? nil : pic.scanResult
                        resultName = img_writer.writeFile(intermediatePath,
                                                          with: pic.orientation,
                                                          andTextResult: res,
                                                          andTextOrientation: res?.orientation ?? PxOrientation_Normal)
                    }
                } catch let error {
                    _ = try? PxCatchExceptions.do { img_writer.close() }
                    return Outcome(tag: "WRITE_FAILED",
                                   detail: "stage=pdf-final err=\(error.localizedDescription)")
                }
                if resultName == nil { break }
            }

            do {
                try PxCatchExceptions.do { img_writer.close() }
            } catch let error {
                return Outcome(tag: "CLOSE_FAILED",
                               detail: "stage=pdf-final err=\(error.localizedDescription)")
            }

            guard resultName != nil else {
                return Outcome(tag: "WRITER_RETURNED_NIL", detail: "stage=pdf-final")
            }
        }

        let size = (try? FileManager.default.attributesOfItem(atPath: outputPath)[.size] as? NSNumber)?.intValue ?? 0
        return Outcome(tag: "OK", detail: "size=\(size) path=\(outputPath)")
    }

    // MARK: - Engine-side font-optional scenarios

    private enum N2Kind {
        // skip setFonts(...), pass andTextResult non-nil. Note: pic.scanResult
        // is nil unless the reproducer ran OCR — and it doesn't, since tessdata
        // bring-up is heavy. So in practice this scenario does NOT enter the
        // text-layer block on the engine side (text.isTextReady() returns false
        // when there's no scan_result). It demonstrates that setFonts-omission
        // with a no-OCR write stays non-throwing, mirroring real consumer
        // integrations that ship without OCR.
        case textLayerSkip
        case footerSkip      // skip setFonts(...), configureFooter(...) explicit
    }

    private static func runN2(label: String, kind: N2Kind, fixture: String,
                              log: LogSink, dir: URL) {
        let row = "\(label)\t\(fixture)\t-\t-\t-\t-\t-"
        guard let pic = loadPicture(named: fixture) else {
            log.write("\(row)\tFIXTURE_MISSING\t-")
            return
        }
        autoreleasepool {
            let cut = pic.detect()
            let refine = PxRefineFeatures()
            refine.rectify(with: cut.copy())
            pic.refine(refine)

            let outcome = attemptN2(kind: kind, pic: pic, label: label, dir: dir)
            log.write("\(row)\t\(outcome.tag)\t\(outcome.detail)")
        }
    }

    private static func attemptN2(kind: N2Kind, pic: PxPicture, label: String,
                                  dir: URL) -> Outcome {
        let outputPath = dir.appendingPathComponent("\(label).pdf").path
        let img_writer = PxImageWriter.new(PxImageWriter_Type_PDF)

        do {
            try PxCatchExceptions.do { img_writer.open(outputPath) }
        } catch let error {
            return Outcome(tag: "OPEN_FAILED",
                           detail: "kind=\(kind) err=\(error.localizedDescription)")
        }

        // Footer scenario: force a footer to render regardless of license
        // state. 4 mm matches the height of the engine's own auto-footer.
        if case .footerSkip = kind {
            let height = PxDimension(value: 4, units: PxDimension_Units_Millimeters)
            img_writer.configureFooter(height,
                                       withText: "EasyScanner reproducer footer",
                                       andUrl: "https://www.pixelnetica.com")
        }

        // No setFonts(...) call — that's the whole point of these scenarios.

        let textResult: PxTextResult? = (kind == .textLayerSkip) ? pic.scanResult : nil

        do {
            try PxCatchExceptions.do {
                _ = img_writer.write(pic, with: textResult)
            }
        } catch let error {
            _ = try? PxCatchExceptions.do { img_writer.close() }
            return Outcome(tag: "WRITE_FAILED",
                           detail: "kind=\(kind) err=\(error.localizedDescription)")
        }

        do {
            try PxCatchExceptions.do { img_writer.close() }
        } catch let error {
            return Outcome(tag: "CLOSE_FAILED",
                           detail: "kind=\(kind) err=\(error.localizedDescription)")
        }

        // Validate the file parses as a PDF with at least one page.
        guard let doc = PDFDocument(url: URL(fileURLWithPath: outputPath)) else {
            return Outcome(tag: "PDF_PARSE_FAILED",
                           detail: "kind=\(kind) path=\(outputPath)")
        }
        if doc.pageCount < 1 {
            return Outcome(tag: "PDF_EMPTY",
                           detail: "kind=\(kind) path=\(outputPath)")
        }

        let size = (try? FileManager.default.attributesOfItem(atPath: outputPath)[.size] as? NSNumber)?.intValue ?? 0
        return Outcome(tag: "OK",
                       detail: "kind=\(kind) size=\(size) pages=\(doc.pageCount) path=\(outputPath)")
    }

    // MARK: -

    private static func loadPicture(named stem: String) -> PxPicture? {
        guard let url = Bundle.main.url(forResource: stem, withExtension: "png", subdirectory: "test-imageset"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return PxPicture(from: data)
    }

    private static func reportDirectory() -> URL? {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let wave = AppEnvironment.shared.resultsWave.isEmpty ? "current" : AppEnvironment.shared.resultsWave
        let dir = docs.appendingPathComponent("test-results")
            .appendingPathComponent("_repro")
            .appendingPathComponent(wave)
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            return dir
        } catch {
            return nil
        }
    }

    private static func licenseFeaturesDescription() -> String {
        let f = UInt(PxLicense.info().features)
        var bits: [String] = []
        if f & UInt(PxLicenseFeature_PNG.rawValue)  != 0 { bits.append("PNG") }
        if f & UInt(PxLicenseFeature_TIFF.rawValue) != 0 { bits.append("TIFF") }
        if f & UInt(PxLicenseFeature_PDF.rawValue)  != 0 { bits.append("PDF") }
        if f & UInt(PxLicenseFeature_OCR.rawValue)  != 0 { bits.append("OCR") }
        return "0x\(String(f, radix: 16))[\(bits.joined(separator: "|"))]"
    }

    private static func licenseDisabledFeaturesDescription() -> String {
        // PxLicense.info.features is the *allowed* set; complement gives disabled bits.
        let allowed = UInt(PxLicense.info().features)
        let disabled = ~allowed & 0xFFFF
        var bits: [String] = []
        if disabled & UInt(PxLicenseFeature_PNG.rawValue)  != 0 { bits.append("PNG") }
        if disabled & UInt(PxLicenseFeature_TIFF.rawValue) != 0 { bits.append("TIFF") }
        if disabled & UInt(PxLicenseFeature_PDF.rawValue)  != 0 { bits.append("PDF") }
        if disabled & UInt(PxLicenseFeature_OCR.rawValue)  != 0 { bits.append("OCR") }
        return "0x\(String(disabled, radix: 16))[\(bits.joined(separator: "|"))]"
    }

    private final class LogSink {
        private let path: URL
        private var buffer: String = ""

        init(reportPath: URL) {
            self.path = reportPath
        }

        func write(_ line: String) {
            buffer.append(line)
            buffer.append("\n")
            AppLog.pdf.debug(line)
        }

        func flush() {
            try? buffer.data(using: .utf8)?.write(to: path)
        }
    }
}

#endif
