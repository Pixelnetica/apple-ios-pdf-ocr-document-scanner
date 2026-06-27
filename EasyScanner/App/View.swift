// Copyright © 2012–2026 Pixelnetica™.
//
// Part of the EasyScanner sample app for the Pixelnetica Document
// Scanning SDK. Provided as sample code: you may use, modify, and
// incorporate it into applications that integrate the SDK. Provided
// "as is", without warranty of any kind.

import SwiftUI

struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body( content: Content ) -> some View {
        content
            .onAppear()
            .onReceive( NotificationCenter.default.publisher( for: UIDevice.orientationDidChangeNotification ) ) { _ in
                action( UIDevice.current.orientation )
            }
    }
}

extension View {
    func onRotate( perform action: @escaping (UIDeviceOrientation) -> Void ) -> some View {
        self.modifier( DeviceRotationViewModifier( action: action ) )
    }
    
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder
    func `if`<Content: View>( _ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform( self )
        } else {
            self
        }
    }
}
