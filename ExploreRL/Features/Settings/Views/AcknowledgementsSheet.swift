import SwiftUI

private struct Acknowledgement: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let url: URL?
}

private let acknowledgements: [Acknowledgement] = [
    Acknowledgement(
        name: "Gymnazo",
        description: "A reinforcement learning toolkit for Swift, inspired by Gymnasium.",
        url: URL(string: "https://github.com/justindal/Gymnazo")
    ),
    Acknowledgement(
        name: "MLX Swift",
        description: "High-performance machine learning framework for Apple Silicon by Apple.",
        url: URL(string: "https://github.com/ml-explore/mlx-swift")
    ),
    Acknowledgement(
        name: "Swift Collections",
        description: "Data structure implementations for Swift by Apple.",
        url: URL(string: "https://github.com/apple/swift-collections")
    ),
    Acknowledgement(
        name: "Box2D",
        description: "A 2D physics engine for games, used by Gymnazo environments.",
        url: URL(string: "https://box2d.org")
    ),
    Acknowledgement(
        name: "Stable Baselines3",
        description: "A reliable reinforcement learning algorithms library in Python.",
        url: URL(string: "https://github.com/DLR-RM/stable-baselines3")
    ),
    Acknowledgement(
        name: "RL Baselines3 Zoo",
        description: "Training scripts, tuned hyperparameters, and benchmarks for Stable Baselines3.",
        url: URL(string: "https://github.com/DLR-RM/rl-baselines3-zoo")
    ),
]

struct AcknowledgementsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List(acknowledgements) { item in
                Button {
                    if let url = item.url {
                        openURL(url)
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.name)
                                .font(.body.weight(.semibold))
                            Spacer()
                            if item.url != nil {
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Text(item.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
                .tint(.primary)
                #if os(macOS)
                .listRowSeparator(.hidden)
                #endif
            }
            .navigationTitle("Acknowledgements")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            #if os(macOS)
            .frame(minWidth: 400, idealWidth: 500, minHeight: 400)
            #endif
        }
    }
}
