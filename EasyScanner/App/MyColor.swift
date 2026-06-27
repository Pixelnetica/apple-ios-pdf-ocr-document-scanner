// Copyright © 2012–2026 Pixelnetica™.
//
// Part of the EasyScanner sample app for the Pixelnetica Document
// Scanning SDK. Provided as sample code: you may use, modify, and
// incorporate it into applications that integrate the SDK. Provided
// "as is", without warranty of any kind.

import SwiftUI

struct MyColor {
    static let background = Color( "background-color" )
    static let labelsPrimary = Color( "labels-primary-color" )
    static let cameraText = Color( "camera-text-color" )
    static let textError = Color( "text-error-color" )
    static let borderDetector = UIColor( red: 0, green: 0.8, blue: 0, alpha: 0.6 )
    // The OCR editor colors are owned by the framework (PxUiOcrColors), so the demo
    // no longer references them here. The matching colorset assets remain in the
    // catalog but are currently unused.
}
