import SwiftUI

struct QLearningPage: View {
    var body: some View {
        ExploreDocPage(title: "Q‑Learning") {
            introSection
            qValueSection
            bellmanSection
            updateRuleSection
            tdErrorSection
            algorithmSection
            epsilonGreedySection
            parametersSection
            exampleSection
            convergenceSection
            offPolicySection
            whenToUseSection
            limitationsSection
        }
    }
}

extension QLearningPage {
    private var introSection: some View {
        Text("Q-Learning is a foundational reinforcement learning algorithm that learns the value of taking each action in each state. It's \"model-free\" (no environment dynamics needed) and \"off-policy\" (learns optimal behavior even while exploring).")
            .foregroundStyle(.secondary)
    }

    private var qValueSection: some View {
        ExploreSectionCard(title: "What is a Q-Value?") {
            Text("A Q-value, written Q(s, a), represents the expected total future reward for taking action a in state s, then following the optimal policy thereafter.")
                .foregroundStyle(.secondary)

            EquationBlock(text: "Q(s, a) = Expected future return starting from s, taking a")

            Text("Think of it as answering: \"How good is this action in this situation?\" Higher Q-values mean better expected outcomes.")
                .foregroundStyle(.secondary)
        }
    }

    private var bellmanSection: some View {
        ExploreSectionCard(title: "The Bellman Equation") {
            Text("Q-Learning is derived from the Bellman optimality equation, which expresses the optimal Q-value recursively:")
                .foregroundStyle(.secondary)

            EquationBlock(text: "Q*(s,a) = Σ[ r + γ max Q*(s′,a′) ]")

            Text("This says: the optimal value of taking action a in state s equals the expected immediate reward plus the discounted value of acting optimally from the next state. Q-Learning iteratively approximates this.")
                .foregroundStyle(.secondary)
        }
    }

    private var updateRuleSection: some View {
        ExploreSectionCard(title: "The Update Rule") {
            Text("Q-Learning uses temporal difference (TD) learning to approximate the Bellman equation:")
                .foregroundStyle(.secondary)

            EquationBlock(text: "Q(s,a) ← Q(s,a) + α [ r + γ max Q(s′,a′) − Q(s,a) ]")

            VStack(alignment: .leading, spacing: 8) {
                Text("Components:").fontWeight(.medium)
                BulletList(items: [
                    "Q(s,a): current estimate for state s, action a",
                    "α (alpha): learning rate, step size for updates",
                    "r: immediate reward received",
                    "γ (gamma): discount factor, weight of future rewards",
                    "max Q(s′,a′): best estimated value in next state s′"
                ])
            }
        }
    }

    private var tdErrorSection: some View {
        ExploreSectionCard(title: "Temporal Difference Error") {
            Text("The bracketed term in the update rule is the TD error (δ):")
                .foregroundStyle(.secondary)

            EquationBlock(text: "δ = r + γ max Q(s′,a′) − Q(s,a)")

            BulletList(items: [
                "TD target: r + γ max Q(s′,a′) - what we now think Q should be",
                "TD error: difference between target and current estimate",
                "Positive δ → we underestimated, increase Q",
                "Negative δ → we overestimated, decrease Q",
                "Learning converges as TD errors approach zero"
            ])
        }
    }

    private var algorithmSection: some View {
        ExploreSectionCard(title: "Algorithm Walkthrough") {
            Text("The complete Q-Learning algorithm:")
                .foregroundStyle(.secondary)

            CodeBlock([
                "Initialize Q-table with zeros",
                "",
                "For each episode:",
                "    s ← initial state",
                "    ",
                "    While not done:",
                "        Choose a using ε-greedy from Q(s, ·)",
                "        Take action a, observe r, s′, done",
                "        ",
                "        Q(s,a) ← Q(s,a) + α[r + γ max Q(s′,·) − Q(s,a)]",
                "        ",
                "        s ← s′",
                "    Decay ε"
            ])
        }
    }

