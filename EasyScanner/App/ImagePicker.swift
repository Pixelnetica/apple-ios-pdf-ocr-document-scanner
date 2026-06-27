// Copyright © 2012–2026 Pixelnetica™.
//
// Part of the EasyScanner sample app for the Pixelnetica Document
// Scanning SDK. Provided as sample code: you may use, modify, and
// incorporate it into applications that integrate the SDK. Provided
// "as is", without warranty of any kind.

import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    var callback: (Data?, Error?) -> Void
    // Called when the user dismisses the picker without choosing an image.
    var onCancel: (() -> Void)?

    init( _ callback: @escaping (Data?, Error?) -> Void, onCancel: (() -> Void)? = nil ) {
        self.callback = callback
        self.onCancel = onCancel
    }

    func makeUIViewController( context: Context ) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        
        config.filter = .images

        let picker = PHPickerViewController( configuration: config )
        
        picker.delegate = context.coordinator
        
        return picker
    }

    func updateUIViewController( _ uiViewController: PHPickerViewController, context: Context ) {
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator( self )
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: ImagePicker

        init( _ parent: ImagePicker ) {
            self.parent = parent
        }
        
        func picker( _ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult] ) {
            picker.dismiss( animated: true )

            guard let provider = results.first?.itemProvider else {
                parent.onCancel?()
                return
            }

            provider.loadDataRepresentation( forTypeIdentifier: "public.image" ) { data, error in
                self.parent.callback( data, error )
            }
        }
    }
}
