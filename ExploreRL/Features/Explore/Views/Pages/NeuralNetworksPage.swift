import SwiftUI

struct NeuralNetworksPage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                introSection
                whatIsNNSection
                architectureSection
                forwardPassSection
                backpropSection
                gradientDescentSection
                trainingLoopSection
                inRLSection
                tipsSection
            }
            .padding()
        }
        .navigationTitle("Neural Networks")
    }
}

extension NeuralNetworksPage {
    private var introSection: some View {
        Text("Neural networks are the function approximators that power deep reinforcement learning. They enable agents to handle large, continuous state spaces that tabular methods cannot.")
            .foregroundStyle(.secondary)
    }

    private var whatIsNNSection: some View {
        ExploreSectionCard(title: "What is a Neural Network?") {
            Text("A neural network is a function that maps inputs to outputs through layers of interconnected neurons. Each neuron computes a weighted sum of its inputs, adds a bias, and applies an activation function.")
                .foregroundStyle(.secondary)

            EquationBlock(text: "y = f(Wx + b)")

            BulletList(items: [
                "x: input vector",
                "W: weight matrix (learned)",
                "b: bias vector (learned)",
                "f: activation function (introduces non-linearity)",
                "y: output vector"
            ])
        }
    }

    private var architectureSection: some View {
        ExploreSectionCard(title: "Network Architecture") {
            Text("A typical feedforward network has multiple layers:")
                .foregroundStyle(.secondary)

            CodeBlock([
                "Input Layer    →  Raw observations (state)",
                "      ↓",
                "Hidden Layer 1 →  Dense(256) + ReLU",
                "      ↓",
                "Hidden Layer 2 →  Dense(256) + ReLU",
                "      ↓",
                "Output Layer   →  Q-values or action distribution"
            ])

            BulletList(items: [
                "More layers = deeper network = more complex functions",
                "More neurons = wider network = more capacity",
                "Too large → overfitting, slow training",
                "Too small → underfitting, can't learn the task"
            ])
        }
    }

    private var forwardPassSection: some View {
        ExploreSectionCard(title: "Forward Pass") {
            Text("The forward pass computes the output given an input by passing data through each layer sequentially:")
                .foregroundStyle(.secondary)

            CodeBlock([
                "h₁ = ReLU(W₁ · x + b₁)",
                "h₂ = ReLU(W₂ · h₁ + b₂)",
                "y  = W₃ · h₂ + b₃"
            ])

            Text("Each layer transforms its input using weights and biases, then applies an activation function (except often the output layer).")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    private var backpropSection: some View {
        ExploreSectionCard(title: "Backpropagation") {
            Text("Backpropagation computes how much each weight contributed to the error, enabling learning:")
                .foregroundStyle(.secondary)

            BulletList(items: [
                "Compute loss (error) from output vs target",
                "Calculate gradient of loss with respect to each weight",
                "Use chain rule to propagate gradients backward",
                "Each weight gets a gradient indicating how to change"
            ])

            EquationBlock(text: "∂L/∂W = ∂L/∂y · ∂y/∂h · ∂h/∂W")

            Text("This is why it's called 'back' propagation: gradients flow from output to input.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    private var gradientDescentSection: some View {
        ExploreSectionCard(title: "Gradient Descent") {
            Text("Gradient descent updates weights in the direction that reduces the loss:")
                .foregroundStyle(.secondary)

            EquationBlock(text: "W ← W − η · ∂L/∂W")

            VStack(alignment: .leading, spacing: 8) {
                Text("Variants:").fontWeight(.medium)
                BulletList(items: [
                    "SGD: Stochastic gradient descent (one sample)",
                    "Mini-batch: Average gradient over batch",
                    "Adam: Adaptive learning rates per parameter"
                ])
            }

            Text("In RL, we typically use Adam with learning rates around 1e-4 to 1e-3.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    private var trainingLoopSection: some View {
        ExploreSectionCard(title: "Training Loop") {
            Text("The neural network training cycle:")
                .foregroundStyle(.secondary)

            CodeBlock([
                "For each batch:",
                "    1. Forward pass: compute predictions",
                "    2. Compute loss: compare to targets",
                "    3. Backward pass: compute gradients",
                "    4. Update weights: apply optimizer step",
                "    5. Zero gradients: reset for next batch"
            ])
        }
    }

    private var inRLSection: some View {
        ExploreSectionCard(title: "Neural Networks in RL") {
            Text("In reinforcement learning, neural networks serve different purposes:")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                roleItem(
                    name: "Q-Network (DQN)",
                    description: "Maps state → Q-values for all actions"
                )

                roleItem(
                    name: "Policy Network",
                    description: "Maps state → action probabilities or distribution"
                )

                roleItem(
                    name: "Value Network",
                    description: "Maps state → expected return V(s)"
                )

                roleItem(
                    name: "Actor-Critic",
                    description: "Separate networks for policy and value"
                )
            }
        }
    }

    private func roleItem(name: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name).fontWeight(.medium)
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var tipsSection: some View {
        ExploreSectionCard(title: "Practical Tips") {
            BulletList(items: [
                "Start with 2 hidden layers of 256 neurons",
                "Use ReLU activation for hidden layers",
                "Normalize inputs when possible",
                "Use Adam optimizer with lr=3e-4",
                "Monitor loss and gradient magnitudes",
                "Use target networks for stability (DQN, SAC)"
            ])
        }
    }
}
