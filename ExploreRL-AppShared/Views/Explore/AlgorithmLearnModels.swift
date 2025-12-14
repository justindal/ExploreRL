//
//  AlgorithmLearnModels.swift
//

import SwiftUI

struct AlgorithmLearnItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let model: EnvironmentInfoTabModel
}

enum AlgorithmLearnModels {
    static let all: [AlgorithmLearnItem] = [
        qLearning,
        sarsa,
        dqn,
        sac
    ]
    
    static let qLearning = AlgorithmLearnItem(
        id: "qlearning",
        title: "Q-Learning",
        subtitle: "Tabular • Off-policy • Discrete actions",
        icon: "tablecells",
        color: .cyan,
        model: EnvironmentInfoTabModel(
            title: "Q-Learning",
            subtitle: "Tabular • Off-policy",
            overview: "Q-Learning learns an action-value function Q(s, a) and acts greedily with exploration. It is off-policy: it learns about the optimal policy while behaving with an exploratory policy.",
            sections: [
                .init(
                    title: "Core idea",
                    kind: .bullets([
                        "Maintain a table of Q-values for each state-action pair.",
                        "Update towards the best next action (max over a′).",
                        "Use exploration (e.g. ε-greedy) to keep learning."
                    ])
                ),
                .init(
                    title: "Update rule",
                    kind: .keyValues([
                        .init(label: "Target", value: "r + γ · max_a′ Q(s′, a′)"),
                        .init(label: "Update", value: "Q(s,a) ← Q(s,a) + α · (target − Q(s,a))")
                    ])
                ),
                .init(
                    title: "When to use",
                    kind: .bullets([
                        "Small discrete state/action spaces (e.g. FrozenLake).",
                        "Great baseline to understand RL quickly."
                    ])
                ),
                .init(
                    title: "Common knobs",
                    kind: .bullets([
                        "α (learning rate): update size.",
                        "γ (discount): how much future rewards matter.",
                        "ε (exploration): probability of random action."
                    ])
                )
            ]
        )
    )
    
    static let sarsa = AlgorithmLearnItem(
        id: "sarsa",
        title: "SARSA",
        subtitle: "Tabular • On-policy • Discrete actions",
        icon: "arrow.triangle.2.circlepath",
        color: .teal,
        model: EnvironmentInfoTabModel(
            title: "SARSA",
            subtitle: "Tabular • On-policy",
            overview: "SARSA is like Q-Learning but on-policy: it learns Q-values for the policy it is actually following. This often makes it more conservative in stochastic environments.",
            sections: [
                .init(
                    title: "Core idea",
                    kind: .bullets([
                        "Maintain Q(s, a) as a table.",
                        "Update using the action actually taken next (a′), not the best possible action."
                    ])
                ),
                .init(
                    title: "Update rule",
                    kind: .keyValues([
                        .init(label: "Target", value: "r + γ · Q(s′, a′)"),
                        .init(label: "Update", value: "Q(s,a) ← Q(s,a) + α · (target − Q(s,a))")
                    ])
                ),
                .init(
                    title: "When to use",
                    kind: .bullets([
                        "Small discrete spaces where you want stable learning.",
                        "Often safer than Q-Learning in stochastic dynamics."
                    ])
                )
            ]
        )
    )
    
    static let dqn = AlgorithmLearnItem(
        id: "dqn",
        title: "DQN",
        subtitle: "Neural network • Value-based • Discrete actions",
        icon: "network",
        color: .orange,
        model: EnvironmentInfoTabModel(
            title: "Deep Q-Network (DQN)",
            subtitle: "Value-based • Discrete actions",
            overview: "DQN replaces the tabular Q(s, a) with a neural network Qθ(s, a). It uses experience replay and a target network to stabilize training.",
            sections: [
                .init(
                    title: "Core pieces",
                    kind: .bullets([
                        "Q-network: predicts Q-values for each action.",
                        "Replay buffer: sample past transitions to reduce correlation.",
                        "Target network: a lagged copy used to compute stable targets."
                    ])
                ),
                .init(
                    title: "Update target",
                    kind: .keyValues([
                        .init(label: "Target", value: "r + γ · max_a′ Q_target(s′, a′)")
                    ])
                ),
                .init(
                    title: "When to use",
                    kind: .bullets([
                        "Discrete actions with continuous observations (CartPole, MountainCar, Acrobot, LunarLander)."
                    ])
                ),
                .init(
                    title: "Common knobs",
                    kind: .bullets([
                        "Learning rate, γ, ε schedule.",
                        "Batch size, replay buffer size.",
                        "Target update frequency, warmup steps."
                    ])
                )
            ]
        )
    )
    
    static let sac = AlgorithmLearnItem(
        id: "sac",
        title: "SAC",
        subtitle: "Actor-critic • Maximum entropy • Continuous actions",
        icon: "waveform.path.ecg",
        color: .indigo,
        model: EnvironmentInfoTabModel(
            title: "Soft Actor-Critic (SAC)",
            subtitle: "Actor-critic • Continuous actions",
            overview: "SAC learns a stochastic policy (actor) and Q-functions (critics). It maximizes reward while encouraging exploration via an entropy term (maximum entropy RL).",
            sections: [
                .init(
                    title: "Core pieces",
                    kind: .bullets([
                        "Actor: outputs a distribution over actions.",
                        "Critics: estimate Q(s, a) (often an ensemble).",
                        "Entropy term: encourages exploration and robustness."
                    ])
                ),
                .init(
                    title: "When to use",
                    kind: .bullets([
                        "Continuous action control (Pendulum, MountainCarContinuous, LunarLanderContinuous)."
                    ])
                ),
                .init(
                    title: "Common knobs",
                    kind: .bullets([
                        "Learning rate, γ (discount), τ (target smoothing).",
                        "α (entropy weight): higher means more exploration.",
                        "Batch size, buffer size, warmup steps."
                    ])
                )
            ]
        )
    )
}


