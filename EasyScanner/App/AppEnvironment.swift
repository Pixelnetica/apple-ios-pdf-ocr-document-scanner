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
        fontHandlingOverride = FontHandlingMode(rawValue:
            Self.value(after: "--uitesting-font-handling", in: args) ?? "")
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
