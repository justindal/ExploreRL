import SwiftUI

struct HomeSessionActionButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    let isProminent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
        }
        .modify { button in
            if #available(iOS 26.0, macOS 26.0, *) {
                if isProminent {
                    button
                        .buttonStyle(.glass(.regular.tint(tint).interactive()))
                        #if os(macOS)
                            .tint(tint)
                        #endif
                } else {
                    button
                        .buttonStyle(.glass(.clear))
                }
            } else if isProminent {
                button
                    .buttonStyle(.borderedProminent)
                    .tint(tint)
            } else {
                button
                    .buttonStyle(.bordered)
                    .tint(.primary)
            }
        }
        #if os(iOS)
            .controlSize(.large)
            .frame(minHeight: 44)
        #else
            .controlSize(.small)
        #endif
    }
}
