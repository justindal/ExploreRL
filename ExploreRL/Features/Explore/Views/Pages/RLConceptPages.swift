import SwiftUI

struct RLLoopPage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("The fundamental cycle driving all reinforcement learning.")
                    .foregroundStyle(.secondary)

                ExploreSectionCard(title: "The cycle") {
                    Text(
                        "At each timestep the agent observes the environment, selects an action, and receives a reward and next observation."
                    )
                    .foregroundStyle(.secondary)
                    EquationBlock(text: "sₜ → aₜ → (rₜ₊₁, sₜ₊₁)")
                }

                ExploreSectionCard(title: "Markov Decision Process") {
                    Text("RL problems are formalized as MDPs: a 5-tuple (S, A, P, R, γ).")
                        .foregroundStyle(.secondary)
                    BulletList(items: [
                        "S: set of all possible states",
                        "A: set of all possible actions",
                        "P(s′|s,a): transition probability to next state",
                        "R(s,a,s′): reward function (or simply rₜ₊₁)",
                        "γ ∈ [0,1]: discount factor",
                    ])
                    Text(
                        "The Markov property means the future depends only on the current state, not the history. All RL algorithms exploit this structure."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                }

                ExploreSectionCard(title: "Discrete vs Continuous") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            Text("Discrete:")
                                .fontWeight(.medium)
                                .frame(width: 80, alignment: .leading)
                            Text("Finite actions (left/right, up/down). Tabular methods apply.")
                                .foregroundStyle(.secondary)
                        }
                        HStack(alignment: .top) {
                            Text("Continuous:")
                                .fontWeight(.medium)
                                .frame(width: 80, alignment: .leading)
                            Text(
                                "Real-valued actions (torque, steering). Need function approximation."
                            )
                            .foregroundStyle(.secondary)
                        }
                    }
                    Text(
                        "Discrete observation spaces can use Q-tables. Continuous observations (images, sensors) require neural networks."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                }

                ExploreSectionCard(title: "Episodes") {
                    Text(
                        "An episode runs from an initial state until a terminal condition or step limit. The goal is to maximize total reward per episode."
                    )
                    .foregroundStyle(.secondary)
                }

                ExploreSectionCard(title: "Policy") {
                    Text("A policy maps states to actions. It can be deterministic or stochastic.")
                        .foregroundStyle(.secondary)
                    EquationBlock(text: "π(a|s) = P(aₜ = a | sₜ = s)")
                }
            }
            .padding()
        }
    }
}

struct ReturnsPage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("How agents measure long-term value.")
                    .foregroundStyle(.secondary)

                ExploreSectionCard(title: "Discounted return") {
                    Text(
                        "The return is the sum of future rewards, each discounted by γ per timestep."
                    )
                    .foregroundStyle(.secondary)
                    EquationBlock(text: "Gₜ = rₜ₊₁ + γ rₜ₊₂ + γ² rₜ₊₃ + ...")
                }

                ExploreSectionCard(title: "Discount factor γ") {
                    BulletList(items: [
                        "γ = 0: only immediate reward matters",
                        "γ = 1: all future rewards weighted equally (episodic only)",
                        "Typical range: 0.95 – 0.99",
                    ])
                }

                ExploreSectionCard(title: "n‑Step Returns") {
                    Text(
                        "Instead of bootstrapping after 1 step, we can wait n steps before using a value estimate:"
                    )
                    .foregroundStyle(.secondary)
                    EquationBlock(text: "Gₜ:ₜ₊ₙ = rₜ₊₁ + γrₜ₊₂ + ... + γⁿ⁻¹rₜ₊ₙ + γⁿV(sₜ₊ₙ)")
                    BulletList(items: [
                        "n = 1: TD(0), one-step bootstrap (most common)",
                        "n = ∞: Monte Carlo, uses full episode return",
                        "Intermediate n balances bias and variance",
                    ])
                }

                ExploreSectionCard(title: "TD(λ) and Eligibility Traces") {
                    Text(
                        "TD(λ) combines all n-step returns into a single estimate using an exponentially weighted average:"
                    )
                    .foregroundStyle(.secondary)
                    EquationBlock(text: "Gₜλ = (1−λ) Σₙ λⁿ⁻¹ Gₜ:ₜ₊ₙ")
                    BulletList(items: [
                        "λ = 0: equivalent to TD(0)",
                        "λ = 1: equivalent to Monte Carlo",
                        "Eligibility traces assign credit to recently visited states",
                        "Bridges the gap between TD learning and Monte Carlo",
                    ])
                }

                ExploreSectionCard(title: "TD error") {
                    Text(
                        "Many algorithms learn from a one-step prediction error rather than waiting for the full return."
                    )
                    .foregroundStyle(.secondary)
                    EquationBlock(text: "δₜ = rₜ₊₁ + γ V(sₜ₊₁) − V(sₜ)")
                }
            }
            .padding()
        }
    }
}

