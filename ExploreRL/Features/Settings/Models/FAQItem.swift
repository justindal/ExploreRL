import Foundation

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
    var hasAppFilesAction: Bool = false
}

extension FAQItem {
    static let all: [FAQItem] = [
        FAQItem(
            question: "What is ExploreRL?",
            answer: "ExploreRL is an interactive app for learning and experimenting with reinforcement learning. Train agents across various environments and watch them improve in real time."
        ),
        FAQItem(
            question: "What algorithms are supported?",
            answer: "Tabular methods (Q-Learning, SARSA), Deep Q-Network (DQN), Soft Actor-Critic (SAC), Proximal Policy Optimization (PPO), and Twin Delayed DDPG (TD3). PPO provides stable on-policy learning, while SAC and TD3 do better in complex continuous control tasks."
        ),
        FAQItem(
            question: "What is the Explore tab?",
            answer: "The Explore tab provides interactive, high-level overviews of reinforcement learning concepts and algorithms. You can toggle this tab on or off in Settings."
        ),
        FAQItem(
            question: "How do I train an agent?",
            answer: "Go to the Train tab, pick an environment, choose an algorithm, configure hyperparameters, and tap Start. You can watch the agent learn in real time and monitor metrics like reward and episode length."
        ),
        FAQItem(
            question: "How do I save and load sessions?",
            answer: "During or after training, use the save option to store your session. Saved sessions appear in the Library tab where you can load them back into training or evaluate their performance."
        ),
        FAQItem(
            question: "Can I export and share trained agents?",
            answer: "Yes. You can export individual sessions from the Library detail view or export all sessions at once from Settings. Archives can be shared and imported on another device."
        ),
        FAQItem(
            question: "What environments are available?",
            answer: "Classic control environments like CartPole, MountainCar, Acrobot, and Pendulum. Toy text environments like FrozenLake, Taxi, CliffWalking, and Blackjack. Box2D environments like LunarLander and CarRacing, including continuous variants."
        ),
        FAQItem(
            question: "Why is training slow?",
            answer: "Training speed depends on the algorithm, environment complexity, and device hardware. Deep learning algorithms (DQN, SAC, PPO, TD3) use MLX for GPU acceleration. Try reducing buffer size or batch size if training is too slow, or run a System Check in Settings to benchmark your device."
        ),
        FAQItem(
            question: "What is MLX?",
            answer: "MLX is Apple's machine learning framework optimized for Apple Silicon. ExploreRL uses MLX through the Gymnazo library to run neural network computations efficiently on your device."
        ),
        FAQItem(
            question: "Where are my files stored?",
            answer: "Local sessions and training checkpoints are saved natively on your device. You can easily export individual sessions as zip archives using the Share button.",
            hasAppFilesAction: true
        )
    ]
}
