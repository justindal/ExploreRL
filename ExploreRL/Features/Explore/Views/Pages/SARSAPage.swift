import SwiftUI

struct SARSAPage: View {
    var body: some View {
        ExploreDocPage(title: "SARSA") {
            introSection
            nameSection
            updateRuleSection
            tdErrorSection
            algorithmSection
            epsilonGreedySection
            parametersSection
            exampleSection
            vsQLearningSection
            whenToUseSection
            limitationsSection
        }
    }
}

extension SARSAPage {
    private var introSection: some View {
        Text("SARSA is a foundational on-policy reinforcement learning algorithm. The name comes from the quintuple (S, A, R, S′, A′) used in each update. Unlike Q-Learning, SARSA learns the value of the policy it's actually following.")
            .foregroundStyle(.secondary)
    }

    private var nameSection: some View {
        ExploreSectionCard(title: "What Does SARSA Mean?") {
            Text("SARSA stands for the five elements used in each update:")
                .foregroundStyle(.secondary)

            CodeBlock([
                "S  → Current state",
                "A  → Action taken",
                "R  → Reward received",
                "S′ → Next state",
                "A′ → Next action (actually chosen)"
            ])

            Text("The key insight: SARSA uses the actual next action A′, not the theoretical best action.")
                .foregroundStyle(.secondary)
        }
    }

    private var updateRuleSection: some View {
        ExploreSectionCard(title: "The Update Rule") {
            Text("SARSA updates Q-values using the action that will actually be taken next:")
                .foregroundStyle(.secondary)

            EquationBlock(text: "Q(s,a) ← Q(s,a) + α [ r + γ Q(s′,a′) − Q(s,a) ]")

            VStack(alignment: .leading, spacing: 8) {
                Text("Components:").fontWeight(.medium)
                BulletList(items: [
                    "Q(s,a): current estimate for state s, action a",
                    "α (alpha): learning rate, step size for updates",
                    "r: immediate reward received",
                    "γ (gamma): discount factor, weight of future rewards",
                    "Q(s′,a′): value of the next state-action pair (not max!)"
                ])
            }
        }
    }

    private var tdErrorSection: some View {
        ExploreSectionCard(title: "Temporal Difference Error") {
            Text("The TD error for SARSA uses the actual next action:")
                .foregroundStyle(.secondary)

            EquationBlock(text: "δ = r + γ Q(s′,a′) − Q(s,a)")

            BulletList(items: [
                "TD target: r + γ Q(s′,a′)  expected value following current policy",
                "This reflects what the agent will actually do, not optimal behavior",
                "Makes SARSA more conservative in risky environments"
            ])
        }
    }

    private var algorithmSection: some View {
        ExploreSectionCard(title: "Algorithm Walkthrough") {
            Text("The complete SARSA algorithm:")
                .foregroundStyle(.secondary)

            CodeBlock([
                "Initialize Q-table with zeros",
                "",
                "For each episode:",
                "    s ← initial state",
                "    a ← choose action using ε-greedy from Q(s, ·)",
                "    ",
                "    While not done:",
                "        Take action a, observe r, s′, done",
                "        a′ ← choose action using ε-greedy from Q(s′, ·)",
                "        ",
                "        Q(s,a) ← Q(s,a) + α[r + γ Q(s′,a′) − Q(s,a)]",
                "        ",
                "        s ← s′",
                "        a ← a′",
                "    Decay ε"
            ])

            Text("Notice: the next action a′ is chosen before the update, then becomes the action for the next step.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    private var epsilonGreedySection: some View {
        ExploreSectionCard(title: "ε-Greedy in SARSA") {
            Text("SARSA uses ε-greedy for action selection, and this directly affects learning:")
                .foregroundStyle(.secondary)

            BulletList(items: [
                "The policy being followed IS the policy being learned",
                "Exploratory (random) actions affect Q-value updates",
                "Higher ε leads to more conservative Q-values",
                "SARSA learns the value of exploring, not just exploiting"
            ])

            Text("This is SARSA's on-policy behaviour, it evaluates and improves the same policy.")
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
                    description: "Controls update magnitude. Same considerations as Q-Learning."
                ),
                ExploreParameter(
                    name: "γ (Discount Factor)",
                    typical: "0.95 – 0.99",
                    description: "Values future rewards. Determines how far ahead to plan."
                ),
                ExploreParameter(
                    name: "ε (Exploration Rate)",
                    typical: "1.0 → 0.01",
                    description: "More impactful than in Q-Learning since it affects the learned values."
                ),
                ExploreParameter(
                    name: "ε Decay",
                    typical: "0.995 per episode",
                    description: "As ε decreases, SARSA converges toward Q-Learning behavior."
                ),
            ]
        )
    }

    private var exampleSection: some View {
        ExploreSectionCard(title: "Example: Cliff Walking") {
            Text("Consider a grid where the agent must walk from Start to Goal, avoiding a cliff. Falling off the cliff gives -100 reward.")
                .foregroundStyle(.secondary)

            CodeBlock([
                "┌───┬───┬───┬───┬───┐",
                "│   │   │   │   │   │",
                "├───┼───┼───┼───┼───┤",
                "│ S │ C │ C │ C │ G │  S = Start",
                "└───┴───┴───┴───┴───┘  C = Cliff (-100)",
                "                       G = Goal (+1)"
            ])

            VStack(alignment: .leading, spacing: 8) {
                Text("Learned paths:").fontWeight(.medium)
                BulletList(items: [
                    "Q-Learning: walks along the cliff edge (optimal but risky)",
                    "SARSA: takes the safer path away from the cliff",
                    "SARSA accounts for the chance of random exploration near the cliff"
                ])
            }
        }
    }

    private var vsQLearningSection: some View {
        ExploreComparisonCard(
            title: "SARSA vs Q‑Learning",
            leftTitle: "SARSA",
            rightTitle: "Q‑Learning",
            rows: [
                ExploreComparison(
                    aspect: "Update uses",
                    left: "Q(s′, a′) actual next action",
                    right: "max Q(s′, a′) best action"
                ),
                ExploreComparison(
                    aspect: "Policy type",
                    left: "On-policy",
                    right: "Off-policy"
                ),
                ExploreComparison(
                    aspect: "Behavior",
                    left: "Conservative, safer",
                    right: "Optimistic, riskier"
                ),
                ExploreComparison(
                    aspect: "Exploration impact",
                    left: "Affects learned values",
                    right: "Only affects data collection"
                ),
                ExploreComparison(
                    aspect: "Convergence",
                    left: "To policy being followed",
                    right: "To optimal policy"
                ),
            ],
            footer: "Choose SARSA when the cost of exploration matters (robotics, finance). Choose Q‑Learning when you want the optimal policy regardless of exploration risk."
        )
    }

    private var whenToUseSection: some View {
        ExploreSectionCard(title: "When to Use SARSA") {
            BulletList(items: [
                "Exploration has real costs (physical systems, money)",
                "Environment is stochastic or has dangerous states",
                "You want to learn a safe, risk-aware policy",
                "The deployed policy will also explore (same ε as training)"
            ])
        }
    }

    private var limitationsSection: some View {
        ExploreSectionCard(title: "Limitations") {
            BulletList(items: [
                "Learns suboptimal policy if exploration continues",
                "Slower convergence than Q-Learning in safe environments",
                "Same tabular limitations: discrete states, state explosion",
                "Less sample efficient (can't use off-policy data)"
            ])
        }
    }
}
