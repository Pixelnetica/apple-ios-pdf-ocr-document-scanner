// Copyright © 2012–2026 Pixelnetica™.
//
// Part of the EasyScanner sample app for the Pixelnetica Document
// Scanning SDK. Provided as sample code: you may use, modify, and
// incorporate it into applications that integrate the SDK. Provided
// "as is", without warranty of any kind.

import Foundation

enum A11yID {
    enum ContentView {
        static let shareButton = "contentView.toolbar.shareButton"
        static let settingsButton = "contentView.toolbar.settingsButton"
        static let albumButton = "contentView.toolbar.albumButton"
        static let cameraToggleButton = "contentView.toolbar.cameraToggleButton"
        static let rotateButton = "contentView.toolbar.rotateButton"
        static let editorButton = "contentView.toolbar.editorButton"
        static let ocrButton = "contentView.toolbar.ocrButton"
        static let documentThumbnail = "contentView.documentThumbnail"
    }

    enum ImageEditor {
        static let confirmButton = "imageEditor.confirmButton"
        static let cancelButton = "imageEditor.cancelButton"
        static let rotateLeftButton = "imageEditor.rotateLeftButton"
        static let rotateRightButton = "imageEditor.rotateRightButton"
        static let expandCollapseButton = "imageEditor.expandCollapseButton"
        static func cornerHandle(_ position: String) -> String { "imageEditor.cornerHandle.\(position)" }
    }

    enum ColorProfile {
        static let blackWhite = "colorProfileChooser.profile.blackWhite"
        static let gray = "colorProfileChooser.profile.gray"
        static let original = "colorProfileChooser.profile.original"
        static let color = "colorProfileChooser.profile.color"
    }

    enum OCR {
        static let recognizeButton = "ocrView.recognizeButton"
        static let languagePickerButton = "ocrView.languagePickerButton"
        static let outputField = "ocrView.outputField"
        static let dismissButton = "ocrView.dismissButton"
    }

    enum OCRLanguages {
        static let arrangeIcon = "ocrLanguages.arrangeIcon"
        static let backButton = "ocrLanguages.backButton"
        static let moreLanguagesLink = "ocrLanguages.moreLanguagesLink"
        static let noLanguagesText = "ocrLanguages.noLanguagesText"
        static func languageRow(_ code: String) -> String { "ocrLanguages.languageRow.\(code)" }
        static func deleteIcon(_ code: String) -> String { "ocrLanguages.deleteIcon.\(code)" }
    }

    enum OCRMoreLanguages {
        static func downloadButton(_ code: String) -> String { "ocrMoreLanguages.downloadButton.\(code)" }
        static func progressIndicator(_ code: String) -> String { "ocrMoreLanguages.progressIndicator.\(code)" }
    }

    enum Settings {
        static let smartCropToggle = "settings.smartCropToggle"
        static let borderDetectorToggle = "settings.borderDetectorToggle"
        static let autoShotToggle = "settings.autoShotToggle"
        static let torchToggle = "settings.torchToggle"
        static let simulateMultipageToggle = "settings.simulateMultipageToggle"
        static let detectTextOrientationToggle = "settings.detectTextOrientationToggle"
        static let colorProfilePicker = "settings.colorProfilePicker"
        static let saveFormatPicker = "settings.saveFormatPicker"
        static let pdfCompressionPicker = "settings.pdfCompressionPicker"
        static let autoShotDelaySlider = "settings.autoShotDelaySlider"
        static let doneButton = "settings.doneButton"
        static let aboutLink = "settings.aboutLink"
        static let ocrLanguagesLink = "settings.ocrLanguagesLink"
    }

    enum About {
        static let root = "aboutView.root"
    }

    enum Camera {
        static let closeButton = "camera.closeButton"
        static let torchButton = "camera.torchButton"
        static let borderDetectorButton = "camera.borderDetectorButton"
        static let shutterButton = "camera.shutterButton"
        static let detectorLabel = "camera.detectorLabel"
    }

    enum UITesting {
        static let fixtureLoader = "uitesting.fixtureLoader"
        static func loadFixture(_ index: Int) -> String { "uitesting.loadFixture.\(index)" }
        static let saveResult = "uitesting.saveResult"
        static let licenseLogMirror = "uitesting.licenseLogMirror"
        static let fixturesMissing = "uitesting.fixturesMissing"
        static let savedFilePathMirror = "uitesting.savedFilePathMirror"
        static let savedFileSizeMirror = "uitesting.savedFileSizeMirror"
        static let savedFilePdfPageCount = "uitesting.savedFilePdfPageCount"
        static let savedFilePdfMagicValid = "uitesting.savedFilePdfMagicValid"
        // Character count of selectable text in the saved PDF (via PDFKit).
        // Zero = image-only PDF (no text layer); > 0 = text layer present.
        static let savedFilePdfTextChars = "uitesting.savedFilePdfTextChars"
        // didRun is exposed as a "1" / "0" string so the test can read it via .label
        // like every other mirror here. The sentinel distinguishes "harness never
        // executed" (label absent) from "harness ran and produced a zero count",
        // guarding against a false pass when the test runner skips the harness.
        static let n15HarnessDidRun = "uitesting.n15HarnessDidRun"
        static let n15HarnessGetPointsCount = "uitesting.n15HarnessGetPointsCount"
    }
}
