import SwiftUI

struct MonteCarloPage: View {
    var relatedItems: [ExploreItem] = []
    var body: some View {
        ExploreDocPage(title: "Monte Carlo", relatedItems: relatedItems) {
            introSection
            firstVisitEveryVisitSection
            mcPredictionSection
            mcControlSection
            updateRuleSection
            algorithmSection
            vsTDSection
            whenToUseSection
            limitationsSection
        }
    }
}

extension MonteCarloPage {
    private var introSection: some View {
        Text(
            "Monte Carlo (MC) methods learn value functions and optimal policies from complete episodes of experience. Unlike Temporal Difference (TD) methods, MC waits until the end of an episode before updating estimates; it does not bootstrap."
        )
        .foregroundStyle(.secondary)
    }

    private var firstVisitEveryVisitSection: some View {
        ExploreSectionCard(title: "First-Visit vs Every-Visit MC") {
            Text(
                "When a state appears multiple times in an episode, there are two ways to compute its value:"
            )
            .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("First-Visit MC:").fontWeight(.medium)
                Text(
                    "Average returns only after the first visit to a state in each episode. This yields independent samples and is easier to analyze theoretically."
                )
                .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Every-Visit MC:").fontWeight(.medium)
                Text(
                    "Average returns after every visit to a state. Uses more data per episode, but samples from the same episode are correlated and not independent."
                )
                .foregroundStyle(.secondary)
            }

            Text(
                "Both converge to the true value function as the number of visits approaches infinity, but first-visit MC has more straightforward theoretical guarantees."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }

    private var mcPredictionSection: some View {
        ExploreSectionCard(title: "MC Prediction: Estimating V(s)") {
            Text(
                "The goal of MC prediction is to estimate the state-value function V(s) by averaging observed returns:"
            )
            .foregroundStyle(.secondary)

            EquationBlock(text: "V(s) ≈ (1/N) Σᵢ Gᵢ(s)")

            Text(
                "where Gᵢ(s) is the return (total discounted reward) following the i-th visit to state s, and N is the total number of visits."
            )
            .foregroundStyle(.secondary)
            .padding(.top, 4)

            BulletList(items: [
                "Generate episodes using current policy π",
                "For each state visit, record the return Gₜ = rₜ₊₁ + γ rₜ₊₂ + γ² rₜ₊₃ + ...",
                "Average all returns for each state to estimate V(s)",
                "No bootstrapping: uses actual sampled returns, not estimates of next states",
            ])
        }
    }

    private var mcControlSection: some View {
        ExploreSectionCard(title: "MC Control: Learning the Optimal Policy") {
            Text(
                "MC Control learns Q(s,a) (the value of taking action a in state s) and improves the policy using ε-greedy exploration:"
            )
            .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Why Q(s,a) instead of V(s)?").fontWeight(.medium)
                Text(
                    "To improve a policy, we need to compare actions. V(s) alone doesn't tell us which action is best. Q(s,a) gives per-action values, enabling policy improvement without a model of the environment."
                )
                .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Policy Improvement with ε-greedy:").fontWeight(.medium)
                CodeBlock([
                    "With probability 1−ε: a = argmax Q(s, a)",
                    "With probability ε:     a = random action",
                ])

                Text(
                    "This ensures continual exploration while exploiting learned knowledge. As ε decays, the policy approaches optimal."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            }
        }
    }

    private var updateRuleSection: some View {
        ExploreSectionCard(title: "The Update Rule") {
            Text(
                "MC methods use the complete return Gₜ, the sum of discounted rewards from time t until the episode ends:"
            )
            .foregroundStyle(.secondary)

            EquationBlock(text: "Gₜ = rₜ₊₁ + γ rₜ₊₂ + γ² rₜ₊₃ + ... + γᵀ⁻ᵗ⁻¹ rₜ₊ᵀ")

            Text("The Q-value is updated by incrementally averaging observed returns:")
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            EquationBlock(text: "Q(s,a) ← Q(s,a) + (1/N) (Gₜ − Q(s,a))")

            VStack(alignment: .leading, spacing: 8) {
                Text("Components:").fontWeight(.medium)
                BulletList(items: [
                    "Q(s,a): current estimate for taking action a in state s",
                    "Gₜ: actual return observed from time t to episode end",
                    "N: number of times (s,a) has been visited",
                    "(1/N): implicit step size that decreases with more visits",
                    "Gₜ − Q(s,a): error between observed and estimated value",
                ])
            }
        }
    }

    private var algorithmSection: some View {
        ExploreSectionCard(title: "Algorithm Walkthrough") {
            Text("Monte Carlo Control with Exploring Starts (or ε-greedy):")
                .foregroundStyle(.secondary)

            CodeBlock([
                "Initialize:",
                "    Q(s,a) ← arbitrary for all s, a",
                "    Returns(s,a) ← empty list",
                "    π ← arbitrary policy",
                "",
                "Repeat for each episode:",
                "    Generate episode: S₀, A₀, R₁, ..., Sₜ₋₁, Aₜ₋₁, Rₜ",
                "        following policy π (with ε-greedy exploration)",
                "    G ← 0",
                "",
                "    For each step t = T−1, T−2, ..., 0:",
                "        G ← γ G + Rₜ₊₁",
                "        If (Sₜ, Aₜ) is a first visit:",
                "            Append G to Returns(Sₜ, Aₜ)",
                "            Q(Sₜ, Aₜ) ← average(Returns(Sₜ, Aₜ))",
                "            π(Sₜ) ← ε-greedy based on Q(Sₜ, ·)",
                "",
                "    Decay ε over time",
            ])

            Text(
                "Notice: returns are processed backwards, from episode end to start, computing G incrementally."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }

    private var vsTDSection: some View {
        ExploreComparisonCard(
            title: "Monte Carlo vs Temporal Difference",
            leftTitle: "Monte Carlo",
            rightTitle: "TD Learning",
            rows: [
                ExploreComparison(
                    aspect: "Update timing",
                    left: "Waits for episode to finish",
                    right: "Updates every step (online)"
                ),
                ExploreComparison(
                    aspect: "Target",
                    left: "Gₜ (complete return)",
                    right: "r + γ V(s′) (bootstrapped)"
                ),
                ExploreComparison(
                    aspect: "Variance",
                    left: "High (full trajectory noise)",
                    right: "Low (single-step noise)"
                ),
                ExploreComparison(
                    aspect: "Bias",
                    left: "Unbiased (uses actual returns)",
                    right: "Biased (relies on estimate of V)"
                ),
                ExploreComparison(
                    aspect: "Episode requirement",
                    left: "Episodic only",
                    right: "Works on continuing tasks too"
                ),
                ExploreComparison(
                    aspect: "Online learning",
                    left: "No (must wait for episode end)",
                    right: "Yes (learns every step)"
                ),
                ExploreComparison(
                    aspect: "Sample efficiency",
                    left: "Uses all rewards in episode",
                    right: "Throws away future rewards"
                ),
            ],
            footer:
                "MC is unbiased but high-variance; TD is biased but low-variance. This is the classic bias-variance tradeoff. In practice, TD methods like SARSA and Q-Learning are often preferred because they learn online and have lower variance, but MC's unbiasedness is valuable when accurate value estimates matter."
        )
    }

    private var whenToUseSection: some View {
        ExploreSectionCard(title: "When to Use Monte Carlo") {
            BulletList(items: [
                "Episodic tasks with clear termination (games, trials, simulations)",
                "When the environment model is unknown (model-free)",
                "When unbiased value estimates are important",
                "Episodes are short enough that waiting is acceptable",
                "Non-stationary environments where full-episode credit assignment helps",
                "When you want to learn from actual outcomes, not guessed estimates",
            ])
        }
    }

    private var limitationsSection: some View {
        ExploreSectionCard(title: "Limitations") {
            BulletList(items: [
                "Episodic only; cannot handle continuing (non-terminating) tasks",
                "High variance; full trajectory noise accumulates in the return",
                "Cannot learn online; must wait for each episode to finish",
                "Slow updates; one update per episode per visited state",
                "Exploration must be managed carefully (exploring starts or ε-greedy)",
                "Inefficient with long episodes; variance grows with episode length",
            ])
        }
    }
}
