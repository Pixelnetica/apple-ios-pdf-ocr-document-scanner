// Copyright © 2012–2026 Pixelnetica™.
//
// Part of the EasyScanner sample app for the Pixelnetica Document
// Scanning SDK. Provided as sample code: you may use, modify, and
// incorporate it into applications that integrate the SDK. Provided
// "as is", without warranty of any kind.

import SwiftUI
import DocScanningSDK
import DocScanningSDK_UI

// Demo host for the OCR feature. This view owns ONLY the demo-side
// "scanning in progress" UI; the finished-result editor (toolbar / preview / colour-
// highlighted text / edit mode / split-view) is the framework's PxUiOcrEditorScreen,
// presented here via PxUiOcrEditorScreenView once a PxTextResult exists.
//
// Presentation model — ONE cover, not two siblings. The pre-editor language picker
// (reached from the no-languages alert) and the editor are mutually exclusive screens:
// you are either picking languages before any result exists, or in the editor. They are
// driven by a single `.fullScreenCover(item: $rootModal)` so they never coexist as
// sibling covers (two sibling covers on one view stole each other's interaction and
// dropped presentations — the editor never appeared after the picker, the picker stayed
// stuck). Transitions pass through nil; the editor is promoted from the cover's onDismiss
// after the picker has fully torn down, so nothing races a present against a dismiss.
//
// The in-editor change-language picker is a SEPARATE cover nested INSIDE the editor's
// content (presenting from within already-presented content is the supported form).
//
// Other wiring notes:
//  - The editor is latched via `rootModal == .editor`, never on `scanResult != nil`:
//    re-scan sets scanResult = nil again, which would dismiss the editor mid-rescan.
//  - scanResult is not @Published; the model bumps `scanResultVersion` on each scan
//    completion and the host bridges it via .onChange.
//  - On editor dismiss the framework self-dismisses its own modal and the
//    completion closes the whole OCR feature (`viewShown = false`).
struct OCRTextView: View {
    @ObservedObject var model = OCRModel.inst

    private enum RootModal: Identifiable {
        case picker                              // pre-editor language picker (from the no-languages alert)
        case editor(PxUiOcrEditorSession)        // the framework OCR editor; carries its session

        // The .editor case carries the session inside the presentation item so the cover
        // content reads it from the item, never from the separate @State (which is not yet
        // visible in the same tick the cover presents — that race rendered a blank/nil cover).
        var id: Int { switch self { case .picker: 0; case .editor: 1 } }
    }

    @State private var rootModal: RootModal?
    @State private var session: PxUiOcrEditorSession?
    @State private var changeLanguageShown = false
    // Set when a scan finishes while the pre-editor picker is still up; the cover's
    // onDismiss then promotes nil → .editor (no present-against-dismiss race).
    @State private var pendingEditorPresent = false

    var body: some View {
        scanningHost
            .onAppear {
                presentExistingResultOrScan()
            }
            .onChange(of: model.scanResultVersion) { _ in
                handleScanCompletion()
            }
            .onChange(of: model.scanProgress) { progress in
                session?.scanProgress = progress
            }
            .fullScreenCover(item: $rootModal, onDismiss: promotePendingEditor) { which in
                switch which {
                case .picker: preEditorPickerCover
                case .editor(let session): editorCover(session)
                }
            }
    }

    // MARK: - Demo-owned scanning UI (shown for the initial scan, before the editor presents)

    @ViewBuilder private var scanningHost: some View {
        NavigationStack {
            VStack {
                HStack {
                    ToolbarButton(imageName: "ic_shevron_back", dualMode: true,
                                  a11yID: A11yID.OCR.dismissButton, action: model.closeView)
                    Spacer()
                    Text(model.selectedLanguagesString)
                        .foregroundColor(MyColor.labelsPrimary)
                }
                .zIndex(10)

                ProgressView(value: model.scanProgress, total: 100)
                    .progressViewStyle(.linear)

                Spacer()

                if let image = model.scanImage {
                    image
                        .resizable()
                        .scaledToFit()
                } else if !model.selectedLanguages.isEmpty {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(6)
                }

                Spacer()
            }
            .navigationTitle("")
            // The no-languages alert lives INSIDE the NavigationStack, not on the outer
            // body next to the cover modifier.
            .alert(isPresented: $model.alert) {
                Alert(
                    title: Text("alert-warning"),
                    message: Text("ocr-no-languages-selected"),
                    primaryButton: .cancel(Text("alert-cancel"), action: model.cancelScan),
                    secondaryButton: .destructive(Text("ocr-select-languages")) {
                        model.alert = false
                        rootModal = .picker
                    }
                )
            }
        }
    }

    // MARK: - Pre-editor language picker (from the no-languages alert)

