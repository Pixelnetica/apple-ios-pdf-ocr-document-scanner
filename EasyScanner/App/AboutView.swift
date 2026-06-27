// Copyright © 2012–2026 Pixelnetica™.
//
// Part of the EasyScanner sample app for the Pixelnetica Document
// Scanning SDK. Provided as sample code: you may use, modify, and
// incorporate it into applications that integrate the SDK. Provided
// "as is", without warranty of any kind.

import SwiftUI

struct AboutView : View {
    private let websiteURL = URL( string: "https://www.pixelnetica.com/products/document-scanning-sdk/document-scanner-sdk.html" )!

    var body: some View {
        List {
            Section {
            } header: {
                VStack( spacing: 8 ) {
                    Image( "AppLogo" )
                        .resizable()
                        .scaledToFit()
                        .frame( width: 96, height: 96 )

                    Text( "about-powered-by" )
                        .font( .caption )
                        .foregroundStyle( .secondary )
                        .textCase( nil )

                    Text( "about-heading" )
                        .font( .headline )
                        .multilineTextAlignment( .center )
                        .foregroundStyle( .primary )
                        .textCase( nil )
                }
                .frame( maxWidth: .infinity )
                .padding( .vertical, 8 )
            }

            Section {
                Link( destination: self.websiteURL ) {
                    HStack {
                        Text( "about-website-link" )
                        Spacer()
                        Image( systemName: "arrow.up.right" )
                            .foregroundStyle( .secondary )
                            .font( .footnote.weight( .semibold ) )
                    }
                }
            } header: {
                Text( "about-more-info" )
                    .textCase( nil )
            }

            Section {
                LabeledContent( "about-sdk-name" ) {
                    self.versionText( self.sdkVersion )
                }
                LabeledContent( "about-app-name" ) {
                    self.versionText( self.appVersion )
                }
            } header: {
                Text( "about-versions" )
                    .textCase( nil )
            } footer: {
                Text( verbatim: self.copyrightLine )
            }
            .textSelection( .enabled )
        }
        .navigationTitle( "about-title" )
        .accessibilityIdentifier( A11yID.About.root )
    }

    /// Version number at normal size, with the `(build) [commit]` suffix in a
    /// smaller secondary font on the same line.
    private func versionText( _ v: VersionInfo ) -> Text {
        Text( verbatim: v.version )
        + Text( verbatim: " (\(v.build)) [\(v.commit)]" )
            .font( .caption )
            .foregroundColor( .secondary )
    }

    private struct VersionInfo {
        let version: String
        let build: String
        let commit: String
    }

    private var sdkVersion: VersionInfo {
        VersionInfo(
            version: PxSDK.versionString,
            build: PxSDK.buildString,
            commit: Bundle( for: PxSDK.self ).object( forInfoDictionaryKey: "GitCommitHash" ) as? String ?? ""
        )
    }

    private var appVersion: VersionInfo {
        let bundle = Bundle.main
        return VersionInfo(
            version: bundle.object( forInfoDictionaryKey: "CFBundleShortVersionString" ) as? String ?? "",
            build: bundle.object( forInfoDictionaryKey: "CFBundleVersion" ) as? String ?? "",
            commit: bundle.object( forInfoDictionaryKey: "GitCommitHash" ) as? String ?? ""
        )
    }

    private var copyrightLine: String {
        return String( format: NSLocalizedString( "about-copyright", comment: "" ), self.buildYear )
    }

    private var buildYear: Int {
        let plist_path = Bundle.main.path( forResource: "Info.plist", ofType: nil )

        var dict: [FileAttributeKey : Any]? = nil
        do {
            dict = try FileManager.default.attributesOfItem( atPath: plist_path ?? "" )
        } catch {
        }

        let build_date = dict?[FileAttributeKey( "NSFileCreationDate" )] as? Date

        var components: DateComponents? = nil
        if let build_date = build_date {
            components = Calendar.current.dateComponents( in: TimeZone.current, from: build_date )
        }

        return Int( components?.year ?? 0 )
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AboutView()
        }
    }
}
