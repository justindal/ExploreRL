import SwiftUI

struct DDPGPage: View {
    var relatedItems: [ExploreItem] = []
    var body: some View {
        ExploreDocPage(title: "DDPG", relatedItems: relatedItems) {
            introSection
            actorCriticSection
            dqnInnovationsSection
            deterministicPolicyGradientSection
            explorationSection
            algorithmSection
            targetUpdatesSection
            comparisonSection
            whenToUseSection
            limitationsSection
            td3ConnectionSection
        }
    }
}

extension DDPGPage {
    private var introSection: some View {
        Text(
            "Deep Deterministic Policy Gradient (DDPG) extends DQN to continuous action spaces by using an actor-critic architecture. The actor learns a deterministic policy μ(s), while the critic learns Q(s,a) to evaluate actions. Like DQN, it uses experience replay and target networks for stability."
        )
        .foregroundStyle(.secondary)
    }

    private var actorCriticSection: some View {
        ExploreSectionCard(title: "Actor-Critic Architecture") {
            Text(
                "DDPG uses two neural networks that work together: the actor decides what to do, and the critic judges how good that decision was."
            )
            .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Actor μ(s | θᵘ)").fontWeight(.medium)
                BulletList(items: [
                    "Maps state s → continuous action a (deterministic)",
                    "Learns the optimal policy directly",
                    "Updated via the deterministic policy gradient",
                ])
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Critic Q(s, a | θᵠ)").fontWeight(.medium)
                BulletList(items: [
                    "Maps (state, action) → scalar Q-value",
                    "Evaluates how good an action is in a given state",
                    "Updated via TD error (like DQN)",
                ])
            }
            .padding(.top, 4)

            CodeBlock([
                "Actor:  a = μ(s)",
                "Critic: q = Q(s, a)",
                "",
                "Together:  Q(s, μ(s))  ←  value of the policy",
            ])
        }
    }

    private var dqnInnovationsSection: some View {
        ExploreSectionCard(title: "Key Innovations from DQN") {
            Text(
                "DDPG inherits two stability mechanisms from DQN that make deep RL with continuous actions possible:"
            )
            .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Experience Replay").fontWeight(.medium)
                BulletList(items: [
                    "Store transitions (s, a, r, s′, done) in a replay buffer",
                    "Sample random mini-batches to break temporal correlation",
                    "Enables off-policy learning and improves sample efficiency",
                ])
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Target Networks").fontWeight(.medium)
                BulletList(items: [
                    "Separate target actor μ′ and target critic Q′",
                    "Compute TD targets using target networks for stability",
                    "Target networks change slowly, preventing feedback loops",
                ])
            }
            .padding(.top, 4)

            Text(
                "These two ideas are what allow DDPG (and DQN) to train deep neural networks for RL without diverging."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }

    private var deterministicPolicyGradientSection: some View {
        ExploreSectionCard(title: "Deterministic Policy Gradient") {
            Text(
                "Unlike stochastic policy gradients (which sample actions), DDPG uses a deterministic policy. The gradient flows through the critic to the actor using the chain rule:"
            )
            .foregroundStyle(.secondary)

            EquationBlock(text: "∇_θ J ≈ E[ ∇_a Q(s, a) · ∇_θ μ(s) ]")

            VStack(alignment: .leading, spacing: 8) {
                Text("Intuition:").fontWeight(.medium)
                BulletList(items: [
                    "∇_a Q(s,a): how changes in the action affect Q-value",
                    "∇_θ μ(s): how changes in actor parameters affect the action",
                    "Product: adjust actor to increase actions that yield higher Q",
                ])
            }

            Text(
                "This is an off-policy gradient: the expectation is over states from the replay buffer, not the current policy's trajectory. This makes DDPG more sample-efficient than on-policy methods."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }

    private var explorationSection: some View {
        ExploreSectionCard(title: "Exploration Strategy") {
            Text(
                "Since the actor is deterministic, DDPG must add external noise to explore. Two common noise processes are used:"
            )
            .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Gaussian Noise").fontWeight(.medium)
                BulletList(items: [
                    "Simple: a ← μ(s) + N(0, σ²)",
                    "σ is typically annealed or fixed at a small value",
                    "Most common in modern implementations",
                ])
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Ornstein-Uhlenbeck Process").fontWeight(.medium)
                BulletList(items: [
                    "Temporally correlated noise: current step depends on previous",
                    "Useful for physical systems with momentum (e.g., robotics)",
                    "Original DDPG paper used this; many now prefer Gaussian",
                ])
            }
            .padding(.top, 4)

            CodeBlock([
                "Exploration: a_explore = μ(s) + noise",
                "Inference:  a = μ(s)   (no noise)",
            ])
        }
    }

    private var algorithmSection: some View {
        ExploreSectionCard(title: "Algorithm Walkthrough") {
            Text("The complete DDPG training loop:")
                .foregroundStyle(.secondary)

            CodeBlock([
                "Initialize actor μ and critic Q with random weights",
                "Initialize target networks: μ′ ← μ, Q′ ← Q",
                "Initialize replay buffer D",
                "",
                "For each episode:",
                "    s ← initial state",
                "    ",
                "    For each timestep:",
                "        a ← μ(s) + noise_explore",
                "        Execute a, observe r, s′, done",
                "        Store (s, a, r, s′, done) in D",
                "        ",
                "        Sample random mini-batch from D",
                "        y ← r + γ Q′(s′, μ′(s′))   (0 if done)",
                "        ",
                "        // Update critic (minimize TD error)",
                "        L = (1/N) Σ (Q(s,a) − y)²",
                "        Gradient step on L w.r.t. critic params",
                "        ",
                "        // Update actor (deterministic policy gradient)",
                "        ∇J ≈ (1/N) Σ ∇_a Q(s,a) · ∇_θ μ(s)",
                "        Gradient step on J w.r.t. actor params",
                "        ",
                "        // Soft update targets",
                "        θ′_Q ← τ θ_Q + (1−τ) θ′_Q",
                "        θ′_μ ← τ θ_μ + (1−τ) θ′_μ",
                "        ",
                "        s ← s′",
            ])

            Text(
                "Both actor and critic are updated every timestep using mini-batches from the replay buffer. Target networks are updated softly each step."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }

    private var targetUpdatesSection: some View {
        ExploreSectionCard(title: "Soft vs Hard Target Updates") {
            Text(
                "DDPG uses soft (Polyak) target updates rather than the periodic hard copies used in the original DQN. This provides smoother target evolution."
            )
            .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Hard Update (original DQN)").fontWeight(.medium)
                EquationBlock(text: "θ′ ← θ  (every C steps)")
                BulletList(items: [
                    "Target jumps to match online network all at once",
                    "Can cause instability if C is too small",
                ])
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Soft Update (DDPG)").fontWeight(.medium)
                EquationBlock(text: "θ′ ← τ θ + (1−τ) θ′  (every step)")
                BulletList(items: [
                    "τ is typically very small (e.g., 0.005)",
                    "Target slowly tracks online network",
                    "More stable, avoids abrupt changes",
                ])
            }
            .padding(.top, 4)

            Text(
                "Soft updates have become the standard for most actor-critic methods (DDPG, TD3, SAC). They're simpler and often more stable than tuning a hard-update frequency."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }

    private var comparisonSection: some View {
        ExploreComparisonCard(
            title: "DQN vs DDPG",
            leftTitle: "DQN",
            rightTitle: "DDPG",
            rows: [
                ExploreComparison(
                    aspect: "Action space",
                    left: "Discrete only",
                    right: "Continuous (vector)"
                ),
                ExploreComparison(
                    aspect: "Policy",
                    left: "Implicit (argmax over Q)",
                    right: "Explicit (actor network μ)"
                ),
                ExploreComparison(
                    aspect: "Architecture",
                    left: "Single Q-network",
                    right: "Actor + Critic (two networks)"
                ),
                ExploreComparison(
                    aspect: "Action selection",
                    left: "argmax over discrete actions",
                    right: "Forward pass through actor"
                ),
                ExploreComparison(
                    aspect: "Exploration",
                    left: "ε-greedy (random actions)",
                    right: "Noise injection (Gaussian / OU)"
                ),
                ExploreComparison(
                    aspect: "Target update",
                    left: "Hard copy every C steps",
                    right: "Soft update every step (τ ≪ 1)"
                ),
                ExploreComparison(
                    aspect: "Stability",
                    left: "Relatively stable with tuning",
                    right: "More brittle, sensitive to hyperparams"
                ),
            ],
            footer:
                "DDPG is essentially DQN adapted for continuous control: replace argmax with an actor, and add noise instead of ε-greedy."
        )
    }

    private var whenToUseSection: some View {
        ExploreSectionCard(title: "When to Use DDPG") {
            BulletList(items: [
                "Continuous action spaces (robotics, autonomous driving)",
                "When a deterministic policy is desired at inference time",
                "Off-policy learning: data from any policy can be reused",
                "Tasks where action noise provides sufficient exploration",
                "As a baseline before trying TD3 or SAC",
            ])
        }
    }

    private var limitationsSection: some View {
        ExploreSectionCard(title: "Limitations") {
            BulletList(items: [
                "Brittle: small hyperparameter changes can cause divergence",
                "Overestimation bias: Q-values tend to drift upward over time",
                "Hyperparameter sensitive: learning rate, τ, noise, architecture all interact",
                "Deterministic policy cannot represent multi-modal optimal behavior",
                "Exploration relies on external noise, not built into the objective",
                "Can struggle in highly stochastic environments",
            ])
        }
    }

    private var td3ConnectionSection: some View {
        ExploreSectionCard(title: "Connection: TD3 Improves DDPG") {
            Text(
                "Twin Delayed DDPG (TD3) addresses DDPG's main weaknesses with three targeted fixes, making it significantly more stable while retaining the same actor-critic structure."
            )
            .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("The three fixes:").fontWeight(.medium)
                BulletList(items: [
                    "Clipped Double Q-Learning: two critics, take the minimum target value to reduce overestimation",
                    "Delayed Policy Updates: update the actor less often than the critics (e.g., every 2 critic updates)",
                    "Target Policy Smoothing: add noise to target actions to prevent exploiting sharp Q-value peaks",
                ])
            }

            Text(
                "These changes are small in code but large in impact; TD3 is often the preferred baseline over DDPG for continuous control benchmarks."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }
}
