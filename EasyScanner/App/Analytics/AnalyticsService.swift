// Copyright © 2012–2026 Pixelnetica™.
//
// Part of the EasyScanner sample app for the Pixelnetica Document
// Scanning SDK. Provided as sample code: you may use, modify, and
// incorporate it into applications that integrate the SDK. Provided
// "as is", without warranty of any kind.

import Foundation

// A small, vendor-agnostic analytics seam. The app logs typed events through
// `AppAnalytics.log(...)`; a backend decides what to do with them. The default
// backend does nothing, so the app behaves identically whether or not an
// analytics provider is wired in. (In this sample no provider is wired in.)

/// Where a scan originated.
enum AnalyticsSource: String {
    case camera
    case photoLibrary = "photo_library"
}

/// Outcome of a scan input.
enum AnalyticsScanResult: String {
    case success
    case cancelled
    case failure
}

/// What caused the page editor to open.
enum AnalyticsEditorTrigger: String {
    case auto    // the app opened it (detection failed, or smart-crop is off)
    case manual  // the user opened it via the crop button
}

/// A single analytics event. Each case maps to one event name plus its
/// parameters; `name`/`parameters` are what a backend forwards.
enum AnalyticsEvent {
    case scanStarted(source: AnalyticsSource)
    case scanCompleted(source: AnalyticsSource, result: AnalyticsScanResult)
    case borderDetected(detected: Bool, source: AnalyticsSource)
    case editorOpened(trigger: AnalyticsEditorTrigger)
    case ocrRun(language: String, languageCount: Int, durationMs: Int)
    case exportDocument(format: String, compression: String?, pageCount: Int)
    case share(contentType: String, itemId: String, method: String?)
    case colorProfileSelected(profile: String)

    /// Event name. Lower snake_case, within analytics naming limits.
    var name: String {
        switch self {
        case .scanStarted:          return "scan_started"
        case .scanCompleted:        return "scan_completed"
        case .borderDetected:       return "border_detected"
        case .editorOpened:         return "editor_opened"
        case .ocrRun:               return "ocr_run"
        case .exportDocument:       return "export_document"
        case .share:                return "share"
        case .colorProfileSelected: return "color_profile_selected"
        }
    }

    /// Event parameters. Optional values are omitted when absent. Booleans are
    /// logged as `"true"`/`"false"` strings so they read as analytics dimensions.
    var parameters: [String: Any] {
        switch self {
        case let .scanStarted(source):
            return ["source": source.rawValue]
        case let .scanCompleted(source, result):
            return ["source": source.rawValue, "result": result.rawValue]
        case let .borderDetected(detected, source):
            return ["detected": detected ? "true" : "false", "source": source.rawValue]
        case let .editorOpened(trigger):
            return ["trigger": trigger.rawValue]
        case let .ocrRun(language, languageCount, durationMs):
            return ["ocr_language": language, "language_count": languageCount, "duration_ms": durationMs]
        case let .exportDocument(format, compression, pageCount):
            var p: [String: Any] = ["format": format, "page_count": pageCount]
            if let compression { p["compression"] = compression }
            return p
        case let .share(contentType, itemId, method):
            var p: [String: Any] = ["content_type": contentType, "item_id": itemId]
            if let method { p["method"] = method }
            return p
        case let .colorProfileSelected(profile):
            return ["profile": profile]
        }
    }
}

/// Receives logged events. Replace the backend to forward events somewhere.
protocol AnalyticsBackend {
    func log(_ event: AnalyticsEvent)
}

/// Default backend: drops every event.
struct NoOpAnalyticsBackend: AnalyticsBackend {
    func log(_ event: AnalyticsEvent) {}
}

/// App-wide analytics entry point. Swap `backend` to start forwarding events.
enum AppAnalytics {
    nonisolated(unsafe) static var backend: AnalyticsBackend = NoOpAnalyticsBackend()

    static func log(_ event: AnalyticsEvent) {
        backend.log(event)
    }
}
