import SwiftUI

struct A2CPage: View {
    var relatedItems: [ExploreItem] = []
    var body: some View {
        ExploreDocPage(title: "A2C", relatedItems: relatedItems) {
            introSection
            architectureSection
            advantageSection
            actorLossSection
            criticLossSection
            algorithmSection
            a3cSection
            comparisonSection
            whenToUseSection
            limitationsSection
            connectionSection
        }
    }
}

extension A2CPage {
    private var introSection: some View {
        Text(
            "Advantage Actor-Critic (A2C) combines policy gradient methods with a value function baseline, using two neural networks: an Actor for the policy and a Critic for value estimation. By using the advantage function instead of raw returns, A2C reduces gradient variance while remaining simpler than PPO."
        )
        .foregroundStyle(.secondary)
    }

    private var architectureSection: some View {
        ExploreSectionCard(title: "Actor-Critic Architecture") {
            Text("A2C uses two networks that often share early layers:")
                .foregroundStyle(.secondary)

            CodeBlock([
                "Actor (Policy Network) π_θ:",
                "    Input:  State s",
                "    Output: π(a|s); action probabilities (discrete)",
                "            or μ(s), σ(s); Gaussian parameters (continuous)",
                "",
                "Critic (Value Network) Vᵩ:",
                "    Input:  State s",
                "    Output: V(s); scalar expected return from state s",
            ])

            VStack(alignment: .leading, spacing: 8) {
                Text("Why a Critic?").fontWeight(.medium)
                BulletList(items: [
                    "The Critic provides a baseline that reduces policy gradient variance",
                    "Without a baseline: high variance from Monte Carlo returns",
                    "With V(s) baseline: gradient uses advantage = return − V(s)",
                    "Shared layers: common to use a shared backbone for efficiency",
                ])
            }
        }
    }

