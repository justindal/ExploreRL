import SwiftUI

struct OptimizersPage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                introSection
                gradientDescentSection
                sgdSection
                momentumSection
                adamSection
                learningRateSection
                comparisonSection
                inRLSection
                tipsSection
            }
            .padding()
        }
    }
}

extension OptimizersPage {
    private var introSection: some View {
        Text("Optimizers determine how neural network weights are updated during training. They use computed gradients to adjust weights in a direction that reduces the loss.")
            .foregroundStyle(.secondary)
    }

    private var gradientDescentSection: some View {
        ExploreSectionCard(title: "Gradient Descent Basics") {
            Text("The fundamental idea: move weights in the opposite direction of the gradient to minimize loss.")
                .foregroundStyle(.secondary)

            EquationBlock(text: "θ ← θ − η · ∇L(θ)")

            BulletList(items: [
                "θ: model parameters (weights and biases)",
                "η: learning rate, step size",
                "∇L(θ): gradient of loss with respect to θ",
                "Negative sign: we descend (minimize), not ascend"
            ])
        }
    }

    private var sgdSection: some View {
        ExploreSectionCard(title: "SGD (Stochastic Gradient Descent)") {
            Text("The simplest optimizer. Updates weights using gradients from a mini-batch of samples.")
                .foregroundStyle(.secondary)

            EquationBlock(text: "θ ← θ − η · ∇L(θ)")

            BulletList(items: [
                "\"Stochastic\" = uses random sample/batch, not full dataset",
                "Simple and memory efficient",
                "Can oscillate in ravines (narrow valleys)",
                "Sensitive to learning rate choice"
            ])
        }
    }

    private var momentumSection: some View {
        ExploreSectionCard(title: "Momentum") {
            Text("Adds a velocity term that accumulates past gradients, helping navigate ravines and escape local minima.")
                .foregroundStyle(.secondary)

            EquationBlock(text: "v ← βv + ∇L(θ)\nθ ← θ − η · v")

            BulletList(items: [
                "v: velocity (accumulated gradient)",
                "β: momentum coefficient (typically 0.9)",
                "Accelerates in consistent gradient directions",
                "Dampens oscillations in inconsistent directions"
            ])
        }
    }

    private var adamSection: some View {
        ExploreSectionCard(title: "Adam (Adaptive Moment Estimation)") {
            Text("The most popular optimizer for deep RL. Combines momentum with per-parameter adaptive learning rates.")
                .foregroundStyle(.secondary)

            CodeBlock([
                "m ← β₁ · m + (1 - β₁) · g      // First moment (mean)",
                "v ← β₂ · v + (1 - β₂) · g²     // Second moment (variance)",
                "m̂ ← m / (1 - β₁ᵗ)              // Bias correction",
                "v̂ ← v / (1 - β₂ᵗ)              // Bias correction",
                "θ ← θ − η · m̂ / (√v̂ + ε)"
            ])

            BulletList(items: [
                "β₁ = 0.9: exponential decay for first moment",
                "β₂ = 0.999: exponential decay for second moment",
                "ε = 1e-8: prevents division by zero",
                "Adapts learning rate per parameter based on gradient history"
            ])
        }
    }

    private var learningRateSection: some View {
        ExploreSectionCard(title: "Learning Rate") {
            Text("The learning rate η is the most important hyperparameter:")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                rateItem(rate: "Too high", effect: "Diverges, loss explodes")
                rateItem(rate: "Too low", effect: "Very slow convergence")
                rateItem(rate: "Just right", effect: "Steady loss decrease")
            }

            Text("Common approach: start with 3e-4 for Adam, reduce if unstable.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
    }

    private func rateItem(rate: String, effect: String) -> some View {
        HStack {
            Text(rate)
                .fontWeight(.medium)
                .frame(width: 80, alignment: .leading)
            Text(effect)
                .foregroundStyle(.secondary)
        }
    }

    private var comparisonSection: some View {
        ExploreSectionCard(title: "Optimizer Comparison") {
            VStack(alignment: .leading, spacing: 12) {
                optimizerRow(name: "SGD", pros: "Simple, low memory", cons: "Slow, sensitive to lr")
                optimizerRow(name: "Momentum", pros: "Faster, less oscillation", cons: "Extra hyperparameter")
                optimizerRow(name: "RMSprop", pros: "Adaptive lr per param", cons: "No momentum")
                optimizerRow(name: "Adam", pros: "Best of both worlds", cons: "Slightly more memory")
            }
        }
    }

    private func optimizerRow(name: String, pros: String, cons: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name).fontWeight(.medium)
            HStack(alignment: .top, spacing: 16) {
                HStack(alignment: .top, spacing: 4) {
                    Text("✓")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Text(pros)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(alignment: .top, spacing: 4) {
                    Text("✗")
                        .font(.caption)
                        .foregroundStyle(.red)
                    Text(cons)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var inRLSection: some View {
        ExploreSectionCard(title: "Optimizers in RL") {
            Text("Deep RL typically uses Adam with these considerations:")
                .foregroundStyle(.secondary)

            BulletList(items: [
                "Learning rate: 1e-4 to 3e-4 (lower than supervised learning)",
                "Separate optimizers for actor and critic networks",
                "Gradient clipping often used for stability",
                "Some algorithms use different lr for different networks"
            ])

            VStack(alignment: .leading, spacing: 8) {
                Text("Typical configurations:").fontWeight(.medium)
                    .padding(.top, 8)
                Text("DQN: Adam, lr=1e-4")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("SAC: Adam, lr=3e-4 for actor and critics")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var tipsSection: some View {
        ExploreSectionCard(title: "Practical Tips") {
            BulletList(items: [
                "Start with Adam because it works well out of the box",
                "Use lr=3e-4 as a starting point",
                "If training is unstable, try lowering learning rate",
                "Monitor gradient norms to detect explosion/vanishing",
                "Consider gradient clipping (max_grad_norm=0.5)",
                "Learning rate schedules can help (linear decay)"
            ])
        }
    }
}
