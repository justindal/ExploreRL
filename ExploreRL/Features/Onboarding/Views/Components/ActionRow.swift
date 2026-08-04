import SwiftUI

struct ActionRow: View {
    @Binding var currentIndex: Int
    let pageCount: Int
    let onFinish: () -> Void

    init(
        currentIndex: Binding<Int>,
        pageCount: Int,
        onFinish: @escaping () -> Void = {}
    ) {
        _currentIndex = currentIndex
        self.pageCount = pageCount
        self.onFinish = onFinish
    }

    var body: some View {
        HStack(spacing: 12) {
            if currentIndex > 0 {
                backButton
            }
            continueButton
        }
        .padding(.horizontal, 10)
        .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
        .frame(maxWidth: .infinity, alignment: .bottom)
    }

    private var isLastPage: Bool {
        pageCount > 0 && currentIndex >= pageCount - 1
    }

    private var backButton: some View {
        Button {
            withAnimation(.indicatorAnimation) {
                currentIndex = max(currentIndex - 1, 0)
            }
        } label: {
            Text("Back")
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .modify { view in
            if #available(iOS 26.0, macOS 26.0, *) {
                view.buttonStyle(.glassProminent)
                    .buttonSizing(.flexible)
            } else {
                view
                    .buttonStyle(.bordered)
                    .controlSize(.large)
            }
        }
        .tint(.secondary)
    }

    private var continueButton: some View {
        Button {
            if isLastPage {
                onFinish()
            } else {
                withAnimation(.indicatorAnimation) {
                    currentIndex = min(currentIndex + 1, pageCount - 1)
                }
            }
        } label: {
            Text(isLastPage ? "Get Started" : "Continue")
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .modify { view in
            if #available(iOS 26.0, macOS 26.0, *) {
                view.buttonStyle(.glassProminent)
                    .buttonSizing(.flexible)
            } else {
                view
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        }
    }
}
