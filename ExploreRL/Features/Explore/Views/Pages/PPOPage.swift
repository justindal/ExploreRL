import SwiftUI

struct PPOPage: View {
    var relatedItems: [ExploreItem] = []
    var body: some View {
        ExploreDocPage(title: "PPO", relatedItems: relatedItems) {
            introSection
            whySection
            gaeSection
            objectiveSection
            combinedLossSection
            algorithmSection
            parametersSection
            comparisonSection
            vsTabularSection
            whenToUseSection
            limitationsSection
        }
    }
}

extension PPOPage {
    private var introSection: some View {
        Text(
            "Proximal Policy Optimization (PPO) is an on-policy actor-critic algorithm that improves policy gradient stability using a clipped objective. It is a strong general-purpose baseline for both discrete and continuous control."
        )
        .foregroundStyle(.secondary)
    }

    private var whySection: some View {
        ExploreSectionCard(title: "Why PPO?") {
            BulletList(items: [
                "Policy gradients can be unstable with large updates",
                "PPO clips policy ratio changes to keep updates conservative",
                "Works well across many environments with minimal tuning",
                "Simple to implement compared with trust-region methods",
            ])
        }
    }

    private var gaeSection: some View {
        ExploreSectionCard(title: "Generalized Advantage Estimation (GAE)") {
            Text(
                "PPO typically uses GAE to compute advantages. GAE is an exponentially weighted average of n-step advantage estimates, controlled by λ:"
            )
            .foregroundStyle(.secondary)
            EquationBlock(text: "Aₜ^GAE = Σₗ (γλ)ˡ δₜ₊ₗ")
            VStack(alignment: .leading, spacing: 8) {
                Text("Where:").fontWeight(.medium)
                BulletList(items: [
                    "δₜ = rₜ₊₁ + γ V(sₜ₊₁) − V(sₜ) is the TD error",
                    "λ = 0: Aₜ = δₜ (one-step TD, low variance, high bias)",
                    "λ = 1: Aₜ = Gₜ − V(sₜ) (Monte Carlo, high variance, low bias)",
                    "Typical λ: 0.95 – 0.98, balancing bias and variance",
                ])
            }
        }
    }

    private var objectiveSection: some View {
        ExploreSectionCard(title: "Clipped Policy Objective") {
            Text("PPO optimizes a clipped surrogate objective to prevent destructive updates:")
                .foregroundStyle(.secondary)

            EquationBlock(text: "L^CLIP = E[min(rₜ(θ)·Aₜ, clip(rₜ(θ), 1−ε, 1+ε)·Aₜ)]")

            BulletList(items: [
                "rₜ(θ) = π_θ(aₜ|sₜ) / π_θold(aₜ|sₜ); probability ratio",
                "Aₜ: advantage estimate (typically GAE)",
                "ε: clip range (commonly 0.1 to 0.2)",
                "If ratio goes outside [1−ε, 1+ε], the gradient is clipped to zero",
                "This prevents the new policy from moving too far from the old one",
            ])
        }
    }

    private var combinedLossSection: some View {
        ExploreSectionCard(title: "Combined Loss") {
            Text("The full PPO loss combines policy loss, value loss, and an entropy bonus:")
                .foregroundStyle(.secondary)

            EquationBlock(text: "L = L^CLIP − c₁ L^VF + c₂ S[π_θ]")

            VStack(alignment: .leading, spacing: 8) {
                Text("Components:").fontWeight(.medium)
                BulletList(items: [
                    "L^CLIP: clipped policy loss (maximize expected advantage)",
                    "L^VF = (V_θ(s) − V_target)²: value function loss",
                    "S[π_θ]: entropy bonus (encourages exploration)",
                    "c₁, c₂: coefficients (often c₁=0.5, c₂=0.01)",
                ])
            }
        }
    }

    private var algorithmSection: some View {
        ExploreSectionCard(title: "Algorithm Walkthrough") {
            CodeBlock([
                "Initialize policy π and value network V",
                "",
                "Repeat:",
                "    Collect rollout with current policy for n_steps",
                "    Compute advantages Aₜ using GAE",
                "    Compute returns: Rₜ = Aₜ + V(sₜ)",
                "    For n_epochs:",
                "        Shuffle rollout into minibatches",
                "        Compute probability ratio rₜ(θ)",
                "        Compute clipped policy loss",
                "        Compute value loss (MSE to returns)",
                "        Total loss = policy_loss + c₁·value_loss − c₂·entropy",
                "        Backpropagate and update θ",
                "    Update old policy reference θ_old ← θ",
            ])
        }
    }

