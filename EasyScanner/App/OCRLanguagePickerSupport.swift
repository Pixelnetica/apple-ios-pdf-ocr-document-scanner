// Copyright © 2012–2026 Pixelnetica™.
//
// Part of the EasyScanner sample app for the Pixelnetica Document
// Scanning SDK. Provided as sample code: you may use, modify, and
// incorporate it into applications that integrate the SDK. Provided
// "as is", without warranty of any kind.

import SwiftUI
import DocScanningSDK_UI

/// Demo-side persistence handle the framework PxUiLanguagePickerScreen reads/writes
/// through. It round-trips ORDERED installed + selected languages to the same
/// UserDefaults keys OCRModel uses ("loadedOcrLanguages" / "selectedOcrLanguages"),
/// so the picker and the demo's scan path share one source of truth. After the
/// picker returns, the demo calls OCRModel.applyLanguagePickerReturn() to re-read
/// these keys and re-scan iff the ordered signature changed.
final class OCRLanguageSelectionStore: NSObject, PxUiLanguagePickerSelectionStore {
    var installedLanguages: [String] {
        get { UserDefaults.standard.stringArray( forKey: "loadedOcrLanguages" ) ?? [] }
        set { UserDefaults.standard.setValue( newValue, forKey: "loadedOcrLanguages" ) }
    }

    var selectedLanguages: [String] {
        get { UserDefaults.standard.stringArray( forKey: "selectedOcrLanguages" ) ?? [] }
        set { UserDefaults.standard.setValue( newValue, forKey: "selectedOcrLanguages" ) }
    }
}

/// The directory OCR `.traineddata` files live in (mirrors OCRModel's private
/// langDirUrl derivation at EasyScannerApp startup). Re-derived here so
/// the demo can build a PxUiLanguagePickerScreenConfiguration without exposing the
/// model's private member.
func ocrLanguagesDirectory() -> URL {
    FileManager.default.urls( for: .documentDirectory, in: .userDomainMask )[0]
        .appendingPathComponent( "pixelnetica.DocScanningSDK" )
        .appendingPathComponent( "languages" )
}

/// Builds the configuration the demo passes when presenting the framework picker.
func makeOCRLanguagePickerConfiguration() -> PxUiLanguagePickerScreenConfiguration {
    PxUiLanguagePickerScreenConfiguration(
        outputDirectory: ocrLanguagesDirectory(),
        baseURL: PxUiLanguagePickerScreenConfiguration.defaultBaseURL,
        selectionStore: OCRLanguageSelectionStore()
    )
}

/// Circular progress indicator for the OSD download row in SettingsView.
/// value < 0 → indeterminate spinner; otherwise a 0...1 trimmed ring.
@ViewBuilder
func OCRDownloadProgressIndicator( _ value: CGFloat ) -> some View {
    if value < 0 {
        ProgressView().progressViewStyle( CircularProgressViewStyle() )
    } else {
        Image( systemName: "square.fill" )
            .foregroundColor( .blue )
            .scaleEffect( 0.4 )
            .overlay(
                Circle()
                    .trim( from: 0, to: value )
                    .stroke( .blue )
                    .rotationEffect( .degrees( -90 ) )
            )
    }
}
