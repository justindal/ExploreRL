import SwiftUI

struct PolicyGradientPage: View {
    var relatedItems: [ExploreItem] = []
    var body: some View {
        ExploreDocPage(title: "Policy Gradient", relatedItems: relatedItems) {
            introSection
            theoremSection
            reinforceSection
            algorithmSection
            advantageSection
            comparisonSection
            whenToUseSection
            limitationsSection
            connectionSection
        }
    }
}

extension PolicyGradientPage {
    private var introSection: some View {
        Text(
            "Policy gradient methods optimize the policy directly, rather than learning a value function and deriving a policy from it. By parameterizing the policy and following the gradient of expected return, these methods can learn stochastic policies and handle continuous action spaces naturally."
        )
        .foregroundStyle(.secondary)
    }

    private var theoremSection: some View {
        ExploreSectionCard(title: "The Policy Gradient Theorem") {
            Text(
                "The policy gradient theorem provides the foundation: the gradient of the expected return with respect to the policy parameters can be expressed as an expectation over trajectories."
            )
            .foregroundStyle(.secondary)

            EquationBlock(text: "∇J(θ) = E_π [ ∇log π_θ(a|s) · Gₜ ]")

            VStack(alignment: .leading, spacing: 8) {
                Text("Where:").fontWeight(.medium)
                BulletList(items: [
                    "J(θ): expected return under policy π_θ",
                    "∇log π_θ(a|s): score function; direction that increases probability of action a",
                    "Gₜ: return (total discounted reward) from time step t",
                    "The update increases log-probability of actions that led to high returns",
                ])
            }
        }
    }

    private var reinforceSection: some View {
        ExploreSectionCard(title: "REINFORCE Algorithm") {
            Text(
                "REINFORCE is the simplest policy gradient method. It samples complete trajectories, computes the return Gₜ for each time step, and updates the policy to increase the log-probability of actions proportional to their return."
            )
            .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Core idea:").fontWeight(.medium)
                BulletList(items: [
                    "Run a full episode using the current policy π_θ",
                    "For each step, compute the discounted return Gₜ",
                    "Update θ using: θ ← θ + α · ∇log π_θ(aₜ|sₜ) · Gₜ",
                    "Good actions (high Gₜ) are reinforced; bad actions are suppressed",
                    "Uses Monte Carlo returns; must wait until episode ends",
                ])
            }
        }
    }

    private var algorithmSection: some View {
        ExploreSectionCard(title: "REINFORCE Walkthrough") {
            Text("The complete REINFORCE algorithm in pseudocode:")
                .foregroundStyle(.secondary)

            CodeBlock([
                "Initialize policy parameters θ (e.g., neural network weights)",
                "",
                "Repeat for each episode:",
                "    states, actions, rewards = []",
                "    ",
                "    // Collect trajectory",
                "    s ← initial state",
                "    While not done:",
                "        Sample a ~ π_θ(·|s)",
                "        Execute a, observe r, s′, done",
                "        Append (s, a, r) to trajectory",
                "        s ← s′",
                "    ",
                "    // Compute returns (discounted)",
                "    G ← 0",
                "    For t = T down to 1:",
                "        G ← rₜ + γ · G",
                "        Accumulate loss: −log π_θ(aₜ|sₜ) · G",
                "    ",
                "    // Update policy",
                "    θ ← θ + α · ∇θ J(θ)   // gradient ascent",
            ])
        }
    }

    private var advantageSection: some View {
        ExploreSectionCard(title: "Advantage Function: Reducing Variance") {
            Text(
                "REINFORCE has high variance because returns Gₜ can vary wildly. Subtracting a baseline reduces variance without introducing bias."
            )
            .foregroundStyle(.secondary)

            EquationBlock(text: "∇J(θ) = E [ ∇log π_θ(a|s) · (Gₜ − V(s)) ]")

            VStack(alignment: .leading, spacing: 8) {
                Text("Why subtract a baseline V(s)?").fontWeight(.medium)
                BulletList(items: [
                    "V(s): expected return from state s (the \"baseline\")",
                    "A(s,a) = Gₜ − V(s): the advantage; how much better than average",
                    "Reduces variance: raw returns fluctuate; advantages are centered",
                    "Does not add bias: E[∇log π · V(s)] = 0 (baseline is action-independent)",
                    "Turns REINFORCE into a simple actor-critic method",
                ])
            }

            Text(
                "This insight leads to modern actor-critic architectures like A2C, where a critic network learns V(s) and the actor uses advantages A(s,a) for lower-variance updates."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }

    private var comparisonSection: some View {
        ExploreComparisonCard(
            title: "REINFORCE vs Q-Learning",
            leftTitle: "Q-Learning",
            rightTitle: "REINFORCE",
            rows: [
                ExploreComparison(
                    aspect: "What is learned",
                    left: "Value function Q(s,a)",
                    right: "Policy π_θ(a|s) directly"
                ),
                ExploreComparison(
                    aspect: "Action space",
                    left: "Discrete only",
                    right: "Discrete or continuous"
                ),
                ExploreComparison(
                    aspect: "Policy type",
                    left: "Implicit (derived from Q-values)",
                    right: "Explicit (parameterized policy)"
                ),
                ExploreComparison(
                    aspect: "Action selection",
                    left: "Deterministic (argmax Q, or ε-greedy)",
                    right: "Stochastic (sampled from π)"
                ),
                ExploreComparison(
                    aspect: "Update timing",
                    left: "Per time step (TD learning)",
                    right: "Per episode (Monte Carlo)"
                ),
                ExploreComparison(
                    aspect: "Exploration",
                    left: "ε-greedy (external to learning)",
                    right: "Built-in (stochastic policy)"
                ),
            ]
        )
    }

    private var whenToUseSection: some View {
        ExploreSectionCard(title: "When to Use Policy Gradients") {
            BulletList(items: [
                "Continuous action spaces: joint torques, throttle, steering angles",
                "Stochastic policies are needed: games with bluffing, exploration in RL",
                "The optimal policy is inherently probabilistic (not deterministic)",
                "You want to learn directly from raw states to actions (end-to-end)",
                "Environments where value-based methods struggle (large/continuous actions)",
            ])
        }
    }

    private var limitationsSection: some View {
        ExploreSectionCard(title: "Limitations") {
            BulletList(items: [
                "High variance: Monte Carlo returns vary significantly between episodes",
                "Sample inefficient: each episode yields only one gradient update",
                "On-policy only: data must come from the current policy; no replay buffer",
                "Slow convergence: gradient estimates are noisy, requiring many episodes",
                "Credit assignment is coarse: entire trajectory graded by final return",
                "For maximum sample efficiency, consider PPO or off-policy methods like SAC",
            ])
        }
    }

    private var connectionSection: some View {
        ExploreSectionCard(title: "Modern Policy Gradient Variants") {
            Text(
                "REINFORCE is the foundation. Modern algorithms address its limitations while preserving the core idea of direct policy optimization:"
            )
            .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Key descendants:").fontWeight(.medium)
                BulletList(items: [
                    "A2C / A3C: add a critic baseline V(s) for lower variance; use n-step returns instead of full Monte Carlo",
                    "PPO: clips policy updates to prevent destructive large steps; adds value loss and entropy bonus for stability",
                    "TRPO: constrains policy updates with a trust region (KL divergence bound) for guaranteed improvement",
                    "SAC: combines policy gradients with Q-learning in an off-policy, maximum-entropy framework",
                ])
            }

            Text(
                "All of these trace back to the policy gradient theorem. Understanding REINFORCE gives you the intuition for why and how these more advanced algorithms work."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }
}
