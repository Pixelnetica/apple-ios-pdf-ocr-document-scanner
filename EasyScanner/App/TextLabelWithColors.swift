// Copyright © 2012–2026 Pixelnetica™.
//
// Part of the EasyScanner sample app for the Pixelnetica Document
// Scanning SDK. Provided as sample code: you may use, modify, and
// incorporate it into applications that integrate the SDK. Provided
// "as is", without warranty of any kind.

import SwiftUI
import UIKit

struct TextLabelWithColors: UIViewRepresentable {
    @Binding var text: NSAttributedString
    
    func makeUIView( context: Context ) -> UILabel {
        let uiView = UILabel()
        
        uiView.lineBreakMode = .byWordWrapping
        uiView.numberOfLines = 0;
        uiView.font = UIFont.preferredFont( forTextStyle: .body )
        
        return uiView
    }

    func updateUIView( _ uiView: UILabel, context: Context ) {
        uiView.attributedText = text
    }
 }
