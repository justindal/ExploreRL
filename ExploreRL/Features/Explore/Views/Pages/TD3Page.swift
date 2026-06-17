import SwiftUI

struct TD3Page: View {
    var relatedItems: [ExploreItem] = []
    var body: some View {
        ExploreDocPage(title: "TD3", relatedItems: relatedItems) {
            introSection
            ddpgBackgroundSection
            whySection
            coreIdeasSection
            algorithmSection
            parametersSection
            comparisonSection
            vsDDPGSection
            whenToUseSection
            limitationsSection
        }
    }
}

extension TD3Page {
    private var introSection: some View {
        Text(
            "Twin Delayed Deep Deterministic Policy Gradient (TD3) is an off-policy actor-critic algorithm for continuous control. It improves DDPG stability by reducing Q-value overestimation and slowing policy updates."
        )
        .foregroundStyle(.secondary)
    }

    private var ddpgBackgroundSection: some View {
        ExploreSectionCard(title: "DDPG Background") {
            Text(
                "TD3 builds on Deep Deterministic Policy Gradient (DDPG), which extends DQN to continuous actions. DDPG uses an actor-critic architecture with a deterministic policy and experience replay."
            )
            .foregroundStyle(.secondary)
            BulletList(items: [
                "Actor: maps state → continuous action (deterministic)",
                "Critic: maps (state, action) → Q-value",
                "Exploration via adding noise (Gaussian) to actions",
                "Uses target networks and replay buffer like DQN",
            ])
            Text(
                "DDPG works but is brittle: Q-values tend to overestimate, and the policy can exploit these errors, causing divergence. TD3 adds three fixes to address this."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }

    private var whySection: some View {
        ExploreSectionCard(title: "Why TD3?") {
            BulletList(items: [
                "DDPG can overestimate Q-values and become unstable",
                "TD3 uses two critics and takes the minimum target value",
                "Actor updates are delayed to let critics improve first",
                "Target policy smoothing reduces exploitative value spikes",
            ])
        }
    }

    private var coreIdeasSection: some View {
        ExploreSectionCard(title: "The Three Fixes (in Detail)") {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("1. Clipped Double Q-Learning")
                        .fontWeight(.medium)
                    Text(
                        "Two critics Q₁ and Q₂ are trained independently. The target uses the minimum of the two, providing a pessimistic estimate that counteracts overestimation."
                    )
                    .foregroundStyle(.secondary)
                    EquationBlock(text: "y = r + γ min(Q₁′(s′, a′), Q₂′(s′, a′))")
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("2. Delayed Policy Updates")
                        .fontWeight(.medium)
                    Text(
                        "Update the actor (and target networks) less frequently than the critics. This gives the critics time to stabilize before the policy exploits them. Typical policy delay: 2 (one actor update per 2 critic updates)."
                    )
                    .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("3. Target Policy Smoothing")
                        .fontWeight(.medium)
                    Text(
                        "Add small random noise to the target action and clip it. This smooths the Q-value landscape and prevents the policy from exploiting sharp peaks in the value estimate."
                    )
                    .foregroundStyle(.secondary)
                    EquationBlock(text: "a′ = clip( π′(s′) + clip(ε, −c, c), a_min, a_max )")
                    BulletList(items: [
                        "ε ~ N(0, σ): Gaussian noise (σ ≈ 0.2)",
                        "c: noise clip range (typically 0.5)",
                    ])
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
                "    a = π(s) + ε_explore   // add exploration noise",
                "    Execute a, observe r, s′, done",
                "    Store (s, a, r, s′, done) in D",
                "    ",
                "    Sample batch from D",
                "    ",
                "    // Target actions with smoothing",
                "    a′ = π′(s′) + clip(ε, −c, c)",
                "    a′ = clip(a′, a_min, a_max)",
                "    y = r + γ min(Q₁′(s′,a′), Q₂′(s′,a′))",
                "    ",
                "    // Update critics",
                "    L = (Q₁(s,a) − y)² + (Q₂(s,a) − y)²",
                "    Gradient step on L",
                "    ",
                "    // Delayed updates",
                "    If step % policy_delay == 0:",
                "        Update actor π via deterministic policy gradient",
                "        Soft update targets: θ′ ← τθ + (1−τ)θ′",
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
                    name: "Target Policy Noise (σ)",
                    typical: "0.2",
                    description: "Std dev of Gaussian noise added to target actions."
                ),
                ExploreParameter(
                    name: "Target Noise Clip (c)",
                    typical: "0.5",
                    description: "Clamp range for target smoothing noise."
                ),
                ExploreParameter(
                    name: "τ (Soft Update)",
                    typical: "0.005",
                    description: "Target network update coefficient."
                ),
                ExploreParameter(
                    name: "Exploration Noise",
                    typical: "Gaussian (σ ≈ 0.1)",
                    description: "Noise added to actions during data collection."
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
                    left: "External action noise (Gaussian)",
                    right: "Entropy-regularized objective"
                ),
                ExploreComparison(
                    aspect: "Complexity",
                    left: "Lower (4 networks)",
                    right: "Higher (5+ networks, entropy tuning)"
                ),
                ExploreComparison(
                    aspect: "Common use",
                    left: "Strong baseline for continuous control",
                    right: "Robust for exploration-heavy tasks"
                ),
            ]
        )
    }

    private var vsDDPGSection: some View {
        ExploreComparisonCard(
            title: "TD3 vs DDPG",
            leftTitle: "DDPG",
            rightTitle: "TD3",
            rows: [
                ExploreComparison(
                    aspect: "Critics",
                    left: "Single Q-network",
                    right: "Twin Q-networks (min of two)"
                ),
                ExploreComparison(
                    aspect: "Overestimation",
                    left: "Prone to overestimation",
                    right: "Reduced via clipped double Q"
                ),
                ExploreComparison(
                    aspect: "Policy updates",
                    left: "Every timestep",
                    right: "Delayed (every d steps)"
                ),
                ExploreComparison(
                    aspect: "Target actions",
                    left: "Direct from target actor",
                    right: "Smoothed with clipped noise"
                ),
                ExploreComparison(
                    aspect: "Stability",
                    left: "Often brittle",
                    right: "Significantly more stable"
                ),
            ]
        )
    }

    private var whenToUseSection: some View {
        ExploreSectionCard(title: "When to Use TD3") {
            BulletList(items: [
                "Continuous action tasks with smooth control dynamics",
                "When you want a deterministic policy at inference time",
                "As a stable baseline before testing SAC variants",
            ])
        }
    }

    private var limitationsSection: some View {
        ExploreSectionCard(title: "Limitations") {
            BulletList(items: [
                "Deterministic policy: cannot represent multi-modal optimal behaviors",
                "Exploration relies on external noise, not built into the objective",
                "Less effective in highly stochastic environments",
                "Continuous actions only; no discrete variant",
                "For stochastic policies and better exploration, consider SAC",
                "Policy delay can slow convergence in simple tasks",
            ])
        }
    }
}
