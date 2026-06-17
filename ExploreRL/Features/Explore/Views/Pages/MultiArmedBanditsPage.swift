import SwiftUI

struct MultiArmedBanditsPage: View {
    var relatedItems: [ExploreItem] = []
    var body: some View {
        ExploreDocPage(title: "Multi-Armed Bandits", relatedItems: relatedItems) {
            introSection
            whatIsSection
            exploreExploitSection
            actionValueSection
            epsilonGreedySection
            ucbSection
            regretSection
            connectionToRLSection
            summarySection
        }
    }
}

extension MultiArmedBanditsPage {
    private var introSection: some View {
        Text(
            "The multi-armed bandit problem is the simplest form of the exploration-exploitation dilemma. It captures the core tension of reinforcement learning (should I stick with what I know, or try something new?) without the complexity of state transitions."
        )
        .foregroundStyle(.secondary)
    }

    private var whatIsSection: some View {
        ExploreSectionCard(title: "What is a Multi-Armed Bandit?") {
            Text(
                "Imagine you're in a casino with k slot machines (\"one-armed bandits\"). Each machine has an unknown probability distribution of paying out. Your goal: maximize total reward over n pulls."
            )
            .foregroundStyle(.secondary)

            Text(
                "The name comes from the idea that each machine is an \"arm\" you can pull, and pulling an arm gives a stochastic reward drawn from that arm's hidden distribution."
            )
            .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Key characteristics:").fontWeight(.medium)
                BulletList(items: [
                    "k arms (actions), each with an unknown reward distribution",
                    "At each time step t, you choose one arm aₜ to pull",
                    "You receive a reward rₜ drawn from that arm's distribution",
                    "No state; the environment doesn't change between pulls",
                    "Goal: maximize cumulative reward Σ rₜ over T pulls",
                ])
            }
        }
    }

    private var exploreExploitSection: some View {
        ExploreSectionCard(title: "The Explore-Exploit Tradeoff") {
            Text("Every pull is a choice between two competing objectives:")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text("Exploitation:")
                        .fontWeight(.medium)
                        .frame(width: 110, alignment: .leading)
                    Text(
                        "Pull the arm that currently looks best. Maximizes immediate reward but may miss better arms."
                    )
                    .foregroundStyle(.secondary)
                }
                HStack(alignment: .top) {
                    Text("Exploration:")
                        .fontWeight(.medium)
                        .frame(width: 110, alignment: .leading)
                    Text(
                        "Pull other arms to gather more information. May sacrifice short-term reward but discovers better arms."
                    )
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 4)

            Text(
                "This is the fundamental tension: you can't both explore and exploit with the same pull. Every algorithm for bandits is a strategy for navigating this tradeoff."
            )
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }

    private var actionValueSection: some View {
        ExploreSectionCard(title: "Action-Value Estimation") {
            Text(
                "To decide which arm to pull, we need an estimate of how good each arm is. The simplest estimate is the sample average of rewards received so far:"
            )
            .foregroundStyle(.secondary)

            EquationBlock(
                text: "Qₜ(a) = (sum of rewards when a was taken) / (number of times a was taken)")

            Text(
                "More formally, if arm a has been pulled Nₜ(a) times and received rewards r₁, r₂, ..., r_{Nₜ(a)}:"
            )
            .foregroundStyle(.secondary)

            EquationBlock(text: "Qₜ(a) = 1 / Nₜ(a)  ·  Σ rᵢ   for i = 1 to Nₜ(a)")

            Text(
                "As we collect more data, this estimate converges to the true expected value of the arm by the law of large numbers. This is the foundation that ε-greedy and UCB build upon."
            )
            .foregroundStyle(.secondary)
        }
    }

    private var epsilonGreedySection: some View {
        ExploreSectionCard(title: "ε-Greedy Strategy") {
            Text("The simplest algorithm for balancing exploration and exploitation:")
                .foregroundStyle(.secondary)

            CodeBlock([
                "With probability ε:",
                "    Choose a random arm   (explore)",
                "With probability 1 − ε:",
                "    Choose argmax Q(a)    (exploit)",
            ])

            VStack(alignment: .leading, spacing: 8) {
                Text("How it works:").fontWeight(.medium)
                BulletList(items: [
                    "ε = 0.1 means 10% random pulls, 90% greedy pulls",
                    "Typically start high (ε = 1.0) and decay over time",
                    "Simple to implement and surprisingly effective",
                    "Limitation: explores uniformly, even arms known to be bad",
                ])
            }

            Text(
                "The key weakness: ε-greedy doesn't account for uncertainty. An arm pulled 1,000 times and an arm pulled 5 times get the same exploration probability."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }

    private var ucbSection: some View {
        ExploreSectionCard(title: "Upper Confidence Bound (UCB)") {
            Text(
                "UCB improves on ε-greedy by exploring arms proportionally to their uncertainty. It chooses the arm that maximizes an upper confidence bound:"
            )
            .foregroundStyle(.secondary)

            EquationBlock(text: "aₜ = argmax [ Qₜ(a) + c · sqrt( ln(t) / Nₜ(a) ) ]")

            VStack(alignment: .leading, spacing: 8) {
                Text("Breaking down the formula:").fontWeight(.medium)
                BulletList(items: [
                    "Qₜ(a): estimated value of arm a (exploitation term)",
                    "c: exploration parameter; higher c means more exploration",
                    "ln(t): natural log of total pulls; grows slowly over time",
                    "Nₜ(a): number of times arm a has been pulled; shrinks the bonus as we gain confidence",
                    "sqrt(ln(t)/Nₜ(a)): the uncertainty bonus; large when Nₜ(a) is small",
                ])
            }

            Text(
                "Intuition: arms with few pulls get a large bonus, making them more likely to be chosen. As Nₜ(a) grows, the bonus shrinks and the estimate Qₜ(a) dominates. This is often called \"optimism in the face of uncertainty.\""
            )
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }

    private var regretSection: some View {
        ExploreSectionCard(title: "Regret") {
            Text(
                "Regret measures how much reward we lost compared to always pulling the best arm. It's the standard way to evaluate bandit algorithms:"
            )
            .foregroundStyle(.secondary)

            EquationBlock(text: "Regret(T) = T · μ* − Σ rₜ   for t = 1 to T")

            VStack(alignment: .leading, spacing: 8) {
                Text("Where:").fontWeight(.medium)
                BulletList(items: [
                    "T: total number of pulls",
                    "μ*: true mean reward of the optimal arm",
                    "rₜ: reward received at time t",
                    "T · μ*: the maximum possible total reward (pulling optimal arm every time)",
                ])
            }

            Text(
                "A good algorithm has regret that grows sublinearly (O(log T) for UCB), meaning the per-step regret approaches zero over time. ε-greedy with constant ε has linear regret because it never stops exploring."
            )
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }

    private var connectionToRLSection: some View {
        ExploreSectionCard(title: "Connection to Full Reinforcement Learning") {
            Text(
                "Multi-armed bandits are the simplest possible RL problem; they are RL without state."
            )
            .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("What bandits and RL share:").fontWeight(.medium)
                BulletList(items: [
                    "The explore-exploit tradeoff is the central challenge in both",
                    "Action-value estimation (Q-values) is the same core idea",
                    "ε-greedy and UCB are used as exploration strategies in deep RL (DQN, etc.)",
                    "Regret analysis carries over to more complex settings",
                ])
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("What full RL adds:").fontWeight(.medium)
                BulletList(items: [
                    "State: the environment changes based on your actions",
                    "Delayed rewards: actions now affect future states and rewards",
                    "Credit assignment: which past action caused this reward?",
                    "Planning and lookahead: thinking multiple steps ahead",
                ])
            }

            Text(
                "In bandits, pulling an arm only affects the immediate reward. In RL, an action changes the state you're in, which changes what rewards and actions are available next. That's why we need ideas like the Bellman equation and TD learning, but it all starts here."
            )
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }

    private var summarySection: some View {
        ExploreSectionCard(title: "Summary") {
            BulletList(items: [
                "Bandits are the simplest exploration-exploitation problem",
                "Action-value estimation: Q(a) = average of past rewards",
                "ε-greedy: simple but explores blindly",
                "UCB: explores intelligently using uncertainty bonuses",
                "Regret quantifies the cost of not knowing the best arm",
                "Full RL = bandits + state transitions + delayed rewards",
            ])
        }
    }
}
