// Copyright © 2012–2026 Pixelnetica™.
//
// Part of the EasyScanner sample app for the Pixelnetica Document
// Scanning SDK. Provided as sample code: you may use, modify, and
// incorporate it into applications that integrate the SDK. Provided
// "as is", without warranty of any kind.

import SwiftUI

struct ToolbarButton: View {
    var imageName: String
    var action: (() -> Void)?
    var a11yID: String?

    init( imageName: String, dualMode: Bool = false, a11yID: String? = nil, action: @escaping () -> Void ) {
        self.imageName = dualImageName( imageName, dualMode )
        self.action = action
        self.a11yID = a11yID
    }

    init( textLabel: String ) {
        self.imageName = textLabel
        self.action = nil
        self.a11yID = nil
    }

    var body: some View {
        Group {
            if let action = self.action {
                Button( action: action ) {
                    Image( self.imageName )
                }.padding()
            } else {
                Text( LocalizedStringKey( self.imageName ) )
                    .foregroundColor( MyColor.labelsPrimary )
                    .padding()
            }
        }
        .accessibilityIdentifier( a11yID ?? "" )
    }
}

struct ToolbarButton_Previews: PreviewProvider {
    static var previews: some View {
        ToolbarButton( imageName:"ic_collapse" ) {
        }
    }
}
