import SwiftUI
#if os(iOS)
import UIKit
import UniformTypeIdentifiers

struct FolderPicker: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: [.folder], asCopy: false)
        controller.directoryURL = url
        controller.allowsMultipleSelection = false
        return controller
    }
    
    func updateUIViewController(_ controller: UIDocumentPickerViewController, context: Context) {}
}
#endif

