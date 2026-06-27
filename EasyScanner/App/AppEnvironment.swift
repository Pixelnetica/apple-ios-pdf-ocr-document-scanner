// Copyright © 2012–2026 Pixelnetica™.
//
// Part of the EasyScanner sample app for the Pixelnetica Document
// Scanning SDK. Provided as sample code: you may use, modify, and
// incorporate it into applications that integrate the SDK. Provided
// "as is", without warranty of any kind.

import Foundation
import Combine

/// Test switch for how `ContentModel` calls `setFonts(...)` on the PDF writer.
/// Used only when `--uitesting-font-handling <mode>` is set; otherwise the demo runs its
/// normal PxFontGuard logic. The engine sees the same empty-fonts state for both `.empty`
/// and `.omit`, but exercising the two demo paths separately keeps the iOS bridge covered
/// in either case.
enum FontHandlingMode: String {
    /// Pass `Bundle.main.paths(forResourcesOfType:"ttf", ...)` to `setFonts(...)`. Picture's
    /// scanResult is passed unchanged. Expects text-layer to be present in the PDF.
    case present
    /// Call `setFonts([])`. Picture's scanResult is still passed unchanged. Expects
    /// engine-side warning + image-only PDF.
    case empty
    /// Skip the `setFonts(...)` call entirely. Picture's scanResult is still passed.
    /// Expects engine-side warning + image-only PDF.
    case omit
}

final class AppEnvironment: ObservableObject {
    static let shared = AppEnvironment()

    let isUITesting: Bool
    let resetStateOnLaunch: Bool
    let clearOCRLanguagesOnLaunch: Bool
    let licenseFixtureName: String?
    /// Wave stamp injected by the test runner so all tests in one xcodebuild invocation
    /// share a dated subfolder under Documents/test-results. Empty when not running under
    /// UI tests.
    let resultsWave: String
    /// Languages to load + select at startup, bypassing the OCR language picker.
    /// Each entry must already exist on disk as <lang>.traineddata; missing files are
    /// dropped during the OCRModel reconcile pass. Comma-separated in the launch arg
    /// (e.g. "--uitesting-preselect-languages eng,rus").
    let preselectLanguages: [String]
    /// Runs the PDF axis-sweep reproducer on launch and writes a report to
    /// Documents/test-results/_repro/<wave>/. Debug-build-only and only effective
    /// when --uitesting is also set; the reproducer itself enforces the DEBUG guard.
    let runPdfReproducer: Bool
    /// Bridge regression harness: instantiate a default `PxCutout()`, call `getPoints:`
    /// into a stack buffer, and surface the result via UITesting mirrors so the test can
    /// assert that the bridge's `try/catch` in `PxCutout.mm:-getPoints:` swallows the
    /// engine throw and returns `cnt = 0` without crashing. Read once at launch.
    let runN15InvariantHarness: Bool
    /// When set, the app synthesises a plain solid-white 1024x1024 UIImage at startup and
    /// feeds it through ContentModel as if it came from the photo library. The SDK detector
    /// returns isDefined=false on a document-free image, which opens the editor with a
    /// full-image fallback cutout and triggers the no-document banner. Read once at launch;
    /// only effective in combination with --uitesting.
    let loadN14NoDocFixture: Bool
    /// When set, the app loads a known-detectable document fixture
    /// (test-imageset/ti-doc-bw-no_rot-con_back.png) AND forces `cropState=false` in
    /// UserDefaults so the editor opens for manual review of a successful detection. The
    /// banner must be hidden. Read once at launch; only effective in combination with
    /// --uitesting.
    let loadN14DetectedDocFixture: Bool
    /// When set, initSettings overrides the install-default `autoShot=true` and
    /// `borderDetector=true` to `false` so camera UI tests do not race the SDK's
    /// auto-capture pipeline. Without this, opening the camera (even without tapping the
    /// shutter) lets borderDetector + autoShot trigger a capture, which routes to the
    /// editor and removes ContentView's toolbar from view — flaking non-capture camera
    /// tests. Read once at launch; only effective in combination with --uitesting.
    let cameraDefaultsOff: Bool
    /// Select a save format at launch (`--uitesting-save-format N`, e.g. 5 = TXT) so a test
    /// can exercise a specific export without driving the Settings save-format picker. nil = unset.
    let saveFormatOverride: Int?
    /// Preload a fixture by index at launch (`--uitesting-load-fixture N`), bypassing the
    /// SwiftUI fixture-picker Menu. The Menu's accessibility shape is unreachable to
    /// XCUITest on current Xcode, which blocks every OCR test that must import a document.
    /// This arg loads the same fixture `loadUITestFixture(index:)` would, with no picker
    /// interaction. nil = not set.
    let loadFixtureIndex: Int?

