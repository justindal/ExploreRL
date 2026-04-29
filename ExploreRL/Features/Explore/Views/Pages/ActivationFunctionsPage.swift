import SwiftUI

struct ActivationFunctionsPage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                introSection
                whySection
                reluSection
                tanhSection
                sigmoidSection
                softmaxSection
                comparisonSection
                inRLSection
            }
            .padding()
        }
    }
}

extension ActivationFunctionsPage {
    private var introSection: some View {
        Text("Activation functions introduce non-linearity into neural networks. Without them, stacking layers would just produce a linear function, limiting what the network can learn.")
            .foregroundStyle(.secondary)
    }

    private var whySection: some View {
        ExploreSectionCard(title: "Why Non-Linearity?") {
            Text("A sequence of linear transformations is still linear:")
                .foregroundStyle(.secondary)

            EquationBlock(text: "W₂(W₁x) = (W₂W₁)x = Wx")

            Text("Activation functions break this linearity, enabling networks to learn complex, non-linear mappings from states to values or actions.")
                .foregroundStyle(.secondary)
        }
    }

    private var reluSection: some View {
        ExploreSectionCard(title: "ReLU (Rectified Linear Unit)") {
            EquationBlock(text: "ReLU(x) = max(0, x)")

            CodeBlock([
                "    ▲",
                "    │      ╱",
                "    │    ╱",
                "────┼──●────▶",
                "    │",
                "    │"
            ])

            BulletList(items: [
                "Most common activation for hidden layers",
                "Simple, fast to compute",
                "No vanishing gradient for positive values",
                "Can cause \"dead neurons\" if always negative"
            ])
        }
    }

    private var tanhSection: some View {
        ExploreSectionCard(title: "Tanh (Hyperbolic Tangent)") {
            EquationBlock(text: "tanh(x) = (eˣ − e⁻ˣ) / (eˣ + e⁻ˣ)")

            BulletList(items: [
                "Output range: [-1, 1]",
                "Zero-centered (unlike sigmoid)",
                "Can cause vanishing gradients at extremes",
                "Sometimes used for bounded action outputs"
            ])

            Text("In SAC, tanh squashes unbounded Gaussian samples to [-1, 1] for action bounds.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    private var sigmoidSection: some View {
        ExploreSectionCard(title: "Sigmoid") {
            EquationBlock(text: "σ(x) = 1 / (1 + e⁻ˣ)")

            BulletList(items: [
                "Output range: (0, 1)",
                "Useful for probabilities",
                "Suffers from vanishing gradients",
                "Rarely used in hidden layers today"
            ])
        }
    }

    private var softmaxSection: some View {
        ExploreSectionCard(title: "Softmax") {
            EquationBlock(text: "softmax(xᵢ) = eˣⁱ / Σⱼ eˣʲ")

            BulletList(items: [
                "Converts logits to probability distribution",
                "All outputs sum to 1",
                "Used for discrete action selection",
                "Temperature parameter controls sharpness"
            ])

            Text("In discrete action policies, softmax over Q-values or logits gives action probabilities.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    private var comparisonSection: some View {
        ExploreSectionCard(title: "Comparison") {
            VStack(alignment: .leading, spacing: 12) {
                activationRow(name: "ReLU", range: "[0, ∞)", use: "Hidden layers")
                activationRow(name: "Tanh", range: "[-1, 1]", use: "Bounded outputs")
                activationRow(name: "Sigmoid", range: "(0, 1)", use: "Binary probabilities")
                activationRow(name: "Softmax", range: "(0, 1), Σ=1", use: "Action distributions")
                activationRow(name: "None", range: "ℝ", use: "Q-values, unbounded outputs")
            }
        }
    }

    private func activationRow(name: String, range: String, use: String) -> some View {
        HStack {
            Text(name)
                .fontWeight(.medium)
                .frame(width: 70, alignment: .leading)
            Text(range)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(use)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var inRLSection: some View {
        ExploreSectionCard(title: "Usage in RL") {
            VStack(alignment: .leading, spacing: 8) {
                Text("DQN:").fontWeight(.medium)
                Text("ReLU in hidden layers → Linear output (Q-values can be any real number)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Discrete Policy:").fontWeight(.medium)
                Text("ReLU in hidden layers → Softmax output (action probabilities)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)

            VStack(alignment: .leading, spacing: 8) {
                Text("SAC (Continuous):").fontWeight(.medium)
                Text("ReLU in hidden layers → Linear (mean) + Softplus (std) → Tanh squashing")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
        }
    }
}
