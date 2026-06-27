// Copyright © 2012–2026 Pixelnetica™.
//
// Part of the EasyScanner sample app for the Pixelnetica Document
// Scanning SDK. Provided as sample code: you may use, modify, and
// incorporate it into applications that integrate the SDK. Provided
// "as is", without warranty of any kind.

import DocScanningSDK_UI
import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?

    @ObservedObject private var model = ContentModel.inst
    @ObservedObject private var ocrModel =  OCRModel.inst
    @ObservedObject private var appEnv = AppEnvironment.shared

    @State private var fixturesMissing: String = ""
    @State private var showCamera: Bool = false
    // Held across the camera presentation so its final toggle state
    // (e.g. torch on/off) can be persisted back to UserDefaults on close.
    @State private var cameraConfiguration = PxUiCameraScreenConfiguration()

	var body: some View {
        let is_landscape = verticalSizeClass == .compact

        let model = self.model

        ZStack {
            MyColor.background.ignoresSafeArea()

            if( ocrModel.viewShown ) {
                OCRTextView()
            } else {
                VStack {
                    self.buildToolbar( top: true, bottom: is_landscape && model.binarizedImage != nil )

                    Spacer()

                    model.binarizedImage?
                        .resizable()
                        .scaledToFit()
                        .accessibilityIdentifier( A11yID.ContentView.documentThumbnail )

                    Spacer()

                    if !is_landscape && model.binarizedImage != nil {
                        self.buildToolbar( top: false, bottom: true )
                    }
                }
            }

            if appEnv.isUITesting {
                uiTestingMirrors
            }
        }.sheet( isPresented: $model.showImagePicker ) {
            ImagePicker( model.loadPhoto, onCancel: model.handlePhotoPickerCancelled )
        }.sheet( isPresented: $model.showShareSheet ) {
            ShareSheet( activityItems: [model.shareUrl!], callback: { activityType, completed, _, _ in
                // Log a share only when the user actually completed one; record
                // the chosen activity (e.g. "com.apple.UIKit.activity.Mail").
                if completed {
                    AppAnalytics.log( .share( contentType: "document",
                                              itemId: model.exportFormatToken,
                                              method: activityType?.rawValue ) )
                }
            } )
        }.fullScreenCover( isPresented: $showCamera ) {
            // Adoption of the SDK-UI camera screen. Settings persistence is
            // the consumer's concern: seed the held configuration from
            // UserDefaults at present-time, and on close persist the toggle
            // state the camera reported back (so torch on/off is remembered
            // across sessions).
            PxUiCameraScreenView( configuration: makeCameraConfiguration() ) { result in
                showCamera = false
                persistCameraConfiguration()
                switch result {
                case .success(let image, let cutout):
                    AppAnalytics.log(.scanCompleted(source: .camera, result: .success))
                    ContentModel.inst.loadImage(image, cutout: cutout)
                case .cancelled:
                    AppAnalytics.log(.scanCompleted(source: .camera, result: .cancelled))
                case .failure(let error):
                    AppAnalytics.log(.scanCompleted(source: .camera, result: .failure))
                    // Surface the framework's default-localised text
                    // via the existing error sheet.
                    ContentModel.inst.showError(
                        (error as NSError).localizedDescription)
                @unknown default:
                    break
                }
            }
            .ignoresSafeArea()
        }.fullScreenCover( isPresented: $model.showEditor ) {
            // Adoption of the SDK-UI page-crop editor. The screen edits corners
            // + rotation and returns (image, cutout); the demo runs the crop /
            // dewarp / colour-profile processing on the result. Both entry
            // points (the crop button and loadPicture's auto-open fallback) set
            // model.showEditor.
            if let picture = model.picture, let cutout = model.cutout {
                PxUiPageCropScreenView( picture: picture, cutout: cutout ) { result in
                    model.showEditor = false
                    switch result {
                    case .finished(let image, let cutout):
                        model.commitEditedPicture( image, cutout: cutout )
                    case .cancelled:
                        break
                    @unknown default:
                        break
                    }
                }
                .ignoresSafeArea()
            }
        }.sheet( isPresented: $model.showSettings ) {
            SettingsView()
        }.alert( isPresented: $model.showAlert ) {
            if model.ocrAlert {
                return Alert(
                    title: Text( "alert-warning" ),
                    message: Text( "ocr-no-scan-result" ),
                    primaryButton: .destructive( Text( "ocr-scan-text" ) ) {
                        model.hideAlert()

                        ocrModel.openView()
                    },
                    secondaryButton: .cancel( Text( "alert-cancel" ), action: model.hideAlert )
                )
            }

            return Alert(
                title: Text( model.alertTitle! ),
                message: Text( model.alertMessage! ),
                dismissButton: .default( Text( "alert-ok" ) )
            )
        }
        .onAppear {
            auditFixtures()
            if appEnv.isUITesting {
                if appEnv.loadN14NoDocFixture {
                    ContentModel.inst.loadN14NoDocFixture()
                } else if appEnv.loadN14DetectedDocFixture {
                    ContentModel.inst.loadUITestFixture(index: 0)
                } else if let index = appEnv.loadFixtureIndex {
                    // Load a fixture directly, bypassing the picker Menu, for OCR tests.
                    ContentModel.inst.loadUITestFixture(index: index)
                }
            }
        }
	}

    @ViewBuilder
    func buildToolbar( top:Bool, bottom:Bool ) -> some View {
        let model = self.model

        HStack {
            if( top ) {
                if appEnv.isUITesting {
                    fixtureLoaderMenu

                    Button {
                        ContentModel.inst.saveResultToTestContainer()
                    } label: {
                        Image( systemName: "square.and.arrow.down.on.square" )
                            .foregroundColor( MyColor.labelsPrimary )
                            .padding()
                    }
                    .accessibilityIdentifier( A11yID.UITesting.saveResult )

                    Spacer()
                }

                ToolbarButton( imageName:"ic_album", dualMode: true, a11yID: A11yID.ContentView.albumButton, action: model.handleAlbumButton )

                Spacer()

                ToolbarButton( imageName:"ic_camera", dualMode: true, a11yID: A11yID.ContentView.cameraToggleButton, action: { AppAnalytics.log( .scanStarted( source: .camera ) ); showCamera = true } )

                Spacer()
            }

            if( bottom ) {
                ToolbarButton( imageName:"ic_rotate_ccw", dualMode: true, a11yID: A11yID.ContentView.rotateButton, action: model.rotateImageCCW )

                Spacer()

                ToolbarButton( imageName:"ic_crop", dualMode: true, a11yID: A11yID.ContentView.editorButton, action: { AppAnalytics.log( .editorOpened( trigger: .manual ) ); model.showEditor = true } )

                Spacer()

                ColorProfileChooser( colorProfile: PxColorProfile( UInt32( model.colorProfile ) ), action: model.selectColorProfile )

                Spacer()

                ToolbarButton( imageName:"ic_ocr", dualMode: true, a11yID: A11yID.ContentView.ocrButton, action: ocrModel.openView )

                Spacer()

                ToolbarButton( imageName:"ic_share", dualMode: true, a11yID: A11yID.ContentView.shareButton, action: model.handleShareButton )
            }

            if( top ) {
                if( bottom ) {
                    Spacer()
                }

                ToolbarButton( imageName:"ic_settings", dualMode: true, a11yID: A11yID.ContentView.settingsButton, action: model.openSettings )
            }
        }
    }

    // Seeds the held camera configuration from UserDefaults at
    // present-time and returns it for the camera screen.
    private func makeCameraConfiguration() -> PxUiCameraScreenConfiguration {
        cameraConfiguration.borderDetectorOn = UserDefaults.standard.bool( forKey: "borderDetector" )
        cameraConfiguration.autoshotOn       = UserDefaults.standard.bool( forKey: "autoShot" )
        cameraConfiguration.autoshotDelay    = UserDefaults.standard.float( forKey: "DelayValue" )
        cameraConfiguration.torchOn          = UserDefaults.standard.bool( forKey: "torchState" )
        return cameraConfiguration
    }

    // Persists the toggle state the camera reported back on close, so the
    // torch on/off (and border detector) is remembered across sessions.
    private func persistCameraConfiguration() {
        UserDefaults.standard.set( cameraConfiguration.torchOn, forKey: "torchState" )
        UserDefaults.standard.set( cameraConfiguration.borderDetectorOn, forKey: "borderDetector" )
    }

    @ViewBuilder
    private var fixtureLoaderMenu: some View {
        Menu {
            Button( "0: BW flat" ) {
                ContentModel.inst.loadUITestFixture( index: 0 )
            }
            .accessibilityIdentifier( A11yID.UITesting.loadFixture( 0 ) )

            Button( "1: BW rotated" ) {
                ContentModel.inst.loadUITestFixture( index: 1 )
            }
            .accessibilityIdentifier( A11yID.UITesting.loadFixture( 1 ) )

            Button( "2: Color rotated" ) {
                ContentModel.inst.loadUITestFixture( index: 2 )
            }
            .accessibilityIdentifier( A11yID.UITesting.loadFixture( 2 ) )
        } label: {
            Image( systemName: "ant" )
                .foregroundColor( MyColor.labelsPrimary )
                .padding()
        }
        .accessibilityIdentifier( A11yID.UITesting.fixtureLoader )
    }

    @ViewBuilder
    private var uiTestingMirrors: some View {
        VStack( spacing: 0 ) {
            Text( appEnv.lastLicenseLog )
                .accessibilityIdentifier( A11yID.UITesting.licenseLogMirror )
            Text( fixturesMissing )
                .accessibilityIdentifier( A11yID.UITesting.fixturesMissing )
            Text( appEnv.lastSavedFilePath )
                .accessibilityIdentifier( A11yID.UITesting.savedFilePathMirror )
            Text( verbatim: String( appEnv.lastSavedFileSize ) )
                .accessibilityIdentifier( A11yID.UITesting.savedFileSizeMirror )
            Text( verbatim: String( appEnv.savedFilePdfPageCount ) )
                .accessibilityIdentifier( A11yID.UITesting.savedFilePdfPageCount )
            Text( verbatim: appEnv.savedFilePdfMagicValid ? "1" : "0" )
                .accessibilityIdentifier( A11yID.UITesting.savedFilePdfMagicValid )
            Text( verbatim: String( appEnv.savedFilePdfTextChars ) )
                .accessibilityIdentifier( A11yID.UITesting.savedFilePdfTextChars )
            Text( verbatim: appEnv.n15HarnessDidRun ? "1" : "0" )
                .accessibilityIdentifier( A11yID.UITesting.n15HarnessDidRun )
            Text( verbatim: String( appEnv.n15HarnessGetPointsCount ) )
                .accessibilityIdentifier( A11yID.UITesting.n15HarnessGetPointsCount )
        }
        .foregroundColor( .clear )
        .frame( maxWidth: 1, maxHeight: 1, alignment: .topLeading )
        .allowsHitTesting( false )
    }

    private func auditFixtures() {
        guard appEnv.isUITesting else { return }

        let images = [
            "ti-doc-bw-no_rot-con_back",
            "ti-doc-bw-rot-con_back",
            "ti-doc-jpn-color-rot-receipt",
        ]
        let licenses = [
            "lic-none",
            "lic-invalid-malformed",
            "lic-invalid-appid-wrong",
            "lic-invalid-platform-android",
            "lic-invalid-valid_to-expired",
            "lic-invalid-subscribed_to-expired",
        ]

        var missing: [String] = []
        for name in images {
            if Bundle.main.url( forResource: name, withExtension: "png", subdirectory: "test-imageset" ) == nil {
                missing.append( "\(name).png" )
            }
        }
        for name in licenses {
            if Bundle.main.url( forResource: name, withExtension: "txt", subdirectory: "test-licenses" ) == nil {
                missing.append( "\(name).txt" )
            }
        }
        fixturesMissing = missing.joined( separator: "," )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
