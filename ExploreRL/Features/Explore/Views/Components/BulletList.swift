import SwiftUI

struct BulletList: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { item in
                Text("• \(item)")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

