// Copyright © 2012–2026 Pixelnetica™.
//
// Part of the EasyScanner sample app for the Pixelnetica Document
// Scanning SDK. Provided as sample code: you may use, modify, and
// incorporate it into applications that integrate the SDK. Provided
// "as is", without warranty of any kind.

import SwiftUI
import os

/// Demo-app logging. Mirrors the SDK's scheme (subsystem + category + level)
/// under the demo's own identity, with an "[EasyScanner]" prefix so the
/// SDK-framework's "[DocScanningSDK]" messages stay distinguishable from the
/// sample app's own output.
struct AppLog {
    private let logger: Logger
    private init(_ category: String) {
        logger = Logger(subsystem: "com.pixelnetica.EasyScanner", category: category)
    }

    static let ocr = AppLog("OCR")
    static let pdf = AppLog("PDF")
    static let license = AppLog("License")
    static let general = AppLog("General")

    func error(_ message: String)  { logger.error("[EasyScanner] \(message, privacy: .public)") }
    func notice(_ message: String) { logger.notice("[EasyScanner] \(message, privacy: .public)") }
    func info(_ message: String)   { logger.info("[EasyScanner] \(message, privacy: .public)") }
    func debug(_ message: String)  { logger.debug("[EasyScanner] \(message, privacy: .public)") }
}

@main
struct EasyScannerApp: App {

    init() {

        if AppEnvironment.shared.resetStateOnLaunch {
            Self.resetUITestState()
        }

        if AppEnvironment.shared.clearOCRLanguagesOnLaunch {
            Self.clearOCRLanguagesDirectory()
        }

        initSettings()

        // Tests can preselect OCR languages via launch arg to avoid driving the
        // OCR language-picker UI (whose row-toggle animation has produced 60s XCUI
        // wait-for-idle stalls in multi-test xcodebuild invocations). The reconcile
        // pass in OCRModel.init still drops anything missing from disk, so this is
        // a safe no-op when the preselected languages aren't installed.
        if AppEnvironment.shared.isUITesting && !AppEnvironment.shared.preselectLanguages.isEmpty {
            UserDefaults.standard.set(AppEnvironment.shared.preselectLanguages, forKey: "loadedOcrLanguages")
            UserDefaults.standard.set(AppEnvironment.shared.preselectLanguages, forKey: "selectedOcrLanguages")
            UserDefaults.standard.synchronize()
        }

        // When loading a detected-doc fixture under test, force smart-crop OFF so the
        // editor opens for manual review. With the default smart-crop=true, a
        // successful detection (isDefined=true) skips the editor entirely.
        if AppEnvironment.shared.isUITesting && AppEnvironment.shared.loadN14DetectedDocFixture {
            UserDefaults.standard.set(false, forKey: "cropState")
            UserDefaults.standard.synchronize()
        }

        initLicense()

        UIDevice.current.beginGeneratingDeviceOrientationNotifications()

        #if DEBUG
        PdfReproducer.runIfRequested()
        #endif

        if AppEnvironment.shared.runN15InvariantHarness {
            Self.runN15InvariantHarness()
        }
    }

    /// Bridge regression harness: instantiate a default `PxCutout()` and call
    /// `getPoints:` into a stack buffer of four `PxPointF`s. The expected result
    /// is `cnt = 0` — the engine throws on a default-constructed cutout
    /// (`!isValid()`), and the bridge's `try/catch` in `PxCutout.mm:-getPoints:`
    /// swallows the throw and returns `0`. The two `AppEnvironment` mirrors record
    /// the outcome for the test to assert against. Runs whenever
    /// `--uitesting-n15-invariant-harness` is set, regardless of `--uitesting`,
    /// because it exercises only the bridge boundary, not the rest of the
    /// UI-testing scaffolding.
    private static func runN15InvariantHarness() {
        let cutout = PxCutout()
        var pts = Array(repeating: PxPointF(x: 0, y: 0), count: 4)
        let cnt = pts.withUnsafeMutableBufferPointer { buf -> UInt32 in
            cutout.getPoints(buf.baseAddress!)
        }
        AppEnvironment.shared.n15HarnessGetPointsCount = Int(cnt)
        AppEnvironment.shared.n15HarnessDidRun = true
    }

