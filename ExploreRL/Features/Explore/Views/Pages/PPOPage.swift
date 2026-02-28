import SwiftUI

struct PPOPage: View {
    var body: some View {
        ExploreDocPage(title: "PPO") {
            introSection
            whySection
            objectiveSection
            algorithmSection
            parametersSection
            comparisonSection
            whenToUseSection
        }
    }
}

extension PPOPage {
    private var introSection: some View {
        Text("Proximal Policy Optimization (PPO) is an on-policy actor-critic algorithm that improves policy gradient stability using a clipped objective. It is a strong general-purpose baseline for both discrete and continuous control.")
            .foregroundStyle(.secondary)
    }

    private var whySection: some View {
        ExploreSectionCard(title: "Why PPO?") {
            BulletList(items: [
                "Policy gradients can be unstable with large updates",
                "PPO clips policy ratio changes to keep updates conservative",
                "Works well across many environments with minimal tuning",
                "Simple to implement compared with trust-region methods"
            ])
        }
    }

    private var objectiveSection: some View {
        ExploreSectionCard(title: "Clipped Objective") {
            Text("PPO optimizes a clipped surrogate objective:")
                .foregroundStyle(.secondary)

            EquationBlock(text: "L^CLIP = E[min(r_t(θ)A_t, clip(r_t(θ), 1-ε, 1+ε)A_t)]")

            BulletList(items: [
                "r_t(θ) = π_θ(a_t|s_t) / π_θold(a_t|s_t)",
                "A_t is the estimated advantage (often GAE)",
                "ε is the clip range (commonly 0.1 to 0.3)"
            ])
        }
    }

    private var algorithmSection: some View {
        ExploreSectionCard(title: "Algorithm Walkthrough") {
            CodeBlock([
                "Initialize policy and value networks",
                "",
                "Repeat:",
                "    Collect rollout with current policy for n_steps",
                "    Compute advantages and returns (GAE)",
                "    For n_epochs:",
                "        Shuffle rollout into minibatches",
                "        Optimize clipped policy loss",
                "        Optimize value loss",
                "        Add entropy bonus",
                "    Update old policy reference"
            ])
        }
    }

    private var parametersSection: some View {
        ExploreParametersCard(
            title: "Key Hyperparameters",
            parameters: [
                ExploreParameter(
                    name: "n_steps",
                    typical: "32 to 2048",
                    description: "Rollout length before each update."
                ),
                ExploreParameter(
                    name: "batch_size",
                    typical: "64 to 256",
                    description: "Minibatch size for each optimization epoch."
                ),
                ExploreParameter(
                    name: "n_epochs",
                    typical: "4 to 20",
                    description: "Optimization epochs per rollout."
                ),
                ExploreParameter(
                    name: "learning_rate",
                    typical: "1e-4 to 1e-3",
                    description: "Policy/value optimizer step size."
                ),
                ExploreParameter(
                    name: "clip_range",
                    typical: "0.1 to 0.2",
                    description: "Policy ratio clipping threshold."
                ),
                ExploreParameter(
                    name: "gae_lambda",
                    typical: "0.9 to 0.98",
                    description: "Bias/variance tradeoff in advantage estimates."
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
                    left: "Lower",
                    right: "Higher with replay buffers"
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

    private var whenToUseSection: some View {
        ExploreSectionCard(title: "When to Use PPO") {
            BulletList(items: [
                "You want a reliable baseline across many tasks",
                "You need one algorithm for both discrete and continuous actions",
                "You prefer robust defaults over maximum sample efficiency",
                "You are starting experimentation before deeper algorithm tuning"
            ])
        }
    }
}
