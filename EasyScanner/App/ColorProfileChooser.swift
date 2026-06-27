// Copyright © 2012–2026 Pixelnetica™.
//
// Part of the EasyScanner sample app for the Pixelnetica Document
// Scanning SDK. Provided as sample code: you may use, modify, and
// incorporate it into applications that integrate the SDK. Provided
// "as is", without warranty of any kind.

import SwiftUI

struct ColorProfileChooser: View {
    let colorProfile: PxColorProfile
    let action: (PxColorProfile) -> Void

    var body: some View {
        Menu {
            ForEach( 0..<4, id: \.self ) { i in
                let color_profile = PxColorProfile( UInt32( i ) )

                Button {
                    action( color_profile )
                } label: {
                    Text( LocalizedStringKey( colorProfileString( color_profile ) ) )
                    Image( colorProfileImageName( color_profile ) )
                }
                .accessibilityIdentifier( ColorProfileChooser.a11yID( for: color_profile ) )
            }
        } label: {
             Image( colorProfileImageName( colorProfile ) )
        }
        .accessibilityIdentifier( "colorProfileChooser" )
    }

    static func a11yID( for profile: PxColorProfile ) -> String {
        switch profile {
        case PxColorProfile_None:  return A11yID.ColorProfile.original
        case PxColorProfile_BW:    return A11yID.ColorProfile.blackWhite
        case PxColorProfile_Gray:  return A11yID.ColorProfile.gray
        case PxColorProfile_Color: return A11yID.ColorProfile.color
        default:                   return ""
        }
    }
}

struct ColorProfileChooser_Previews: PreviewProvider {
    static var previews: some View {
        ColorProfileChooser( colorProfile: PxColorProfile_Color ) { profile in
        }
    }
}
