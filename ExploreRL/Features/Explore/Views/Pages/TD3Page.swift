import SwiftUI

struct TD3Page: View {
    var body: some View {
        ExploreDocPage(title: "TD3") {
            introSection
            whySection
            coreIdeasSection
            algorithmSection
            parametersSection
            comparisonSection
            whenToUseSection
        }
    }
}

extension TD3Page {
    private var introSection: some View {
        Text("Twin Delayed Deep Deterministic Policy Gradient (TD3) is an off-policy actor-critic algorithm for continuous control. It improves DDPG stability by reducing Q-value overestimation and slowing policy updates.")
            .foregroundStyle(.secondary)
    }

    private var whySection: some View {
        ExploreSectionCard(title: "Why TD3?") {
            BulletList(items: [
                "DDPG can overestimate Q-values and become unstable",
                "TD3 uses two critics and takes the minimum target value",
                "Actor updates are delayed to let critics improve first",
                "Target policy smoothing reduces exploitative value spikes"
            ])
        }
    }

    private var coreIdeasSection: some View {
        ExploreSectionCard(title: "Core Ideas") {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Clipped Double Q-learning")
                        .fontWeight(.medium)
                    EquationBlock(text: "y = r + γ min(Q₁′(s′, a′), Q₂′(s′, a′))")
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Delayed Policy Updates")
                        .fontWeight(.medium)
                    Text("Update critics every step, update actor every `policyDelay` steps.")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Target Policy Smoothing")
                        .fontWeight(.medium)
                    EquationBlock(text: "a′ = clip(π′(s′) + clip(ε, -c, c), a_min, a_max)")
                }
            }
        }
    }

    private var algorithmSection: some View {
        ExploreSectionCard(title: "Algorithm Walkthrough") {
            CodeBlock([
                "Initialize actor π, critics Q₁/Q₂, and target networks",
                "Initialize replay buffer D",
                "",
                "For each timestep:",
                "    Choose action from actor + exploration noise",
                "    Step env and store transition in D",
                "    Sample batch from D",
                "    Compute target with clipped target noise",
                "    Update both critics on TD target",
                "    Every policyDelay steps:",
                "        Update actor using critic Q₁",
                "        Soft update actor and critic targets with τ"
            ])
        }
    }

    private var parametersSection: some View {
        ExploreParametersCard(
            title: "Key Hyperparameters",
            parameters: [
                ExploreParameter(
                    name: "Learning Rate",
                    typical: "1e-3",
                    description: "Optimizer step size for actor and critics."
                ),
                ExploreParameter(
                    name: "Policy Delay",
                    typical: "2",
                    description: "Number of critic updates per actor update."
                ),
                ExploreParameter(
                    name: "Target Policy Noise",
                    typical: "0.2",
                    description: "Noise scale used in target action smoothing."
                ),
                ExploreParameter(
                    name: "Target Noise Clip",
                    typical: "0.5",
                    description: "Clamp range for target smoothing noise."
                ),
                ExploreParameter(
                    name: "τ (Soft Update)",
                    typical: "0.005",
                    description: "Target network update coefficient."
                ),
                ExploreParameter(
                    name: "Action Noise",
                    typical: "Normal or OU",
                    description: "Exploration process for data collection."
                ),
            ]
        )
    }

    private var comparisonSection: some View {
        ExploreComparisonCard(
            title: "TD3 vs SAC",
            leftTitle: "TD3",
            rightTitle: "SAC",
            rows: [
                ExploreComparison(
                    aspect: "Policy",
                    left: "Deterministic actor",
                    right: "Stochastic actor"
                ),
                ExploreComparison(
                    aspect: "Exploration",
                    left: "External action noise",
                    right: "Entropy-regularized objective"
                ),
                ExploreComparison(
                    aspect: "Complexity",
                    left: "Lower",
                    right: "Higher (includes entropy tuning)"
                ),
                ExploreComparison(
                    aspect: "Common use",
                    left: "Strong baseline continuous control",
                    right: "Robust exploration-heavy tasks"
                ),
            ]
        )
    }

    private var whenToUseSection: some View {
        ExploreSectionCard(title: "When to Use TD3") {
            BulletList(items: [
                "Continuous action tasks with smooth control dynamics",
                "When you want a deterministic policy at inference time",
                "As a stable baseline before testing SAC variants"
            ])
        }
    }
}