    @ViewBuilder private var preEditorPickerCover: some View {
        PxUiLanguagePickerScreenView(configuration: makeOCRLanguagePickerConfiguration()) { _ in
            // Dismiss the picker, apply the selection + re-scan; the editor is promoted
            // from this cover's onDismiss once the scan completes (promotePendingEditor).
            rootModal = nil
            model.applyLanguagePickerReturn()
        }
        .ignoresSafeArea()
    }

    // MARK: - Framework OCR editor (presented once a result exists)

    @ViewBuilder private func editorCover(_ session: PxUiOcrEditorSession) -> some View {
        PxUiOcrEditorScreenView(
            configuration: makeEditorConfiguration(),
            session: session
        ) { result in
            // Dismiss path: hold the edited ATTRIBUTED text so re-open seeds from it (not from
            // the result's now-mismatched ranges), then close the OCR feature.
            //
            // Do NOT write editedText back into scanResult.text. That round-trips through
            // PxTextResult.setText:, which CORRUPTS the text to empty for some inputs (the
            // cStringUsingEncoding NUL-terminated wchar_t* → std::wstring path) — even on a
            // no-edit dismiss — emptying scanResult.text and breaking TXT export (which reads
            // res.text). The engine's recognised text is already in scanResult.text and is what
            // every export reader wants, so leave it untouched. Propagating edited text into
            // the exported TXT/PDF is a separate concern blocked by that setText: bug.
            if case .finished(_, let attributedText) = result {
                model.lastEditedText = attributedText
            }
            rootModal = nil
            closeFeature()
        }
        .ignoresSafeArea()
        // Change-language picker — nested inside the (already-presented) editor content.
        .fullScreenCover(isPresented: $changeLanguageShown) {
            PxUiLanguagePickerScreenView(configuration: makeOCRLanguagePickerConfiguration()) { _ in
                changeLanguageShown = false
                model.applyLanguagePickerReturn()
                // Refresh the toolbar summary; a re-scan (if the selection changed) flows
                // back through scanResultVersion → handleScanCompletion (finishRescan).
                session.languageSummary = model.selectedLanguagesString
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Configuration

    private func makeEditorConfiguration() -> PxUiOcrEditorScreenConfiguration {
        PxUiOcrEditorScreenConfiguration(
            onRescanRequested: {
                session?.beginRescan()
                model.startScan()
            },
            onChangeLanguageRequested: {
                changeLanguageShown = true
            }
        )
    }

    // MARK: - Presentation entry (onAppear)

    // Re-opening the OCR feature on a document that already has a result must skip straight
    // to the editor with the existing (possibly hand-edited) result — not re-scan, and not
    // sit on the scanning screen forever (startScanIfNotScanned would no-op, so no completion
    // fires to present the editor). Only scan when there is no current result.
    private func presentExistingResultOrScan() {
        if let result = model.scanResult,
           let image = ContentModel.inst.cutUiImage,
           model.scannedSelectedLanguagesString == model.selectedLanguagesSignature {
            // Seed from the held edited text so a prior edit survives re-open; the editor
            // does not re-derive its text from `result` (whose ranges no longer match).
            let existing = PxUiOcrEditorSession(result: result, image: image,
                                                languageSummary: model.selectedLanguagesString,
                                                seedText: model.lastEditedText)
            session = existing
            rootModal = .editor(existing)
        } else {
            model.startScanIfNotScanned()
        }
    }

    // MARK: - Scan-completion bridge

    private func handleScanCompletion() {
        guard let result = model.scanResult,
              let image = ContentModel.inst.cutUiImage else { return }

        if let session {
            // Re-scan finished — swap the fresh result + image into the live editor.
            session.finishRescan(result: result, image: image)
            session.languageSummary = model.selectedLanguagesString
        } else {
            // First scan finished — build the session (held in @State for the re-scan /
            // progress / change-language paths) and carry the SAME reference in the
            // presentation item so the cover content never reads a not-yet-propagated nil.
            let newSession = PxUiOcrEditorSession(result: result, image: image,
                                                  languageSummary: model.selectedLanguagesString)
            session = newSession
            // If the pre-editor picker is still up (no-languages → install → return path),
            // defer the present to its onDismiss; otherwise present now.
            if case .picker = rootModal {
                pendingEditorPresent = true
            } else {
                rootModal = .editor(newSession)
            }
        }
    }

    // Called from the single cover's onDismiss — promotes the editor after the picker has
    // fully torn down, so the editor present never collides with the picker dismiss.
    private func promotePendingEditor() {
        if pendingEditorPresent, let session {
            pendingEditorPresent = false
            rootModal = .editor(session)
        }
    }

    private func closeFeature() {
        // Closing the OCR feature returns to the main screen and tears down this host
        // (ContentView gates it on viewShown), clearing all latch state for re-entry.
        session = nil
        model.viewShown = false
        model.cancelScan()
    }
}

struct OCRView_Previews: PreviewProvider {
    static var previews: some View {
        OCRTextView()
    }
}
