import SwiftUI

struct DQNPage: View {
    var body: some View {
        ExploreDocPage(title: "DQN") {
            introSection
            whyDeepSection
            networkArchitectureSection
            targetNetworkSection
            experienceReplaySection
            lossSection
            algorithmSection
            explorationSection
            parametersSection
            vsTabularSection
            whenToUseSection
            limitationsSection
        }
    }
}

extension DQNPage {
    private var introSection: some View {
        Text("Deep Q-Network (DQN) extends Q-Learning to handle large or continuous state spaces by using a neural network to approximate Q-values. It introduced two key innovations: experience replay and target networks.")
            .foregroundStyle(.secondary)
    }

    private var whyDeepSection: some View {
        ExploreSectionCard(title: "Why Deep Learning?") {
            Text("Tabular Q-Learning fails when state spaces are too large to enumerate:")
                .foregroundStyle(.secondary)

            BulletList(items: [
                "Atari games: ~10¹⁸ possible screen configurations",
                "Continuous states: infinite possible values",
                "High dimensions: curse of dimensionality"
            ])

            Text("Neural networks generalize across similar states; learning Q(s,a) for one state helps estimate Q-values for similar unseen states.")
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    private var networkArchitectureSection: some View {
        ExploreSectionCard(title: "Network Architecture") {
            Text("The Q-network takes a state as input and outputs Q-values for all actions:")
                .foregroundStyle(.secondary)

            CodeBlock([
                "Input:  State s (e.g., image pixels, sensor readings)",
                "        ↓",
                "Hidden: Dense layers or CNN for feature extraction",
                "        ↓",
                "Output: Q(s, a₁), Q(s, a₂), ..., Q(s, aₙ)",
                "        One output per action"
            ])

            Text("This design is efficient: one forward pass gives Q-values for all actions, enabling fast argmax for action selection.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    private var targetNetworkSection: some View {
        ExploreSectionCard(title: "Target Network") {
            Text("A key insight: using the same network for both prediction and target leads to instability. The target keeps moving as we update.")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("The solution:").fontWeight(.medium)
                BulletList(items: [
                    "Maintain two networks: Q (online) and Q⁻ (target)",
                    "Train Q using targets computed from Q⁻",
                    "Periodically copy Q → Q⁻ (or use soft updates)"
                ])
            }

            EquationBlock(text: "Target: y = r + γ max Q⁻(s′, a′)")

            Text("This decouples the target from rapid changes, stabilizing learning.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    private var experienceReplaySection: some View {
        ExploreSectionCard(title: "Experience Replay") {
            Text("Neural networks assume training samples are independent. Sequential RL data violates this because consecutive states are highly correlated.")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Replay buffer benefits:").fontWeight(.medium)
                BulletList(items: [
                    "Breaks temporal correlation by sampling randomly",
                    "Each experience can be used for multiple updates",
                    "Improves sample efficiency significantly",
                    "Enables mini-batch gradient descent"
                ])
            }

            CodeBlock([
                "Buffer stores: (s, a, r, s′, done)",
                "Capacity: 10,000 – 1,000,000 transitions",
                "Sample: random mini-batch for each update"
            ])
        }
    }

    private var lossSection: some View {
        ExploreSectionCard(title: "Loss Function") {
            Text("DQN minimizes the mean squared TD error:")
                .foregroundStyle(.secondary)

            EquationBlock(text: "L(θ) = E[ (y − Q_θ(s,a))² ]")

            VStack(alignment: .leading, spacing: 8) {
                Text("Where:").fontWeight(.medium)
                BulletList(items: [
                    "y = r + γ max Q⁻(s′,a′) is the TD target",
                    "Q_θ(s,a) is the current network's prediction",
                    "Gradient descent updates θ to minimize L"
                ])
            }

            Text("Some implementations use Huber loss instead of MSE for robustness to outliers.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    private var algorithmSection: some View {
        ExploreSectionCard(title: "Algorithm Walkthrough") {
            Text("The complete DQN training loop:")
                .foregroundStyle(.secondary)

            CodeBlock([
                "Initialize Q network with random weights θ",
                "Initialize target network Q⁻ with weights θ⁻ = θ",
                "Initialize replay buffer D",
                "",
                "For each episode:",
                "    s ← initial state",
                "    ",
                "    While not done:",
                "        a ← ε-greedy from Q(s, ·)",
                "        Take a, observe r, s′, done",
                "        Store (s, a, r, s′, done) in D",
                "        ",
                "        Sample mini-batch from D",
                "        y = r + γ max Q⁻(s′,·)  (0 if done)",
                "        Update θ by gradient descent on (y − Q(s,a))²",
                "        ",
                "        Soft update: θ⁻ ← τθ + (1-τ)θ⁻",
                "        s ← s′",
                "    Decay ε"
            ])
        }
    }

    private var explorationSection: some View {
        ExploreSectionCard(title: "Exploration Strategy") {
            Text("DQN typically uses linear ε-decay:")
                .foregroundStyle(.secondary)

            CodeBlock([
                "ε starts at 1.0 (fully random)",
                "ε decays linearly over exploration_fraction of training",
                "ε ends at ε_min (e.g., 0.01 or 0.05)"
            ])

            Text("Example: with 1M steps and exploration_fraction=0.1, ε decays from 1.0 to 0.01 over the first 100K steps, then stays at 0.01.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    private var parametersSection: some View {
        ExploreParametersCard(
            title: "Key Hyperparameters",
            parameters: [
                ExploreParameter(
                    name: "Learning Rate",
                    typical: "1e-4 – 1e-3",
                    description: "Optimizer step size. Lower than supervised learning."
                ),
                ExploreParameter(
                    name: "Buffer Size",
                    typical: "10K – 1M",
                    description: "Larger buffers improve stability but use more memory."
                ),
                ExploreParameter(
                    name: "Batch Size",
                    typical: "32 – 256",
                    description: "Transitions per gradient update."
                ),
                ExploreParameter(
                    name: "γ (Discount)",
                    typical: "0.99",
                    description: "Usually high for deep RL to value future rewards."
                ),
                ExploreParameter(
                    name: "τ (Target Update)",
                    typical: "0.005 – 0.01",
                    description: "Soft update rate. Lower = more stable, slower."
                ),
                ExploreParameter(
                    name: "Learning Starts",
                    typical: "1K – 50K",
                    description: "Steps before training begins. Fills buffer first."
                ),
            ]
        )
    }

    private var vsTabularSection: some View {
        ExploreComparisonCard(
            title: "DQN vs Tabular Q‑Learning",
            leftTitle: "Tabular",
            rightTitle: "DQN",
            rows: [
                ExploreComparison(
                    aspect: "Value storage",
                    left: "Q-table (explicit)",
                    right: "Neural network (implicit)"
                ),
                ExploreComparison(
                    aspect: "State space",
                    left: "Discrete, small",
                    right: "Continuous, large"
                ),
                ExploreComparison(
                    aspect: "Generalization",
                    left: "None",
                    right: "Across similar states"
                ),
                ExploreComparison(
                    aspect: "Sample efficiency",
                    left: "One update per transition",
                    right: "Many updates via replay"
                ),
                ExploreComparison(
                    aspect: "Stability",
                    left: "Guaranteed convergence",
                    right: "Requires careful tuning"
                ),
            ]
        )
    }

    private var whenToUseSection: some View {
        ExploreSectionCard(title: "When to Use DQN") {
            BulletList(items: [
                "State space too large for tabular methods",
                "Discrete action space (DQN requires argmax over actions)",
                "Image-based observations (Atari, visual tasks)",
                "Environments like CartPole, LunarLander, MountainCar"
            ])
        }
    }

    private var limitationsSection: some View {
        ExploreSectionCard(title: "Limitations") {
            BulletList(items: [
                "Discrete actions only: can't handle continuous control",
                "Overestimation bias: max operator tends to overestimate Q",
                "Hyperparameter sensitive: learning rate, buffer, architecture",
                "Sample inefficient compared to model-based methods",
                "For continuous actions, use SAC or DDPG instead"
            ])
        }
    }
}
