#if os(macOS)
    import SwiftUI

    struct MacHomeSessionActionButton: View {
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
                            .controlSize(.small)
                            #if os(macOS)
                                .tint(tint)
                            #endif
                    } else {
                        button
                            .buttonStyle(.glass(.clear))
                            .controlSize(.small)
                    }
                } else if isProminent {
                    button
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(tint)
                } else {
                    button
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.primary)
                }
            }
        }
    }
#endif