    private var parametersSection: some View {
        ExploreParametersCard(
            title: "Key Hyperparameters",
            parameters: [
                ExploreParameter(
                    name: "n_steps",
                    typical: "128 to 2048",
                    description:
                        "Rollout length before each update. Larger = more stable but less frequent updates."
                ),
                ExploreParameter(
                    name: "batch_size",
                    typical: "64 to 256",
                    description: "Minibatch size for each optimization epoch."
                ),
                ExploreParameter(
                    name: "n_epochs",
                    typical: "4 to 10",
                    description:
                        "Optimization epochs per rollout. More epochs = more data reuse but risk of overfitting."
                ),
                ExploreParameter(
                    name: "learning_rate",
                    typical: "1e-4 to 3e-4",
                    description: "Policy/value optimizer step size. Adam is standard."
                ),
                ExploreParameter(
                    name: "clip_range",
                    typical: "0.1 to 0.2",
                    description:
                        "Policy ratio clipping threshold. Lower = more conservative updates."
                ),
                ExploreParameter(
                    name: "gae_lambda",
                    typical: "0.95 to 0.98",
                    description: "Bias/variance tradeoff in GAE advantage estimates."
                ),
                ExploreParameter(
                    name: "γ (Discount)",
                    typical: "0.99",
                    description: "Future reward discount factor."
                ),
            ]
        )
    }

    private var comparisonSection: some View {
        ExploreComparisonCard(
            title: "PPO vs TD3/SAC",
            leftTitle: "PPO",
            rightTitle: "TD3 / SAC",
            rows: [
                ExploreComparison(
                    aspect: "Learning style",
                    left: "On-policy",
                    right: "Off-policy"
                ),
                ExploreComparison(
                    aspect: "Sample efficiency",
                    left: "Lower (discards data after update)",
                    right: "Higher (reuses data via replay buffer)"
                ),
                ExploreComparison(
                    aspect: "Stability",
                    left: "Strong default stability",
                    right: "Can be more sensitive"
                ),
                ExploreComparison(
                    aspect: "Action spaces",
                    left: "Discrete and continuous",
                    right: "Primarily continuous"
                ),
            ]
        )
    }

    private var vsTabularSection: some View {
        ExploreComparisonCard(
            title: "PPO vs Tabular Q-Learning",
            leftTitle: "Tabular Q-Learning",
            rightTitle: "PPO",
            rows: [
                ExploreComparison(
                    aspect: "Value storage",
                    left: "Q-table",
                    right: "Neural network (actor + critic)"
                ),
                ExploreComparison(
                    aspect: "Policy type",
                    left: "Implicit (from Q-values)",
                    right: "Explicit (actor outputs distribution)"
                ),
                ExploreComparison(
                    aspect: "State space",
                    left: "Small, discrete",
                    right: "Large, continuous"
                ),
                ExploreComparison(
                    aspect: "Action space",
                    left: "Discrete",
                    right: "Discrete or continuous"
                ),
                ExploreComparison(
                    aspect: "Updates",
                    left: "Per timestep",
                    right: "Batch after rollout"
                ),
            ]
        )
    }

    private var whenToUseSection: some View {
        ExploreSectionCard(title: "When to Use PPO") {
            BulletList(items: [
                "You want a reliable baseline across many tasks",
                "You need one algorithm for both discrete and continuous actions",
                "You prefer robust defaults over maximum sample efficiency",
                "You are starting experimentation before deeper algorithm tuning",
            ])
        }
    }

    private var limitationsSection: some View {
        ExploreSectionCard(title: "Limitations") {
            BulletList(items: [
                "Sample inefficient: on-policy means data is used once then discarded",
                "Requires many environment interactions for good performance",
                "Less suitable when environment steps are expensive (real-world robots)",
                "Rollout length and batch size must be tuned per environment",
                "May converge to suboptimal policies in highly stochastic environments",
                "For maximum sample efficiency, consider SAC or TD3 instead",
            ])
        }
    }
}
