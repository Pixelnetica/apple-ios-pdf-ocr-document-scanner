// Copyright © 2012–2026 Pixelnetica™.
//
// Part of the EasyScanner sample app for the Pixelnetica Document
// Scanning SDK. Provided as sample code: you may use, modify, and
// incorporate it into applications that integrate the SDK. Provided
// "as is", without warranty of any kind.

import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    typealias Callback = (_ activityType: UIActivity.ActivityType?, _ completed: Bool, _ returnedItems: [Any]?, _ error: Error?) -> Void

    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    let excludedActivityTypes: [UIActivity.ActivityType]? = nil
    // `var` (not `let`) so the memberwise initializer exposes it: callers can pass
    // a completion to learn the chosen activity and whether a share completed.
    var callback: Callback? = nil

    func makeUIViewController( context: Context ) -> UIActivityViewController {
        let controller = UIActivityViewController( activityItems: activityItems,  applicationActivities: applicationActivities )
        
        controller.excludedActivityTypes = excludedActivityTypes
        controller.completionWithItemsHandler = callback
        
        return controller
    }

    func updateUIViewController( _ uiViewController: UIActivityViewController, context: Context ) {
    }
}
