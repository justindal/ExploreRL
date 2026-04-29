import SwiftUI

struct AlgorithmPage: View {
    let title: String
    let intro: String
    let equationLabel: String
    let equation: String
    let details: [String]
    let parameters: [String]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(intro)
                    .foregroundStyle(.secondary)

                ExploreSectionCard(title: equationLabel) {
                    EquationBlock(text: equation)
                }

                ExploreSectionCard(title: "How it works") {
                    BulletList(items: details)
                }

                ExploreSectionCard(title: "Key parameters") {
                    BulletList(items: parameters)
                }
            }
            .padding()
        }
    }
}
