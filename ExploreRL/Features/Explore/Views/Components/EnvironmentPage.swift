import SwiftUI

struct EnvironmentPage: View {
    let title: String
    let intro: String
    let observations: [String]
    let actions: [String]
    let rewards: [String]
    var tips: [String] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(intro)
                    .foregroundStyle(.secondary)

                ExploreSectionCard(title: "Observations") {
                    BulletList(items: observations)
                }

                ExploreSectionCard(title: "Actions") {
                    BulletList(items: actions)
                }

                ExploreSectionCard(title: "Rewards") {
                    BulletList(items: rewards)
                }

                if !tips.isEmpty {
                    ExploreSectionCard(title: "Tips") {
                        BulletList(items: tips)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(title)
    }
}
