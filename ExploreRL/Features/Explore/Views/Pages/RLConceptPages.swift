import SwiftUI

struct RLLoopPage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("The fundamental cycle driving all reinforcement learning.")
                    .foregroundStyle(.secondary)

                ExploreSectionCard(title: "The cycle") {
                    Text("At each timestep the agent observes the environment, selects an action, and receives a reward and next observation.")
                        .foregroundStyle(.secondary)
                    EquationBlock(text: "sₜ → aₜ → (rₜ₊₁, sₜ₊₁)")
                }

                ExploreSectionCard(title: "Episodes") {
                    Text("An episode runs from an initial state until a terminal condition or step limit. The goal is to maximize total reward per episode.")
                        .foregroundStyle(.secondary)
                }

                ExploreSectionCard(title: "Policy") {
                    Text("A policy maps states to actions. It can be deterministic or stochastic.")
                        .foregroundStyle(.secondary)
                    EquationBlock(text: "π(a|s) = P(aₜ = a | sₜ = s)")
                }
            }
            .padding()
        }
    }
}

struct ReturnsPage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("How agents measure long-term value.")
                    .foregroundStyle(.secondary)

                ExploreSectionCard(title: "Discounted return") {
                    Text("The return is the sum of future rewards, each discounted by γ per timestep.")
                        .foregroundStyle(.secondary)
                    EquationBlock(text: "Gₜ = rₜ₊₁ + γ rₜ₊₂ + γ² rₜ₊₃ + ...")
                }

                ExploreSectionCard(title: "Discount factor γ") {
                    BulletList(items: [
                        "γ = 0: only immediate reward matters",
                        "γ = 1: all future rewards weighted equally",
                        "Typical range: 0.95 – 0.99"
                    ])
                }

                ExploreSectionCard(title: "TD error") {
                    Text("Many algorithms learn from a one-step prediction error rather than waiting for the full return.")
                        .foregroundStyle(.secondary)
                    EquationBlock(text: "δₜ = rₜ₊₁ + γ V(sₜ₊₁) − V(sₜ)")
                }
            }
            .padding()
        }
    }
}

struct ExplorationPage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Balancing new knowledge against known reward.")
                    .foregroundStyle(.secondary)

                ExploreSectionCard(title: "The tradeoff") {
                    Text("Exploit: choose the best-known action. Explore: try something new that might be better.")
                        .foregroundStyle(.secondary)
                }

                ExploreSectionCard(title: "ε‑greedy") {
                    Text("With probability ε take a random action, otherwise take the greedy action. ε typically decays over training.")
                        .foregroundStyle(.secondary)
                    EquationBlock(text: "a = random with prob ε, argmax Q(s,·) otherwise")
                }

                ExploreSectionCard(title: "Entropy regularization") {
                    Text("SAC adds an entropy bonus to the objective, encouraging the policy to remain stochastic.")
                        .foregroundStyle(.secondary)
                    EquationBlock(text: "J(π) = E[ r + α H(π(·|s)) ]")
                }
            }
            .padding()
        }
    }
}

struct ReplayPage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Reusing past experience to learn more efficiently.")
                    .foregroundStyle(.secondary)

                ExploreSectionCard(title: "Why replay?") {
                    BulletList(items: [
                        "Breaks temporal correlation between consecutive samples",
                        "Each transition can be used for multiple updates",
                        "Required by off-policy algorithms (DQN, SAC)"
                    ])
                }

                ExploreSectionCard(title: "Transition format") {
                    EquationBlock(text: "(sₜ, aₜ, rₜ₊₁, sₜ₊₁, done)")
                    Text("The buffer stores a fixed number of recent transitions and overwrites the oldest when full.")
                        .foregroundStyle(.secondary)
                }

                ExploreSectionCard(title: "Training loop") {
                    BulletList(items: [
                        "Collect transitions by interacting with the environment",
                        "Store each transition in the buffer",
                        "Sample a random mini-batch",
                        "Compute loss and update the network"
                    ])
                }
            }
            .padding()
        }
    }
}