    private var advantageSection: some View {
        ExploreSectionCard(title: "The Advantage Function") {
            Text(
                "The advantage measures how much better an action is compared to the average action in a given state:"
            )
            .foregroundStyle(.secondary)

            EquationBlock(text: "A(s,a) = Q(s,a) − V(s)")

            VStack(alignment: .leading, spacing: 8) {
                Text("Using the TD error as an unbiased estimate:").fontWeight(.medium)
                EquationBlock(text: "A(s,a) ≈ δ = r + γ·V(s′) − V(s)")

                BulletList(items: [
                    "Q(s,a): expected return after taking action a in state s",
                    "V(s): expected return from state s (averaged over all actions)",
                    "A(s,a) > 0 → action is better than average",
                    "A(s,a) < 0 → action is worse than average",
                    "Using the TD error δ avoids needing a separate Q-network",
                ])
            }

            Text(
                "The advantage subtracts the state baseline V(s) from the return, centering the learning signal and significantly reducing variance."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }

    private var actorLossSection: some View {
        ExploreSectionCard(title: "Actor Loss (Policy Gradient)") {
            Text(
                "The Actor is updated to maximize the advantage-weighted log-probability of selected actions:"
            )
            .foregroundStyle(.secondary)

            EquationBlock(text: "L_actor = −E[ log π(a|s) · A(s,a) ]")

            VStack(alignment: .leading, spacing: 8) {
                Text("With entropy bonus for exploration:").fontWeight(.medium)
                EquationBlock(text: "L_actor = −E[ log π(a|s) · A(s,a) − β·H(π(·|s)) ]")

                BulletList(items: [
                    "log π(a|s): log-probability of the taken action",
                    "A(s,a): advantage (positive → increase probability, negative → decrease)",
                    "H(π): entropy of the policy distribution (encourages exploration)",
                    "β: entropy coefficient (typically 0.01 to 0.05)",
                    "Gradient ascent on advantage × log-probability",
                ])
            }
        }
    }

    private var criticLossSection: some View {
        ExploreSectionCard(title: "Critic Loss & n-Step Returns") {
            Text(
                "A2C typically uses n-step returns instead of full episode returns for a better bias-variance trade-off:"
            )
            .foregroundStyle(.secondary)

            EquationBlock(text: "Gₜ⁽ⁿ⁾ = rₜ + γrₜ₊₁ + ... + γⁿ⁻¹rₜ₊ₙ₋₁ + γⁿ·V(sₜ₊ₙ)")

            VStack(alignment: .leading, spacing: 8) {
                Text("Critic loss:").fontWeight(.medium)
                EquationBlock(text: "L_critic = E[ (V(sₜ) − Gₜ⁽ⁿ⁾)² ]")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Why n-step returns?").fontWeight(.medium)
                BulletList(items: [
                    "n = 1 (TD(0)): low variance but high bias from V(s′) estimate",
                    "n = ∞ (Monte Carlo): unbiased but high variance from full returns",
                    "n = 5 to 20: practical balance of bias and variance",
                    "n-step gives a more accurate target than 1-step TD for on-policy methods",
                ])
            }

            Text(
                "The Critic is trained with MSE to predict these n-step returns, and its gradients are kept separate from the Actor (no gradient flow from Critic to Actor through shared layers)."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }

    private var algorithmSection: some View {
        ExploreSectionCard(title: "Algorithm Walkthrough") {
            Text("A2C with n-step returns and parallel workers:")
                .foregroundStyle(.secondary)

            CodeBlock([
                "Initialize actor π_θ and critic Vᵩ (optionally shared backbone)",
                "Set n_steps (e.g., 5), num_workers (e.g., 8)",
                "",
                "Repeat:",
                "    // Parallel collection across workers",
                "    For each worker in parallel:",
                "        Reset worker's environment copy to start state s",
                "        For step = 1 to n_steps:",
                "            a ~ π(·|s)              // sample from policy",
                "            Execute a, observe r, s′, done",
                "            Store (s, a, r, s′, done)",
                "            s ← s′",
                "            If done: break",
                "    ",
                "    // Compute n-step returns and advantages",
                "    For each stored trajectory:",
                "        G = 0 if done else V(s_last)",
                "        For t = n_steps-1 down to 0:",
                "            G ← rₜ + γ·G",
                "            Aₜ = G − V(sₜ)          // advantage",
                "            Rₜ = G                     // n-step return target",
                "    ",
                "    // Update networks",
                "    L_actor = mean(−log π(a|s) · A − β·H(π))",
                "    L_critic = mean((V(s) − R)²)",
                "    L_total = L_actor + 0.5·L_critic",
                "    Backpropagate and update θ, φ (separate optimizers recommended)",
            ])
        }
    }

    private var a3cSection: some View {
        ExploreSectionCard(title: "A3C: The Asynchronous Predecessor") {
            Text(
                "A2C is the synchronous variant of A3C (Asynchronous Advantage Actor-Critic). A3C was introduced first and uses multiple workers running asynchronously with no global synchronization barrier:"
            )
            .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("A3C vs A2C:").fontWeight(.medium)
                BulletList(items: [
                    "A3C workers update a global network independently, without waiting for each other",
                    "A2C waits for all workers to finish a rollout, then applies a single batched update",
                    "A2C is typically more GPU-efficient (batched gradients)",
                    "A3C can be more sample-efficient on CPU clusters",
                    "Both use the same advantage formulation and network architecture",
                ])
            }

            Text(
                "In practice, A2C is often preferred for its simpler implementation, better GPU utilization, and comparable performance. Most modern frameworks implement A2C, not A3C."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }

    private var comparisonSection: some View {
        ExploreComparisonCard(
            title: "A2C vs PPO",
            leftTitle: "A2C",
            rightTitle: "PPO",
            rows: [
                ExploreComparison(
                    aspect: "Policy update",
                    left: "Unconstrained gradient ascent on advantage",
                    right: "Clipped surrogate objective with ratio rₜ(θ)"
                ),
                ExploreComparison(
                    aspect: "Stability",
                    left: "Moderate; can produce large, destructive updates",
                    right: "High; clipping prevents large policy changes"
                ),
                ExploreComparison(
                    aspect: "Sample reuse",
                    left: "One update per rollout (on-policy)",
                    right: "Multiple epochs per rollout (n_epochs ≥ 4)"
                ),
                ExploreComparison(
                    aspect: "Advantage",
                    left: "n-step TD error or simple advantage",
                    right: "Typically GAE (generalized advantage estimation)"
                ),
                ExploreComparison(
                    aspect: "Complexity",
                    left: "Simpler; two losses, no clipping logic",
                    right: "More complex; ratio clipping, multi-epoch, GAE"
                ),
                ExploreComparison(
                    aspect: "Hyperparameters",
                    left: "Fewer (lr, n_steps, entropy coef)",
                    right: "More (clip range, n_epochs, gae_lambda, etc.)"
                ),
            ],
            footer:
                "PPO is essentially A2C with a clipped objective and multi-epoch updates. If A2C is too unstable, PPO is the natural next step."
        )
    }

    private var whenToUseSection: some View {
        ExploreSectionCard(title: "When to Use A2C") {
            BulletList(items: [
                "You want a simple, clean actor-critic baseline",
                "Both discrete and continuous action spaces are supported",
                "You need a stepping stone before moving to PPO",
                "You value implementation simplicity over maximum stability",
                "Educational settings: A2C is easier to understand and debug",
                "Environments with moderate stochasticity where vanilla policy gradients work",
            ])
        }
    }

    private var limitationsSection: some View {
        ExploreSectionCard(title: "Limitations") {
            BulletList(items: [
                "Less stable than PPO; unbounded policy updates can cause collapse",
                "Requires careful advantage normalization (normally zero-mean, unit-variance)",
                "Sensitive to learning rate; too high causes policy degradation",
                "On-policy: data is discarded after a single update",
                "No trust region or clipping; nothing prevents the policy from changing too much",
                "Performance lags behind PPO on most standard benchmarks",
                "Shared network architecture requires balancing actor and critic loss scales",
            ])
        }
    }

    private var connectionSection: some View {
        ExploreSectionCard(title: "Connection to PPO") {
            Text(
                "PPO is the direct successor to A2C. The core insight is that A2C's unconstrained policy gradient can be replaced with a clipped objective that prevents the new policy from diverging too far from the old one:"
            )
            .foregroundStyle(.secondary)

            EquationBlock(text: "A2C:  L = −E[ log π(a|s) · A ]")
            EquationBlock(text: "PPO:  L = E[ min(r·A, clip(r, 1−ε, 1+ε)·A) ]")

            VStack(alignment: .leading, spacing: 8) {
                Text("What PPO adds:").fontWeight(.medium)
                BulletList(items: [
                    "r = π_new / π_old: probability ratio; a measure of how much the policy changed",
                    "clip(r, 1−ε, 1+ε): prevents r from going too far from 1",
                    "Multiple optimization epochs per rollout (better data efficiency)",
                    "GAE for more stable advantage estimates",
                ])
            }

            Text(
                "Understanding A2C makes PPO straightforward: PPO is A2C plus a safeguard that limits how much the policy can change in a single update, trading a small amount of simplicity for a large gain in stability."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }
}
