# ExploreRL

ExploreRL is a SwiftUI app for iOS and macOS that lets you visualize and experiment with reinforcement learning (RL). The project uses [Gymnazo](https://github.com/justindal/Gymnazo) for environments and utilities, as well as [MLX Swift](https://github.com/ml-explore/mlx-swift/) to leverage Apple Silicon and to implement reinforcement learning algorithms.

## Features

- Train RL agents in classic environments on-device
- Evaluate saved agents without further training
- Visualize agent behavior, rewards, and learning metrics in real time
- Save/Load trained agents with hyperparameters and weights
- Import/Export saved agents (share policies / Q-tables)
- Adjust hyperparameters (learning rate, gamma, epsilon, batch size, etc.)
- View system info, performance benchmarks
- View educational pages for algorithms, environments, and RL concepts

## App Tabs

- Library: Browse, load, evaluate, import, export, and delete saved sessions
- Train: Configure environments and hyperparameters, then train with live charts/rendering
- Evaluate: Run saved agents in evaluation episodes without further learning
- Explore: In-app educational pages for algorithms, environments, and RL concepts
- Settings: System checks, benchmark tools, FAQ, import/export helpers, and app metadata

## Implemented Algorithms

- Q-Learning (tabular)
- SARSA (tabular)
- DQN
- SAC

Algorithm choices are filtered at runtime based on environment action/observation space compatibility.

## Environment Coverage

ExploreRL supports the following environments from Gymnazo:

- Toy Text: `FrozenLake`, `FrozenLake8x8`, `Blackjack`, `Taxi`, `CliffWalking`
- Classic Control: `CartPole`, `MountainCar`, `MountainCarContinuous`, `Acrobot`, `Pendulum`
- Box2D: `LunarLander`, `LunarLanderContinuous`, `CarRacing`, `CarRacingDiscrete`


## Session Persistence

Saved sessions include:

- Environment ID and environment settings
- Algorithm type and training hyperparameters
- Training state/metrics
- Algorithm checkpoints (weights plus metadata)

Import/export is supported through archive files with `.xrlsession` extension.

## Project Structure

```text
ExploreRL/
├── ExploreRL/
│   ├── Core/
│   ├── Root/
│   └── Features/
│       ├── Explore/
│       ├── Train/
│       ├── Evaluate/
│       ├── Library/
│       └── Settings/
├── ExploreRL.xcodeproj/
└── README.md
```

## Dependencies

- `Gymnazo`
- `mlx-swift`
- `swift-collections`
- `swift-numerics`

## Getting Started

### Prerequisites

- macOS with Xcode 16+
- Apple Silicon for MLX operations
- iOS 18+ / macOS 15+

> Note: Training performance will vary by device. Devices with newer hardware and more memory will have a better experience. ExploreRL was tested on the following devices:
> - MacBook Pro M4 Pro  (14 CPU, 20 GPU)
> - iPad Pro (M2)
> - iPhone 17 Pro (A17 Pro)

### Open and Run

1. Open `ExploreRL.xcodeproj` in Xcode.
2. Select the `ExploreRL` scheme.
3. Choose an iOS simulator or macOS destination.
4. Build and run.

### Command-Line Build

```bash
xcodebuild -scheme ExploreRL -destination "platform=macOS" build
```

## Typical Workflow

1. Open an environment in Train
2. Adjust environment and algorithm settings
3. Start training and watch metrics/rendering
4. Save a session to Library
5. Open the session in Evaluate for rollout checks
6. Import/export sessions as needed

## License

See [LICENSE](LICENSE).
