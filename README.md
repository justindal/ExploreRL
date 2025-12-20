# ExploreRL

ExploreRL is a native Swift app for iOS and macOS that lets you visualize and experiment with reinforcement learning (RL). The project uses [Gymnazo](https://github.com/justindal/Gymnazo) (a Swift port of Gymnasium) for environments and [MLX Swift](https://github.com/ml-explore/mlx-swift/) to leverage Apple Silicon and to implement reinforcement learning algorithms.

## Features

- **Train** RL agents on Gymnasium environments
- **Evaluate** saved agents without further training
- **Visualize** agent behavior, rewards, and learning metrics in real time
- **Save/Load** trained agents with hyperparameters and weights
- **Import/Export** saved agents (share policies / Q-tables)
- **Adjust** hyperparameters (learning rate, gamma, epsilon, batch size, etc.)

## Supported Environments

| Environment             | Category        | Algorithm          | Action Space |
| ----------------------- | --------------- | ------------------ | ------------ |
| Frozen Lake             | Toy Text        | Q-Learning / SARSA | Discrete(4)  |
| Blackjack               | Toy Text        | Q-Learning / SARSA | Discrete(2)  |
| Taxi                    | Toy Text        | Q-Learning / SARSA | Discrete(6)  |
| Cliff Walking           | Toy Text        | Q-Learning / SARSA | Discrete(4)  |
| Cart Pole               | Classic Control | DQN                | Discrete(2)  |
| Mountain Car            | Classic Control | DQN                | Discrete(3)  |
| Mountain Car Continuous | Classic Control | SAC                | Box(1)       |
| Acrobot                 | Classic Control | DQN                | Discrete(3)  |
| Pendulum                | Classic Control | SAC                | Box(1)       |
| Lunar Lander            | Box2D           | DQN                | Discrete(4)  |
| Lunar Lander Continuous | Box2D           | SAC                | Box(2)       |


## Implemented Algorithms

- **Tabular**: Q-Learning, SARSA
- **Deep RL**: DQN (Deep Q-Network), SAC (Soft Actor-Critic)

## Project Structure

```
ExploreRL/
├── ExploreRL-iOS/           # iOS app target
├── ExploreRL-macOS/         # macOS app target
└── ExploreRL-AppShared/     # Shared code between platforms
    ├── Agents/              # RL algorithm implementations
    │   ├── DQN/             # Deep Q-Network agents
    │   ├── SAC/             # Soft Actor-Critic agents
    │   ├── Tabular/         # Q-Learning, SARSA
    │   └── Utils/           # Network utilities
    ├── Models/              # Data models and state
    ├── Services/            # Agent storage and persistence
    ├── ViewModels/          # Environment runners
    └── Views/               # SwiftUI views
        ├── Main/            # Main navigation
        ├── Library/         # Saved agents management
        ├── Train/           # Training landing page
        ├── Evaluate/        # Evaluation mode
        ├── Components/      # Shared UI components
        └── [Environment]/   # Per-environment views
```

## Getting Started

### Prerequisites

- macOS with Xcode 15+
- iOS 18+ / macOS 15+
- Apple Silicon (Intel not supported)

### Dependencies

- [MLX Swift](https://github.com/ml-explore/mlx-swift/) - Neural network training on Apple Silicon
- [Gymnazo](https://github.com/justindal/Gymnazo) - Swift port of Gymnasium environments and tools

### Run

1. Open the project in Xcode
2. Select `ExploreRL-iOS` or `ExploreRL-macOS` target and run.

## Using the App

### Training

1. Select an environment from the **Train** section
2. Configure hyperparameters in the settings panel
3. Start training and watch metrics update in real time
4. Save your trained agent to the Library

### Evaluation

1. Go to the **Evaluate** tab
2. Select a saved agent
3. Run evaluation episodes to test performance

### Library

- View all saved agents and their statistics
- Filter by environment type
- Sort by date, name, episodes, or reward
- Duplicate, rename, or delete agents

## Roadmap

- [x] FrozenLake with Q-Learning/SARSA
- [x] Blackjack with Q-Learning/SARSA
- [x] Taxi with Q-Learning/SARSA
- [x] CliffWalking with Q-Learning/SARSA
- [x] CartPole, MountainCar, Acrobot with DQN
- [x] Pendulum, MountainCarContinuous with SAC
- [x] LunarLander with DQN
- [x] LunarLanderContinuous with SAC
- [x] Save/load agents with weights
- [x] Evaluation mode
- [ ] Export training logs
- [ ] Other Gymnasium environments
- [ ] More algorithms (PPO, A2C, TD3)
- [ ] Experiment comparison view

## License

See [LICENSE](LICENSE) for details.

---
