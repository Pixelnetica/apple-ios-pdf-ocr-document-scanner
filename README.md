# EasyScanner — iOS document scanner: paper to searchable PDF with OCR

A sample iOS app for the [Pixelnetica Document Scanning SDK](https://www.pixelnetica.com/products/document-scanning-sdk/document-scanner-api-features.html?utm_source=EasyScan&utm_medium=src-ios&utm_campaign=read_me&utm_content=dssdk-features "Document Scanning SDK: Main Features and Benefits"). It shows how to build a complete document scanner.

## Features

- Live camera capture with automatic edge detection
- Manual crop and perspective correction
- Image cleanup and colour filters
- OCR with selectable, editable text (searchable PDF)
- Export to PDF, TIFF, PNG, JPEG, and plain text

The app is the reference integration for the SDK — the screens and view models here are meant to be read, copied, and adapted into your own app.

## EasyScan in App Store

A full-featured version is available free on the App Store.

📱 [__"EasyScan: PDF Doc Scanner"__](https://itunes.apple.com/app/easyscan-pdf-doc-scanner/id1460600832).

## Requirements

- Xcode 15 or later
- iOS 16.3+ device or simulator
- The Document Scanning SDK 3.0.0 or later (resolved automatically via Swift Package Manager)

## Getting started

```bash
git clone https://github.com/Pixelnetica/apple-ios-pdf-ocr-document-scanner.git
cd apple-ios-pdf-ocr-document-scanner
open EasyScanner/EasyScanner.xcodeproj
```

Xcode resolves the `DocScanningSDK` Swift package on first open (no manual step). Select the `EasyScanner` scheme and run. To run on a physical device, set your own development team in **Signing & Capabilities** — the project ships with the team field empty.

## Project layout

- `EasyScanner/App/` — the app sources (SwiftUI views, view models, SDK integration).
- `EasyScanner/EasyScanner.xcodeproj` — the Xcode project; consumes the SDK as a remote Swift package.

## SDK dependency (Swift Package Manager)

The app depends on the `DocScanningSDK` Swift package with an **up-to-next-major** rule (`from: 3.0.0`). It automatically resolves to the latest compatible **stable** release — every `3.0.0`-or-later `3.x` — and picks up new minor and patch versions on the next package update. Pre-release (beta) versions are never selected by this rule.

To change the SDK version your copy uses — pin an exact version, widen the range, or opt into a pre-release — edit the dependency in Xcode under **Project → Package Dependencies → DocScanningSDK → Dependency Rule**. This repo does not commit a resolved-versions file, so a fresh clone always resolves to the newest compatible SDK.

## Documentation

See the [SDK Documentation](https://www.pixelnetica.com/docs/document-scanner-sdk/apple-ios/introduction.html "Document Scanner SDK for Apple iOS Documentation") for API documentation and release notes.

## License

The app bundles a demo license that unlocks the SDK for this sample's bundle id, so it runs full-featured out of the box. To use the SDK in your own app, request a license for your `bundle id` [from Pixelnetica](https://www.pixelnetica.com/products/document-scanning-sdk/sdk-support.html?utm_source=EasyScan&utm_medium=src-ios&utm_campaign=read_me&utm_content=dssdk-support "Request information or Free Trial DSSDK license").

This sample app is provided as sample code — see [LICENSE](LICENSE). The Document Scanning SDK itself is commercial software licensed separately.

## About Pixelnetica Document Scanning SDK

[Pixelnetica Document Scanning SDK](https://www.pixelnetica.com/products/document-scanning-sdk/document-scanner-sdk.html?utm_source=EasyScan&utm_medium=src-ios&utm_campaign=read_me&utm_content=dssdk-overview "Document Scanning SDK: Overview") (_DSSDK_) provides developers with an intelligent, highly efficient toolkit, which offers an easy way to add image-processing features optimised for document photos captured by a mobile device or document camera.

For more information about DSSDK main Features and Benefits please visit [Pixelnetica website](https://www.pixelnetica.com/products/document-scanning-sdk/document-scanner-api-features.html?utm_source=EasyScan&utm_medium=src-ios&utm_campaign=read_me&utm_content=dssdk-features "Document Scanning SDK: Main Features and Benefits").

## Have Questions, need Free Trial or Quotation?

Feel free to contact us to request free trial license, price quotation, or in case of any inquiries at [Pixelnetica DSSDK Support](https://www.pixelnetica.com/products/document-scanning-sdk/sdk-support.html?utm_source=EasyScan&utm_medium=src-ios&utm_campaign=read_me&utm_content=dssdk-support "Contact Pixelnetica support for Free trial, Quotation, or in case of any questions").
