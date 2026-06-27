// Copyright © 2012–2026 Pixelnetica™.
//
// Part of the EasyScanner sample app for the Pixelnetica Document
// Scanning SDK. Provided as sample code: you may use, modify, and
// incorporate it into applications that integrate the SDK. Provided
// "as is", without warranty of any kind.

import DocScanningSDK_UI
import SwiftUI

struct SettingsView: View {
    @ObservedObject var contentModel = ContentModel.inst
    @ObservedObject var ocrModel = OCRModel.inst

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // Camera settings persist via @AppStorage bindings to UserDefaults.
    // The camera presentation site reads these keys at present-time and
    // constructs a PxUiCameraScreenConfiguration; no framework type owns
    // app defaults.
    @AppStorage("borderDetector") private var borderDetectorOn: Bool = false
    @AppStorage("autoShot") private var autoshotOn: Bool = false
    @AppStorage("torchState") private var torchOn: Bool = false

    // Autoshot delay persists through the same uniform @AppStorage path
    // as the other camera prefs. The camera reader takes it back as a
    // Float (ContentView.makeCameraConfiguration); UserDefaults coerces
    // the stored Double, matching the app's own 0.7 Double seed.
    @AppStorage("DelayValue") private var autoshotDelay: Double = 0.7

    @State private var languagesShown = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle( "settings-smart-crop", isOn: $contentModel.smartCrop )
                        .onChange( of: contentModel.smartCrop ) { value in
                            UserDefaults.standard.setValue( value, forKey: "cropState" )
                        }
                        .accessibilityIdentifier( A11yID.Settings.smartCropToggle )
                } footer: {
                    Text( "settings-smart-crop-desc" )
                }

                Section {
                    Picker( selection: $contentModel.colorProfile, label: EmptyView() )  {
                        ForEach( 0..<4, id: \.self ) { i in
                            let color_profile = PxColorProfile( UInt32( i ) )

                            HStack {
                                Image( colorProfileImageName( color_profile ) )
                                Text( LocalizedStringKey( colorProfileString( color_profile ) ) )
                            }
                            .tag( i )
                            .accessibilityIdentifier( ColorProfileChooser.a11yID( for: color_profile ) )
                        }
                    }
                    .pickerStyle( InlinePickerStyle() )
                    .onChange( of: contentModel.colorProfile ) { value in
                        UserDefaults.standard.setValue( value, forKey: "selectedProfile" )
                        AppAnalytics.log( .colorProfileSelected(
                            profile: ContentModel.profileShortCode( for: PxColorProfile( UInt32( value ) ) ) ) )
                    }
                    .accessibilityIdentifier( A11yID.Settings.colorProfilePicker )
                } header: {
                    Text( "settings-color-profile" )
                }

                Section {
                    Toggle( "settings-camera-border-detector", isOn: $borderDetectorOn )
                        .accessibilityIdentifier( A11yID.Settings.borderDetectorToggle )
                    Toggle( "settings-camera-autoshot", isOn: $autoshotOn )
                        .accessibilityIdentifier( A11yID.Settings.autoShotToggle )
                    AutoShotDelayRow( value: $autoshotDelay )
                        .accessibilityIdentifier( A11yID.Settings.autoShotDelaySlider )
                    Toggle( "settings-camera-torch-on", isOn: $torchOn )
                        .accessibilityIdentifier( A11yID.Settings.torchToggle )
                } header: {
                    Text( "settings-camera" )
                }

                Section {
                    Picker( selection: $contentModel.saveFormat, label: EmptyView() )  {
                        Text( "PDF" ).tag( 0 )
                        Text( "TIFF G4" ).tag( 2 )
                        Text( "PNG" ).tag( 3 )
                        Text( "JPG" ).tag( 4 )
                        Text( "TXT" ).tag( 5 )
                    }
                    .pickerStyle( InlinePickerStyle() )
                    .onChange( of: contentModel.saveFormat ) { value in
                        UserDefaults.standard.setValue( value, forKey: "selectedSaveFormat" )
                    }
                    .accessibilityIdentifier( A11yID.Settings.saveFormatPicker )
                } header: {
                    Text( "settings-sharing-format" )
                }

                Section {
                    Picker( selection: $contentModel.pdfCompressionLevel, label: EmptyView() )  {
                        Text( "settings-compression-lossless" ).tag( 0 )
                        Text( "settings-compression-low" ).tag( Int( PxImageWriter_CompressionLevel_Low.rawValue ) )
                        Text( "settings-compression-medium" ).tag( Int( PxImageWriter_CompressionLevel_Medium.rawValue ) )
                        Text( "settings-compression-high" ).tag( Int( PxImageWriter_CompressionLevel_High.rawValue ) )
                        Text( "settings-compression-extreme" ).tag( Int( PxImageWriter_CompressionLevel_Extreme.rawValue ) )
                    }
                    .pickerStyle( InlinePickerStyle() )
                    .onChange( of: contentModel.pdfCompressionLevel ) { value in
                        UserDefaults.standard.setValue( value, forKey: "pdfCompressionLevel" )
                    }
                    .accessibilityIdentifier( A11yID.Settings.pdfCompressionPicker )
                } header: {
                    Text( "settings-pdf-compression" )
                }

                Section {
                    Toggle( "settings-simulate-multipage", isOn: $contentModel.simulateMultipageFile )
                        .onChange( of: contentModel.simulateMultipageFile ) { value in
                            UserDefaults.standard.setValue( value, forKey: "simulateMultipageFile" )
                        }
                        .accessibilityIdentifier( A11yID.Settings.simulateMultipageToggle )
                } footer: {
                    Text( "settings-simulate-multipage-desc" )
                }

                Section {
                    Button {
                        languagesShown = true
                    } label: {
                        HStack {
                            Text( "settings-ocr-title" )
                            Spacer()
                            Image( systemName: "chevron.right" )
                                .font( .footnote.weight( .semibold ) )
                                .foregroundColor( .secondary )
                        }
                        .contentShape( Rectangle() )
                    }
                    .buttonStyle( .plain )
                    .accessibilityIdentifier( A11yID.Settings.ocrLanguagesLink )

                    OCROrientationRow()
                        .accessibilityIdentifier( A11yID.Settings.detectTextOrientationToggle )
                } header: {
                    Text( "settings-ocr-header" )
                } footer: {
                    Text( "settings-ocr-footer" )
                }

                Section {
                    NavigationLink( destination: AboutView() ) {
                        Text( "about-title" )
                    }
                    .accessibilityIdentifier( A11yID.Settings.aboutLink )
                }
            }
            .navigationTitle( "settings-title" )
            .navigationBarTitleDisplayMode( .inline )
            .toolbar {
                ToolbarItem( placement: .confirmationAction ) {
                    // Language-agnostic confirm control: the app's own checkmark-in-circle
                    // glyph, matching the main-screen toolbar icon style. The demo ships
                    // light/dark as a "_white" asset pair (no in-asset appearance), so pick
                    // the variant by colour scheme. Semantically a "Done" confirm, not a
                    // dismiss — VoiceOver announces the localized "settings-done".
                    Button {
                        dismiss()
                    } label: {
                        Image( colorScheme == .dark ? "ic_checkmark_circle_white" : "ic_checkmark_circle" )
                    }
                    // .plain strips the system toolbar button chrome (the tinted/glass
                    // capsule on iOS 26) so only the glyph shows against the Form background.
                    .buttonStyle( .plain )
                    .accessibilityLabel( "settings-done" )
                    .accessibilityIdentifier( A11yID.Settings.doneButton )
                }
            }
            .fullScreenCover( isPresented: $languagesShown ) {
                PxUiLanguagePickerScreenView( configuration: makeOCRLanguagePickerConfiguration() ) { _ in
                    languagesShown = false
                    // Re-read the picker's store + re-scan iff the ordered signature
                    // changed (runs on .finished and .cancelled).
                    ocrModel.applyLanguagePickerReturn()
                }
                .ignoresSafeArea()
            }
        }
    }

    // The autoshot-delay row is a labeled numeric field. Kept as a small
    // local view only because it pairs a label with a trailing TextField;
    // it carries no persistence side-effect (the bound @AppStorage does).
    private struct AutoShotDelayRow: View {
        @Binding var value: Double

        var body: some View {
            HStack {
                Text( "settings-camera-autoshot-delay" )

                Spacer()

                TextField( "", value: $value, formatter: formatter )
                    .keyboardType( .numbersAndPunctuation )
                    .multilineTextAlignment( .trailing )
                    .frame( maxWidth: 64 )
            }
        }

        private let formatter: NumberFormatter = {
            let formatter = NumberFormatter()

            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 3

            return formatter
        }()
    }

    // OSD ships bundled with the SDK, so text-orientation detection is always
    // available offline — the toggle is a plain persisted switch.
    private struct OCROrientationRow: View {
        @ObservedObject var ocrModel = OCRModel.inst

        var body: some View {
            Toggle( "settings-ocr-detect-text-orientation", isOn: $ocrModel.detectTextOrientation )
                .onChange( of: ocrModel.detectTextOrientation ) { value in
                    UserDefaults.standard.setValue( value, forKey: "detectTextOrientation" )
                }
        }
    }
}

struct SettingsEditorView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
