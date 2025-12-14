import SwiftUI

#if os(iOS)
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}

#else
import AppKit

struct SafariView: View {
    let url: URL
    
    var body: some View {
        Color.clear
            .frame(height: 0.1)
            .onAppear {
                NSWorkspace.shared.open(url)
            }
    }
}

#endif

#Preview {
    SafariView(url: URL(string: "https://explorerl.notion.site/")!)
}

