// Copyright © 2012–2026 Pixelnetica™.
//
// Part of the EasyScanner sample app for the Pixelnetica Document
// Scanning SDK. Provided as sample code: you may use, modify, and
// incorporate it into applications that integrate the SDK. Provided
// "as is", without warranty of any kind.

func dualImageName( _ name: String, _ dualMode: Bool = false ) -> String {
    var s = name
    
    if( dualMode && UITraitCollection.current.userInterfaceStyle == .dark ) {
        s += "_white"
    }
    
    return s
}

func colorProfileString( _ profile: PxColorProfile ) -> String {
    let profile_strings = [
        "profile-original",
        "profile-bw",
        "profile-gray",
        "profile-color",
    ]
    
    return profile_strings[Int( profile.rawValue )]
}

func colorProfileImageName( _ profile: PxColorProfile ) -> String {
    let image_names = [
        "ic_profile_original",
        "ic_profile_bw",
        "ic_profile_gray",
        "ic_profile_color",
    ]
    
    return dualImageName( image_names[Int( profile.rawValue )], true )
}

extension String {
    var localized: String {
        return NSLocalizedString( self, tableName: nil, bundle: Bundle.main, value: "", comment: "" )
    }
}