struct ExplorationPage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Balancing new knowledge against known reward.")
                    .foregroundStyle(.secondary)

                ExploreSectionCard(title: "The tradeoff") {
                    Text(
                        "Exploit: choose the best-known action. Explore: try something new that might be better."
                    )
                    .foregroundStyle(.secondary)
                }

                ExploreSectionCard(title: "ε‑greedy") {
                    Text(
                        "With probability ε take a random action, otherwise take the greedy action. ε typically decays over training."
                    )
                    .foregroundStyle(.secondary)
                    EquationBlock(text: "a = random with prob ε, argmax Q(s,·) otherwise")
                }

                ExploreSectionCard(title: "Boltzmann (Softmax) Exploration") {
                    Text(
                        "Choose actions with probability proportional to their estimated value, controlled by a temperature parameter τ:"
                    )
                    .foregroundStyle(.secondary)
                    EquationBlock(text: "P(a|s) = exp(Q(s,a)/τ) / Σᵢ exp(Q(s,aᵢ)/τ)")
                    BulletList(items: [
                        "τ → 0: greedy (always pick best)",
                        "τ → ∞: uniform random",
                        "High τ early in training, decay over time",
                        "More nuanced than ε‑greedy: explores promising actions more",
                    ])
                }

                ExploreSectionCard(title: "Upper Confidence Bound (UCB)") {
                    Text("Select actions based on both estimated value and uncertainty:")
                        .foregroundStyle(.secondary)
                    EquationBlock(text: "a = argmax [ Q(s,a) + c √(ln t / N(s,a)) ]")
                    BulletList(items: [
                        "c: exploration coefficient",
                        "t: total timesteps",
                        "N(s,a): number of times action a was taken in state s",
                        "Actions tried less often get a bonus, encouraging systematic exploration",
                    ])
                }

                ExploreSectionCard(title: "Entropy regularization") {
                    Text(
                        "SAC adds an entropy bonus to the objective over all timesteps, encouraging the policy to remain stochastic:"
                    )
                    .foregroundStyle(.secondary)
                    EquationBlock(text: "J(π) = E[ Σₜ γᵗ ( rₜ + α H(π(·|sₜ)) ) ]")
                    BulletList(items: [
                        "H(π): entropy of the policy distribution",
                        "α: temperature controlling exploration–exploitation",
                        "Higher entropy = more random, exploratory actions",
                        "Prevents premature convergence to suboptimal policies",
                    ])
                }
            }
            .padding()
        }
    }
}

struct ReplayPage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Reusing past experience to learn more efficiently.")
                    .foregroundStyle(.secondary)

                ExploreSectionCard(title: "Why replay?") {
                    BulletList(items: [
                        "Breaks temporal correlation between consecutive samples",
                        "Each transition can be used for multiple updates",
                        "Required by off-policy algorithms (DQN, SAC)",
                    ])
                }

                ExploreSectionCard(title: "Transition format") {
                    EquationBlock(text: "(sₜ, aₜ, rₜ₊₁, sₜ₊₁, done)")
                    Text(
                        "The buffer stores a fixed number of recent transitions and overwrites the oldest when full."
                    )
                    .foregroundStyle(.secondary)
                }

                ExploreSectionCard(title: "Training loop") {
                    BulletList(items: [
                        "Collect transitions by interacting with the environment",
                        "Store each transition in the buffer",
                        "Sample a random mini-batch",
                        "Compute loss and update the network",
                    ])
                }

                ExploreSectionCard(title: "Buffer Sizing") {
                    Text("Buffer capacity is a critical hyperparameter:")
                        .foregroundStyle(.secondary)
                    BulletList(items: [
                        "Too small: overfits to recent data, loses old useful experiences",
                        "Too large: slow to fill, old data may be from a much worse policy",
                        "Typical sizes: 10K (simple tasks) to 1M (Atari, complex control)",
                        "A good rule of thumb: buffer should hold many episodes worth of transitions",
                    ])
                }

                ExploreSectionCard(title: "Prioritized Experience Replay (PER)") {
                    Text(
                        "Standard replay samples uniformly. PER samples transitions with higher TD error more often, since they contain more surprise to learn from."
                    )
                    .foregroundStyle(.secondary)
                    EquationBlock(text: "P(i) ∝ |δᵢ|α + ε")
                    BulletList(items: [
                        "δᵢ: TD error of transition i",
                        "α: prioritization exponent (0 = uniform, 1 = full priority)",
                        "ε: small constant so no transition has zero probability",
                        "Requires importance-sampling weights to correct the bias",
                        "Often speeds up learning 2× or more on challenging tasks",
                    ])
                }

                ExploreSectionCard(title: "Hindsight Experience Replay (HER)") {
                    Text(
                        "For sparse-reward tasks where the agent rarely succeeds, HER relabels failed episodes as if the achieved outcome was the goal."
                    )
                    .foregroundStyle(.secondary)
                    BulletList(items: [
                        "After each episode, store the original trajectory",
                        "Also store a copy with a different 'goal'; the state actually reached",
                        "Turns failures into learning signal: 'I reached X, so if X was the goal, this was success'",
                        "Crucial for robotics and goal-conditioned tasks",
                    ])
                }
            }
            .padding()
        }
    }
}