    func initSettings() {
        let defaults = UserDefaults.standard

        if !defaults.bool( forKey: "isInitialized" ) {
            defaults.set( true, forKey: "cropState" )

            defaults.set( 1, forKey: "selectedProfile" )

            defaults.set( 0, forKey: "selectedSaveFormat" )
            defaults.set( Int( PxImageWriter_CompressionLevel_Low.rawValue ), forKey: "pdfCompressionLevel" )

            defaults.set( true, forKey: "borderDetector" )
            defaults.set( true, forKey: "autoShot" )
            defaults.set( 0.7, forKey: "DelayValue" )
            defaults.set( false, forKey: "shakeDetector" )
            defaults.set( true, forKey: "torchState" )

            defaults.set( true, forKey: "detectTextOrientation" )  // OSD model is bundled, so default this on
            defaults.set( [], forKey: "loadedOcrLanguages" )
            defaults.set( [], forKey: "selectedOcrLanguages" )

            defaults.set( true, forKey: "isInitialized" )
            defaults.synchronize()
        }

        // After the first-launch seed runs, optionally force autoShot/borderDetector
        // off for camera UI tests. Applies on every launch so launch-arg combinations
        // like --uitesting-reset-state + --uitesting-camera-defaults-off behave as
        // expected: the reset wipes the keys, initSettings re-seeds the install
        // defaults, then this block overrides the camera-relevant ones to false.
        if AppEnvironment.shared.cameraDefaultsOff {
            defaults.set( false, forKey: "autoShot" )
            defaults.set( false, forKey: "borderDetector" )
            defaults.synchronize()
        }

        // Select a save format at launch (`--uitesting-save-format N`), so a test can exercise
        // a specific export (e.g. TXT = 5) without driving the Settings save-format picker.
        if let fmt = AppEnvironment.shared.saveFormatOverride {
            defaults.set( fmt, forKey: "selectedSaveFormat" )
            defaults.synchronize()
        }
    }

    func initLicense() {
        var key: String = ""

        if let url = Self.licenseFileURL() {
            do {
                key = try String(contentsOf: url, encoding: .utf8)
            } catch {
                AppLog.license.error("Error reading license key from file: \(error.localizedDescription)")
            }
        }

        key = key.trimmingCharacters( in: .whitespacesAndNewlines )

        let status = PxLicense.initialize( withKey: key.isEmpty ? nil : key )
        let token = Self.licenseToken(for: status)
        AppLog.license.info(token)
        AppEnvironment.shared.lastLicenseLog = token

        if status != PxLicenseStatus_Active {
            AppLog.license.notice("License not active; results will be watermarked")
        }
    }

    private static func licenseFileURL() -> URL? {
        if AppEnvironment.shared.isUITesting,
           let fixtureName = AppEnvironment.shared.licenseFixtureName {
            let stem = (fixtureName as NSString).deletingPathExtension
            let ext = (fixtureName as NSString).pathExtension
            if let url = Bundle.main.url(forResource: stem,
                                         withExtension: ext.isEmpty ? nil : ext,
                                         subdirectory: "test-licenses") {
                return url
            }
            AppLog.license.error("UI-test license fixture not found in bundle: \(fixtureName). Falling through to no-license path")
            return nil
        }
        return Bundle.main.url(forResource: "license", withExtension: "txt")
    }

    private static func licenseToken(for status: PxLicenseStatus) -> String {
        switch status {
        case PxLicenseStatus_Active:               return "license.status.active"
        case PxLicenseStatus_None:                 return "license.status.none"
        case PxLicenseStatus_Malformed_Key:        return "license.status.malformed_key"
        case PxLicenseStatus_AppID_Mismatch:       return "license.status.appid_mismatch"
        case PxLicenseStatus_PlatformID_Mismatch:  return "license.status.platform_mismatch"
        case PxLicenseStatus_Expired:              return "license.status.expired"
        case PxLicenseStatus_Subscruption_Expired: return "license.status.subscription_expired"
        default:                                   return "license.status.unknown"
        }
    }

    private static func resetUITestState() {
        let defaults = UserDefaults.standard
        let keys = [
            "isInitialized",
            "cropState",
            "selectedProfile",
            "selectedSaveFormat",
            "pdfCompressionLevel",
            "simulateMultipageFile",
            "borderDetector",
            "autoShot",
            "DelayValue",
            "shakeDetector",
            "torchState",
            "detectTextOrientation",
            "selectedOcrLanguages",
        ]
        keys.forEach { defaults.removeObject(forKey: $0) }
        defaults.synchronize()

        // Clear AppEnvironment published mirrors so a test reading the saved-file mirrors
        // before triggering its own save cannot see leftovers from a previous test in the
        // same xcodebuild test run. Closes the across-test race the atomic recordSavedFile
        // update doesn't address.
        AppEnvironment.shared.lastSavedFilePath = ""
        AppEnvironment.shared.lastSavedFileSize = 0
        AppEnvironment.shared.savedFilePdfPageCount = 0
        AppEnvironment.shared.savedFilePdfMagicValid = false
        AppEnvironment.shared.savedFilePdfTextChars = 0

        // Reset writes a fresh slate for state but PRESERVES the cross-test test-results
        // tree. Each xcodebuild test run uses one wave-stamped subfolder; tests in the
        // same wave each write to their own profile subfolder, so deleting the whole
        // tree on every launch would erase the previous test's output before pull.
        // (See SaveResultsTests + scripts/pull-test-results.sh.)
    }

    private static func clearOCRLanguagesDirectory() {
        let fm = FileManager.default
        guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let langDir = docs.appendingPathComponent("pixelnetica.DocScanningSDK").appendingPathComponent("languages")
        try? fm.removeItem(at: langDir)
        // Also wipe the cached UserDefaults arrays so the model doesn't claim languages it can't load.
        UserDefaults.standard.set([], forKey: "loadedOcrLanguages")
        UserDefaults.standard.set([], forKey: "selectedOcrLanguages")
        UserDefaults.standard.synchronize()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
