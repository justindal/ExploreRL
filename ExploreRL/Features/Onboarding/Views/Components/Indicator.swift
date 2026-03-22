import SwiftUI

struct Indicator: View {
    let currentIndex: Int
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                let isActive = currentIndex == index
                Capsule()
                    .fill(.opacity(isActive ? 1 : 0.4))
                    .frame(width: isActive ? 15 : 6, height: 6)
                    .animation(.spring(response: 0.3), value: isActive)
            }
        }
        .padding(.bottom, 5)
    }
}
