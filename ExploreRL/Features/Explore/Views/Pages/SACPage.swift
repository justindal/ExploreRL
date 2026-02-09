import SwiftUI

struct SACPage: View {
    var body: some View {
        ExploreDocPage(title: "SAC") {
            introSection
            whyContinuousSection
            maxEntropySection
            actorCriticSection
            twinCriticsSection
            entropyTuningSection
            reparamSection
            lossesSection
            algorithmSection
            parametersSection
            vsDQNSection
            whenToUseSection
            limitationsSection
        }
    }
}

extension SACPage {
    private var introSection: some View {
        Text("Soft Actor-Critic (SAC) is a state-of-the-art algorithm for continuous control. It combines actor-critic methods with maximum entropy reinforcement learning, achieving sample efficiency and exploration through an entropy bonus that encourages diverse behavior.")
            .foregroundStyle(.secondary)
    }

    private var whyContinuousSection: some View {
        ExploreSectionCard(title: "Why SAC for Continuous Actions?") {
            Text("DQN requires computing argmax over all actions, which is impossible when actions are continuous:")
                .foregroundStyle(.secondary)

            BulletList(items: [
                "Continuous actions: steering angle, joint torques, throttle",
                "Infinite action space: can't enumerate all possibilities",
                "SAC outputs a probability distribution, then samples actions"
            ])

            Text("SAC learns both a policy (actor) and value estimates (critics) simultaneously, enabling efficient learning in high-dimensional continuous spaces.")
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    private var maxEntropySection: some View {
        ExploreSectionCard(title: "Maximum Entropy RL") {
            Text("Standard RL maximizes expected return. SAC adds an entropy bonus to encourage exploration:")
                .foregroundStyle(.secondary)

            EquationBlock(text: "J(π) = E[ Σₜ γᵗ ( rₜ + α H(π(·|sₜ)) ) ]")

            VStack(alignment: .leading, spacing: 8) {
                Text("Why entropy matters:").fontWeight(.medium)
                BulletList(items: [
                    "H(π) = entropy of the policy's action distribution",
                    "Higher entropy = more random, exploratory actions",
                    "α = temperature controlling the exploration–exploitation trade-off",
                    "Prevents premature convergence to suboptimal deterministic policies"
                ])
            }

            Text("This \"soft\" objective leads to policies that are stochastic by design, not just during training.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    private var actorCriticSection: some View {
        ExploreSectionCard(title: "Actor-Critic Architecture") {
            Text("SAC uses separate networks for the policy (actor) and value estimation (critics):")
                .foregroundStyle(.secondary)

            CodeBlock([
                "Actor (Policy Network):",
                "    Input:  State s",
                "    Output: μ(s), σ(s): mean and std of Gaussian",
                "    Action: a ~ N(μ, σ), then tanh squashing",
                "",
                "Critics (Q-Networks):",
                "    Input:  State s, Action a",
                "    Output: Q(s, a): expected return"
            ])

            VStack(alignment: .leading, spacing: 8) {
                Text("Key design choices:").fontWeight(.medium)
                BulletList(items: [
                    "Actor outputs distribution parameters, not raw actions",
                    "Tanh squashing bounds actions to [-1, 1]",
                    "Critics take state AND action as input (unlike DQN)"
                ])
            }
        }
    }

    private var twinCriticsSection: some View {
        ExploreSectionCard(title: "Twin Critics") {
            Text("SAC uses two critic networks Q₁ and Q₂ to address overestimation bias:")
                .foregroundStyle(.secondary)

            EquationBlock(text: "Q_target = min(Q₁(s′,a′), Q₂(s′,a′))")

            VStack(alignment: .leading, spacing: 8) {
                Text("How it works:").fontWeight(.medium)
                BulletList(items: [
                    "Train two critics independently on the same data",
                    "Use the minimum Q-value for computing targets",
                    "This pessimistic estimate reduces overestimation",
                    "Both critics have their own target networks (soft updated)"
                ])
            }

            Text("This technique, called Clipped Double Q-Learning, was introduced in TD3 and adopted by SAC.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    private var entropyTuningSection: some View {
        ExploreSectionCard(title: "Automatic Entropy Tuning") {
            Text("The entropy coefficient α is crucial but hard to tune. SAC can learn it automatically:")
                .foregroundStyle(.secondary)

            EquationBlock(text: "α* = argmin E[ −α log π(a|s) − α H̄ ]")

            VStack(alignment: .leading, spacing: 8) {
                Text("The mechanism:").fontWeight(.medium)
                BulletList(items: [
                    "H̄ = target entropy (typically −dim(action))",
                    "If policy entropy < target: increase α → more exploration",
                    "If policy entropy > target: decrease α → more exploitation",
                    "α is learned via gradient descent alongside other networks"
                ])
            }

            Text("This removes a sensitive hyperparameter and enables SAC to adapt exploration throughout training.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    private var reparamSection: some View {
        ExploreSectionCard(title: "Reparameterization Trick") {
            Text("To backpropagate through sampled actions, SAC uses the reparameterization trick:")
                .foregroundStyle(.secondary)

            CodeBlock([
                "Instead of: a ~ N(μ, σ)        // can't differentiate",
                "Use:        a = μ + σ · ε      // where ε ~ N(0, 1)",
                "",
                "Then apply: a_bounded = tanh(a)"
            ])

            VStack(alignment: .leading, spacing: 8) {
                Text("Why this matters:").fontWeight(.medium)
                BulletList(items: [
                    "Moves randomness outside the network (ε is fixed noise)",
                    "Gradients flow through μ and σ to update the actor",
                    "Enables end-to-end training of the policy network"
                ])
            }
        }
    }

    private var lossesSection: some View {
        ExploreSectionCard(title: "Loss Functions") {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Critic Loss:").fontWeight(.medium)
                    Text("Mean squared TD error using soft Bellman backup:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    EquationBlock(text: "L_Q = E[ (Q(s,a) − (r + γ(Q_target − α log π(a′|s′))))² ]")
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Actor Loss:").fontWeight(.medium)
                    Text("Maximize expected Q-value plus entropy:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    EquationBlock(text: "L_π = E[ α log π(a|s) − Q(s,a) ]")
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Alpha Loss:").fontWeight(.medium)
                    Text("Adjusts temperature to match target entropy:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    EquationBlock(text: "L_α = E[ −α (log π(a|s) + H̄) ]")
                }
            }
        }
    }

    private var algorithmSection: some View {
        ExploreSectionCard(title: "Algorithm Walkthrough") {
            Text("The complete SAC training loop:")
                .foregroundStyle(.secondary)

            CodeBlock([
                "Initialize actor π, critics Q₁, Q₂, targets Q₁⁻, Q₂⁻",
                "Initialize replay buffer D, entropy coef α",
                "",
                "For each timestep:",
                "    a ~ π(·|s)                    // sample from policy",
                "    Execute a, observe r, s′, done",
                "    Store (s, a, r, s′, done) in D",
                "    ",
                "    Sample batch from D",
                "    ",
                "    // Critic update",
                "    a′ ~ π(·|s′)",
                "    Q_target = r + γ(min(Q₁⁻,Q₂⁻)(s′,a′) − α log π(a′|s′))",
                "    Update Q₁, Q₂ to minimize (Q − Q_target)²",
                "    ",
                "    // Actor update",
                "    a_new ~ π(·|s)",
                "    Update π to minimize α log π(a_new|s) − min(Q₁,Q₂)(s,a_new)",
                "    ",
                "    // Alpha update (if auto-tuning)",
                "    Update α to minimize −α(log π(a_new|s) + H̄)",
                "    ",
                "    // Target update",
                "    Q₁⁻ ← τQ₁ + (1−τ)Q₁⁻",
                "    Q₂⁻ ← τQ₂ + (1−τ)Q₂⁻"
            ])
        }
    }

    private var parametersSection: some View {
        ExploreParametersCard(
            title: "Key Hyperparameters",
            parameters: [
                ExploreParameter(
                    name: "Learning Rate",
                    typical: "3e-4",
                    description: "Same rate often used for actor, critics, and alpha."
                ),
                ExploreParameter(
                    name: "Buffer Size",
                    typical: "100K – 1M",
                    description: "Replay buffer capacity. Larger improves stability."
                ),
                ExploreParameter(
                    name: "Batch Size",
                    typical: "256",
                    description: "Transitions per gradient update."
                ),
                ExploreParameter(
                    name: "γ (Discount)",
                    typical: "0.99",
                    description: "Future reward discounting. Usually high."
                ),
                ExploreParameter(
                    name: "τ (Target Update)",
                    typical: "0.005",
                    description: "Soft update rate for target critics."
                ),
                ExploreParameter(
                    name: "Target Entropy",
                    typical: "−dim(action)",
                    description: "Typical default for continuous control."
                ),
            ]
        )
    }

    private var vsDQNSection: some View {
        ExploreComparisonCard(
            title: "SAC vs DQN",
            leftTitle: "DQN",
            rightTitle: "SAC",
            rows: [
                ExploreComparison(
                    aspect: "Action space",
                    left: "Discrete only",
                    right: "Continuous (or discrete variant)"
                ),
                ExploreComparison(
                    aspect: "Policy type",
                    left: "Implicit (argmax Q)",
                    right: "Explicit (actor network)"
                ),
                ExploreComparison(
                    aspect: "Exploration",
                    left: "ε-greedy",
                    right: "Entropy-driven (stochastic policy)"
                ),
                ExploreComparison(
                    aspect: "Value estimation",
                    left: "Single Q-network + target",
                    right: "Twin critics + targets"
                ),
                ExploreComparison(
                    aspect: "Sample efficiency",
                    left: "Good",
                    right: "Better (off-policy + entropy)"
                ),
            ]
        )
    }

    private var whenToUseSection: some View {
        ExploreSectionCard(title: "When to Use SAC") {
            BulletList(items: [
                "Continuous action spaces (robotics, control, locomotion)",
                "Tasks requiring sample efficiency (real-world robotics)",
                "Environments where exploration is important",
                "Benchmark environments: HalfCheetah, Ant, Humanoid, Pendulum"
            ])
        }
    }

    private var limitationsSection: some View {
        ExploreSectionCard(title: "Limitations") {
            BulletList(items: [
                "More complex: 5+ networks to train simultaneously",
                "Hyperparameter sensitive: target entropy, learning rates",
                "Assumes Gaussian actions: may not suit all distributions",
                "Computationally heavier than simpler methods like PPO",
                "Discrete actions: requires modification (SAC-Discrete)"
            ])
        }
    }
}
