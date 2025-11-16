# ExploreRL

ExploreRL is a native Swift app that runs on iOS and macOS to visualize and experiment with reinforcement learning (RL). The project ports Gymnasium-style environments to Swift and integrates SwiftUI and SpriteKit to run and visualize RL algorithms and training dynamics in real time. [MLX Swift](https://github.com/ml-explore/mlx-swift/) is used to leverage Apple Silicon's Metal and Unified Memory. Inspired by the work of OpenAI and the Farama Foundation's [Gymnasium](https://github.com/Farama-Foundation/Gymnasium/).

This project aims to:

- **Run** classic and custom RL environments on-device (iPhone, iPad, Mac).
- **Experiment** with different RL algorithms and hyperparameters.
- **Visualize** agent behavior, rewards, and learning metrics to help understand the RL process.

**Project layout (top-level):**

- `ExploreRL-iOS/` — iOS app target and UI.
- `ExploreRL-macOS/` — macOS app target and UI.
- `ExploreRLCore/` — Swift Package containing Gymnasium-style environments, spaces, and RL utilities.

**Features**

- Run multiple environments (discrete & continuous).
- Plug-and-play RL algorithms (training/inference modes).
- Adjustable hyperparameters (learning rate, gamma, batch size, etc.).
- Live plots: reward curve, loss, and performance metrics.

## Getting started

Prerequisites

- macOS with Xcode
- Metal Toolchain installed
- Swift MLX Package

Open and run

- Open the workspace or project in Xcode:

```bash
open ExploreRL.xcodeproj
```

- Select the `ExploreRL-iOS` or `ExploreRL-macOS` target and run on a simulator or device.

## Using the app

- Choose an environment to run. Environments live as part of the `ExploreRLCore` Swift package.
- Select an algorithm and configure hyperparameters via the UI controls.
- Start training or run in evaluation mode to visualize agent interaction and metrics.

## Configuration and experiments

- The app exposes common hyperparameters (learning rate, discount factor, epsilon schedules, batch size, etc.) and environment-specific settings.

## Structure

- **Device targets (`ExploreRL-iOS`, `ExploreRL-macOS`)**: Platform-specific views wired to shared logic.
- **ExploreRLCore**: Environment definitions, Spaces definitions, and RL utilities.
- **Trainer layer**: Integrates MLX Swift to implement algorithms, training loops, and logging.

## Planned Features

- [ ] Port additional Gymnasium environments (CartPole, MountainCar, Mujoco-style proxies).
- [ ] Save/load experiments for reproducibility.
- [ ] Add more algorithms (PPO, DQN variants, SAC, A2C).
    - device dependent
- [ ] Export training logs and model weights.
- [ ] Add an experiment scheduler and comparison view.


## Contact and support

If you want help porting a specific Gymnasium environment to Swift or integrating an algorithm with MLX Swift, open an issue describing the environment, required observation/action spaces, and any reference implementations.

---

_ExploreRL — interactive, native visual RL experiments on iOS & macOS._