    private var epsilonGreedySection: some View {
        ExploreSectionCard(title: "ε-Greedy Exploration") {
            Text("ε-greedy is how Q-Learning balances exploration (trying new actions) and exploitation (using what it knows):")
                .foregroundStyle(.secondary)

            CodeBlock([
                "With probability ε:",
                "    Choose a random action",
                "Otherwise:",
                "    Choose argmax Q(s, a)  // best known action"
            ])

            VStack(alignment: .leading, spacing: 8) {
                Text("Why it works:").fontWeight(.medium)
                BulletList(items: [
                    "Early training (ε ≈ 1.0): mostly random, discovers the state space",
                    "Mid training (ε ≈ 0.5): mix of exploration and exploitation",
                    "Late training (ε ≈ 0.01): mostly greedy, refines optimal policy",
                    "Without exploration, the agent may miss better actions"
                ])
            }

            Text("Example: ε = 0.1 means 10% random actions, 90% greedy actions.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    private var parametersSection: some View {
        ExploreParametersCard(
            title: "Key Parameters",
            parameters: [
                ExploreParameter(
                    name: "α (Learning Rate)",
                    typical: "0.1 – 0.5",
                    description: "Controls update magnitude. Too high → unstable. Too low → slow learning."
                ),
                ExploreParameter(
                    name: "γ (Discount Factor)",
                    typical: "0.95 – 0.99",
                    description: "Values future rewards. γ=0 is greedy (now only). γ=1 treats all future rewards equally."
                ),
                ExploreParameter(
                    name: "ε (Exploration Rate)",
                    typical: "1.0 → 0.01",
                    description: "Probability of random action. Starts high for exploration, decays over training."
                ),
                ExploreParameter(
                    name: "ε Decay",
                    typical: "0.995 per episode",
                    description: "Rate at which ε decreases. Balances early exploration vs later exploitation."
                ),
            ]
        )
    }

    private var exampleSection: some View {
        ExploreSectionCard(title: "Example: Frozen Lake") {
            Text("Consider a 2×2 simplified grid. The agent starts at S and must reach G (reward +1). Holes H give reward 0 and end the episode.")
                .foregroundStyle(.secondary)

            CodeBlock([
                "┌───┬───┐",
                "│ S │ F │    S = Start",
                "├───┼───┤    F = Frozen (safe)",
                "│ H │ G │    H = Hole (terminal)",
                "└───┴───┘    G = Goal (+1 reward)"
            ])

            Text("Initial Q-table (all zeros):")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            QTableView(
                states: ["S", "F", "H", "G"],
                actions: ["←", "↓", "→", "↑"],
                values: [
                    [0.0, 0.0, 0.0, 0.0],
                    [0.0, 0.0, 0.0, 0.0],
                    [0.0, 0.0, 0.0, 0.0],
                    [0.0, 0.0, 0.0, 0.0]
                ]
            )

            Text("After training, Q-values reflect the path to the goal:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            QTableView(
                states: ["S", "F", "H", "G"],
                actions: ["←", "↓", "→", "↑"],
                values: [
                    [0.00, 0.00, 0.81, 0.00],
                    [0.00, 0.90, 0.00, 0.00],
                    [0.00, 0.00, 0.00, 0.00],
                    [0.00, 0.00, 0.00, 0.00]
                ],
                highlightedCell: (row: 0, col: 2)
            )

            Text("The agent learned: from S, go right (→) to F, then down (↓) to reach G.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    private var convergenceSection: some View {
        ExploreSectionCard(title: "Convergence Guarantees") {
            Text("Q-Learning is proven to converge to the optimal Q-values Q* under these conditions:")
                .foregroundStyle(.secondary)

            BulletList(items: [
                "All state-action pairs are visited infinitely often",
                "Learning rate α decreases appropriately (but not too fast)",
                "The environment is a finite Markov Decision Process (MDP)"
            ])

            Text("In practice, we use a fixed α and ε-decay, which works well for most tabular problems even without strict convergence guarantees.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    private var offPolicySection: some View {
        ExploreSectionCard(title: "Off-Policy vs On-Policy") {
            Text("Q-Learning is off-policy because it updates using the maximum Q-value of the next state, regardless of what action was actually taken next.")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text("Q-Learning:")
                        .fontWeight(.medium)
                        .frame(width: 100, alignment: .leading)
                    Text("Updates with max Q(s′,a′) - the best possible action")
                        .foregroundStyle(.secondary)
                }
                HStack(alignment: .top) {
                    Text("SARSA:")
                        .fontWeight(.medium)
                        .frame(width: 100, alignment: .leading)
                    Text("Updates with Q(s′,a′) - the action actually taken")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 4)

            Text("This makes Q-Learning more optimistic but sometimes riskier, while SARSA is more conservative.")
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    private var whenToUseSection: some View {
        ExploreSectionCard(title: "When to Use Q-Learning") {
            BulletList(items: [
                "Discrete state space (can enumerate all states)",
                "Discrete action space (finite actions)",
                "Small enough to fit in a table (< ~10,000 states)",
                "Environments like FrozenLake, Taxi, Blackjack, CliffWalking"
            ])
        }
    }

    private var limitationsSection: some View {
        ExploreSectionCard(title: "Limitations") {
            BulletList(items: [
                "State explosion: real-world problems have too many states",
                "No generalization: each state learned independently",
                "Continuous states/actions: not directly supported",
                "For larger problems, use DQN (neural network approximation)"
            ])
        }
    }
}