    @Published var lastLicenseLog: String = ""
    @Published var lastSavedFilePath: String = ""
    @Published var lastSavedFileSize: Int = 0
    /// PDF page count of the most-recently-saved file. Zero for non-PDF saves and the
    /// `<base>-preview.png` license-fallback path. Updated atomically with path/size.
    @Published var savedFilePdfPageCount: Int = 0
    /// True when the most-recently-saved file's first 5 bytes match `%PDF-`. False for
    /// non-PDF saves and the `<base>-preview.png` license-fallback path. Updated
    /// atomically with path/size.
    @Published var savedFilePdfMagicValid: Bool = false
    /// Character count of selectable text extracted from the most-recently-saved PDF via
    /// PDFKit. Zero for image-only PDFs (no text-layer rendered) and for non-PDF saves.
    /// Distinguishes "fonts called + present" (>0) from "fonts omitted or empty" (0).
    /// Updated atomically with path/size.
    @Published var savedFilePdfTextChars: Int = 0
    /// Test switch for how `ContentModel` calls `setFonts(...)` on the PDF writer. `nil`
    /// means default behaviour (PxFontGuard); `.present`, `.empty`, or `.omit` override it
    /// under `--uitesting-font-handling <mode>`. Read once at launch.
    let fontHandlingOverride: FontHandlingMode?

    /// Bridge harness output: `true` once the regression harness has executed end-to-end.
    /// Defaults to `false` so a never-ran state cannot false-pass the test's assertion that
    /// the harness body actually ran.
    @Published var n15HarnessDidRun: Bool = false
    /// Bridge harness output: the `cnt` returned by `[[PxCutout new] getPoints:]`. Expected
    /// to be `0` — a default-constructed cutout throws at the engine, and
    /// `PxCutout.mm:-getPoints:` catches it and returns `cnt = 0`.
    @Published var n15HarnessGetPointsCount: Int = 0

    private init() {
        let args = ProcessInfo.processInfo.arguments
        isUITesting = args.contains("--uitesting")
        resetStateOnLaunch = args.contains("--uitesting-reset-state")
        clearOCRLanguagesOnLaunch = args.contains("--uitesting-clear-ocr-languages")
        licenseFixtureName = Self.value(after: "--uitesting-license", in: args)
        resultsWave = Self.value(after: "--uitesting-results-wave", in: args) ?? ""
        preselectLanguages = Self.value(after: "--uitesting-preselect-languages", in: args)?
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty } ?? []
        runPdfReproducer = args.contains("--uitesting-debug-pdf-reproducer")
        fontHandlingOverride = FontHandlingMode(rawValue:
            Self.value(after: "--uitesting-font-handling", in: args) ?? "")
        runN15InvariantHarness = args.contains("--uitesting-n15-invariant-harness")
        loadN14NoDocFixture = args.contains("--uitesting-n14-no-doc")
        loadN14DetectedDocFixture = args.contains("--uitesting-n14-detected-doc")
        cameraDefaultsOff = args.contains("--uitesting-camera-defaults-off")
        loadFixtureIndex = Self.value(after: "--uitesting-load-fixture", in: args).flatMap { Int($0) }
        saveFormatOverride = Self.value(after: "--uitesting-save-format", in: args).flatMap { Int($0) }
    }

    private static func value(after flag: String, in args: [String]) -> String? {
        guard let idx = args.firstIndex(of: flag), idx + 1 < args.count else { return nil }
        let next = args[idx + 1]
        return next.hasPrefix("--") ? nil : next
    }
}
