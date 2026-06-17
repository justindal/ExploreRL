import SwiftUI

struct DynamicProgrammingPage: View {
    var relatedItems: [ExploreItem] = []
    var body: some View {
        ExploreDocPage(title: "Dynamic Programming", relatedItems: relatedItems) {
            introSection
            whatIsDPSection
            policyEvaluationSection
            policyImprovementSection
            policyIterationSection
            valueIterationSection
            limitationsSection
            connectionSection
        }
    }
}

extension DynamicProgrammingPage {
    // MARK: - Intro

    private var introSection: some View {
        Text(
            "Dynamic Programming (DP) is a class of algorithms that solve reinforcement learning problems when a perfect model of the environment is available. DP forms the theoretical foundation upon which many modern RL methods are built."
        )
        .foregroundStyle(.secondary)
    }

    // MARK: - What is DP in RL?

    private var whatIsDPSection: some View {
        ExploreSectionCard(title: "What is DP in RL?") {
            Text(
                "Dynamic Programming requires a perfect model of the environment, meaning we know the state transition probabilities and reward function:"
            )
            .foregroundStyle(.secondary)

            EquationBlock(text: "P(s′|s,a): probability of reaching s′ from s after action a")
            EquationBlock(text: "R(s,a,s′): expected immediate reward for transition (s,a,s′)")

            Text(
                "With this model, DP computes optimal policies by systematically iterating over all states. It's the \"planning\" approach; the agent doesn't need to interact with the environment; it can simulate everything internally."
            )
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }

    // MARK: - Policy Evaluation

    private var policyEvaluationSection: some View {
        ExploreSectionCard(title: "Policy Evaluation") {
            Text(
                "Given a fixed policy π, policy evaluation computes the state-value function V^π(s), the expected return starting from state s and following π thereafter."
            )
            .foregroundStyle(.secondary)

            Text("Bellman Expectation Equation:")
                .fontWeight(.medium)
                .padding(.top, 4)

            EquationBlock(text: "V^π(s) = Σₐ π(a|s) Σₛ′ P(s′|s,a) [R + γ V^π(s′)]")

            Text("This is turned into an iterative update rule:")
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            EquationBlock(text: "Vₖ₊₁(s) ← Σₐ π(a|s) Σₛ′ P(s′|s,a) [R + γ Vₖ(s′)]")

            VStack(alignment: .leading, spacing: 8) {
                Text("Key points:").fontWeight(.medium)
                BulletList(items: [
                    "Sweeps through all states, updating each one",
                    "Uses the current estimates Vₖ(s′) to improve Vₖ₊₁(s)",
                    "Converges to the true V^π as k → ∞",
                    "Each full sweep is O(|S|²·|A|) in the worst case",
                ])
            }

            Text(
                "This is essentially \"bootstrapping\": using estimates of later states to update the current state. The same idea appears in TD learning, but TD uses sampled experience instead of a model."
            )
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }

    // MARK: - Policy Improvement

    private var policyImprovementSection: some View {
        ExploreSectionCard(title: "Policy Improvement") {
            Text(
                "Once we have a value function V^π for a policy π, we can improve the policy by making it greedy with respect to V^π:"
            )
            .foregroundStyle(.secondary)

            EquationBlock(text: "π′(s) = argmaxₐ Σₛ′ P(s′|s,a) [R + γ V^π(s′)]")

            Text(
                "This chooses the action that maximizes the expected return in each state, assuming we follow V^π afterwards."
            )
            .foregroundStyle(.secondary)
            .padding(.top, 4)

            Text("Policy Improvement Theorem:")
                .fontWeight(.medium)
                .padding(.top, 4)

            BulletList(items: [
                "If π′ is the greedy policy w.r.t. V^π, then V^{π′}(s) ≥ V^π(s) for all s",
                "This guarantees monotonic improvement",
                "If no improvement is possible (π′ = π), the Bellman optimality equation is satisfied and π is optimal",
            ])
        }
    }

    // MARK: - Policy Iteration

    private var policyIterationSection: some View {
        ExploreSectionCard(title: "Policy Iteration") {
            Text(
                "Policy iteration alternates between policy evaluation and policy improvement until convergence:"
            )
            .foregroundStyle(.secondary)

            CodeBlock([
                "1. Initialize π arbitrarily (e.g., random policy)",
                "2. Repeat:",
                "   a. Policy Evaluation:",
                "      Compute V^π(s) for all s (iterate until convergence)",
                "   b. Policy Improvement:",
                "      For each state s:",
                "          π_new(s) ← argmaxₐ Σₛ′ P(s′|s,a)[R + γ V^π(s′)]",
                "   c. If π_new == π:",
                "          Stop; optimal policy found",
                "      Else:",
                "          π ← π_new",
            ])

            VStack(alignment: .leading, spacing: 8) {
                Text("Properties:").fontWeight(.medium)
                BulletList(items: [
                    "Converges in a finite number of iterations (there are only |A|^|S| possible deterministic policies)",
                    "In practice, converges very quickly, often in just a handful of iterations",
                    "Each policy evaluation step can be truncated early without losing convergence",
                    "The inner evaluation loop is the computational bottleneck",
                ])
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Value Iteration

    private var valueIterationSection: some View {
        ExploreSectionCard(title: "Value Iteration") {
            Text(
                "Value iteration combines policy evaluation and improvement into a single update step using the Bellman optimality equation:"
            )
            .foregroundStyle(.secondary)

            Text("Bellman Optimality Equation:")
                .fontWeight(.medium)
                .padding(.top, 4)

            EquationBlock(text: "V*(s) = maxₐ Σₛ′ P(s′|s,a) [R + γ V*(s′)]")

            Text("Turned into an iterative update:")
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            EquationBlock(text: "Vₖ₊₁(s) ← maxₐ Σₛ′ P(s′|s,a) [R + γ Vₖ(s′)]")

            Text(
                "Instead of evaluating a fixed policy to convergence, value iteration does one sweep of evaluation followed immediately by taking the max (improvement). This is equivalent to policy iteration with a single evaluation sweep."
            )
            .foregroundStyle(.secondary)
            .padding(.top, 4)

            CodeBlock([
                "1. Initialize V(s) arbitrarily for all s",
                "2. Repeat until convergence:",
                "   Δ ← 0",
                "   For each state s:",
                "       v ← V(s)",
                "       V(s) ← maxₐ Σₛ′ P(s′|s,a)[R + γ V(s′)]",
                "       Δ ← max(Δ, |v − V(s)|)",
                "   If Δ < θ:",
                "       Stop",
                "3. Output π*(s) = argmaxₐ Σₛ′ P(s′|s,a)[R + γ V(s′)]",
            ])

            VStack(alignment: .leading, spacing: 8) {
                Text("Comparison to Policy Iteration:").fontWeight(.medium)
                BulletList(items: [
                    "Value iteration: fewer sweeps total, but each sweep updates every state",
                    "Policy iteration: fewer sweeps overall, but each evaluation sweep can be expensive",
                    "Both converge to the same optimal policy",
                    "Value iteration is often preferred when the state space is large",
                ])
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Limitations

    private var limitationsSection: some View {
        ExploreSectionCard(title: "Limitations") {
            Text("Despite its theoretical elegance, DP has significant practical limitations:")
                .foregroundStyle(.secondary)

            BulletList(items: [
                "Requires a complete model: P(s′|s,a) must be known for all transitions; rarely available in real-world problems",
                "Curse of dimensionality: the state space grows exponentially with the number of state variables",
                "Only works for small, discrete state spaces; even moderately sized problems become intractable",
                "Computational cost: each sweep is O(|S|²·|A|), infeasible for large |S|",
                "Cannot handle continuous states or actions directly",
            ])

            Text(
                "For large or unknown environments, we must turn to sampling-based methods like Monte Carlo, TD learning, and function approximation."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }

    // MARK: - Connection to Modern RL

    private var connectionSection: some View {
        ExploreSectionCard(title: "Connection to Modern RL") {
            Text(
                "Though DP is rarely used directly in practice, its core ideas underpin virtually all modern RL algorithms:"
            )
            .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                connectionRow(
                    method: "TD Learning",
                    link:
                        "Replaces the model-based expectation Σₛ′ P(s′|s,a)[...] with a sampled transition (s,a,r,s′), using the same bootstrapping idea."
                )
                connectionRow(
                    method: "Q-Learning",
                    link:
                        "Approximates the Bellman optimality equation with sampled experience instead of a model: Q(s,a) ← Q(s,a) + α[r + γ max Q(s′,a′) − Q(s,a)]."
                )
                connectionRow(
                    method: "Actor-Critic",
                    link:
                        "Generalizes policy iteration: the actor (policy) improves via the critic's (value function) feedback, mirroring the evaluation → improvement loop."
                )
                connectionRow(
                    method: "Dyna Architecture",
                    link:
                        "Explicitly combines DP-style planning with TD learning by learning a model from experience and then planning with it."
                )
            }

            Text(
                "Understanding DP gives you the theoretical foundation to grasp why these sampling-based methods work and where their update rules come from."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.top, 8)
        }
    }

    private func connectionRow(method: String, link: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(method)
                .fontWeight(.medium)
            Text(link)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
