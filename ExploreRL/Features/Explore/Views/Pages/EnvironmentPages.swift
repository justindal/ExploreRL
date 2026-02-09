import SwiftUI

// MARK: - Toy Text

struct FrozenLakePage: View {
    var body: some View {
        EnvironmentPage(
            title: "Frozen Lake",
            intro: "Navigate a frozen grid from Start (S) to Goal (G) without falling into Holes (H). The ice can be slippery, adding stochasticity to movement.",
            observations: [
                "Discrete position on the grid (row × col)",
                "One-hot encoded or integer index"
            ],
            actions: [
                "4 discrete: Left, Down, Right, Up"
            ],
            rewards: [
                "+1 for reaching the Goal",
                "0 for all other transitions"
            ],
            tips: [
                "Start with non-slippery mode to debug your agent",
                "Slippery mode: the agent moves in the intended direction only ⅓ of the time",
                "Larger grids need more training steps"
            ]
        )
    }
}

struct BlackjackPage: View {
    var body: some View {
        EnvironmentPage(
            title: "Blackjack",
            intro: "A card game where the goal is to get as close to 21 as possible without going over, while beating the dealer.",
            observations: [
                "Player's current sum (1–31)",
                "Dealer's face-up card (1–10)",
                "Whether the player has a usable ace"
            ],
            actions: [
                "2 discrete: Hit (draw a card), Stand (stop)"
            ],
            rewards: [
                "+1 for winning",
                "−1 for losing or busting",
                "0 for a draw"
            ],
            tips: [
                "Good starter for tabular methods due to small state space",
                "The optimal policy is well-known, making it easy to verify"
            ]
        )
    }
}

struct TaxiPage: View {
    var body: some View {
        EnvironmentPage(
            title: "Taxi",
            intro: "Drive a taxi on a 5×5 grid to pick up a passenger and drop them off at the correct destination.",
            observations: [
                "Discrete encoding of taxi row, column",
                "Passenger location (one of 4 spots or in taxi)",
                "Destination (one of 4 spots)"
            ],
            actions: [
                "6 discrete: North, South, East, West, Pickup, Dropoff"
            ],
            rewards: [
                "+20 for successful dropoff",
                "−1 per step (encourages efficiency)",
                "−10 for illegal pickup or dropoff"
            ],
            tips: [
                "Dense negative reward makes progress easy to track",
                "Tabular methods work well here"
            ]
        )
    }
}

struct CliffWalkingPage: View {
    var body: some View {
        EnvironmentPage(
            title: "Cliff Walking",
            intro: "Walk from start to goal on a 4×12 grid. The bottom row (except start and goal) is a cliff; stepping on it ends the episode.",
            observations: [
                "Discrete position on the 4×12 grid"
            ],
            actions: [
                "4 discrete: Up, Right, Down, Left"
            ],
            rewards: [
                "−1 per step",
                "−100 for falling off the cliff"
            ],
            tips: [
                "Classic example where SARSA and Q‑Learning differ",
                "SARSA finds a safer path along the top",
                "Q‑Learning finds the optimal (risky) path along the cliff edge"
            ]
        )
    }
}

// MARK: - Classic Control

struct CartPolePage: View {
    var body: some View {
        EnvironmentPage(
            title: "Cart Pole",
            intro: "Keep a pole balanced upright on a cart that moves along a frictionless track.",
            observations: [
                "Cart position",
                "Cart velocity",
                "Pole angle",
                "Pole angular velocity"
            ],
            actions: [
                "2 discrete: Push Left, Push Right"
            ],
            rewards: [
                "+1 for every timestep the pole stays upright",
                "Episode ends if the pole tilts beyond ±12° or the cart leaves bounds"
            ],
            tips: [
                "Often solved in under 50k steps with DQN",
                "One of the simplest continuous-observation environments"
            ]
        )
    }
}

struct MountainCarPage: View {
    var body: some View {
        EnvironmentPage(
            title: "Mountain Car",
            intro: "An underpowered car must build momentum by rocking back and forth to reach the top of a hill. Also available as a continuous-action variant.",
            observations: [
                "Position along the track (−1.2 to 0.6)",
                "Velocity (−0.07 to 0.07)"
            ],
            actions: [
                "Discrete: Push Left, No Push, Push Right",
                "Continuous variant: force in [−1, 1]"
            ],
            rewards: [
                "−1 per step until reaching the goal",
                "Continuous variant: reward based on action cost"
            ],
            tips: [
                "Sparse reward makes exploration critical",
                "The car cannot drive directly up; it must swing"
            ]
        )
    }
}

struct AcrobotPage: View {
    var body: some View {
        EnvironmentPage(
            title: "Acrobot",
            intro: "A two-link robot arm hangs from a fixed point. Apply torque at the joint to swing the tip above a target height.",
            observations: [
                "cos(θ₁), sin(θ₁) for the first link",
                "cos(θ₂), sin(θ₂) for the second link",
                "Angular velocities of both joints"
            ],
            actions: [
                "3 discrete: apply torque −1, 0, or +1"
            ],
            rewards: [
                "−1 per step until the tip reaches the target height"
            ],
            tips: [
                "Similar sparse reward structure to Mountain Car",
                "Requires coordinated swinging motions"
            ]
        )
    }
}

struct PendulumPage: View {
    var body: some View {
        EnvironmentPage(
            title: "Pendulum",
            intro: "A pendulum starts hanging down. Apply torque to swing it upright and keep it balanced. A good first continuous-control problem.",
            observations: [
                "cos(θ): horizontal position of the tip",
                "sin(θ): vertical position of the tip",
                "Angular velocity"
            ],
            actions: [
                "1 continuous: torque in [−2, 2]"
            ],
            rewards: [
                "−(θ² + 0.1 θ̇² + 0.001 torque²)",
                "Penalizes angle, velocity, and effort"
            ],
            tips: [
                "Good starter environment for SAC",
                "Reward is always negative; closer to 0 is better"
            ]
        )
    }
}

// MARK: - Box2D

struct LunarLanderPage: View {
    var body: some View {
        EnvironmentPage(
            title: "Lunar Lander",
            intro: "Land a spacecraft between the flags on the landing pad. Available in discrete and continuous action variants.",
            observations: [
                "x and y position",
                "x and y velocity",
                "Angle and angular velocity",
                "Left and right leg contact (boolean)"
            ],
            actions: [
                "Discrete: 4 actions (nothing, left engine, main engine, right engine)",
                "Continuous: 2 values (main engine power, lateral engine power)"
            ],
            rewards: [
                "Shaped reward for moving toward the pad",
                "+100 for landing, −100 for crashing",
                "Fuel usage penalized per firing"
            ],
            tips: [
                "Shaped reward makes learning progress visible early",
                "DQN works well for discrete, SAC for continuous"
            ]
        )
    }
}

struct CarRacingPage: View {
    var body: some View {
        EnvironmentPage(
            title: "Car Racing",
            intro: "Drive around a procedurally generated track as fast as possible. The agent sees a top-down 96×96 RGB image. Also available as a discrete-action variant.",
            observations: [
                "96×96 RGB image (top-down view of the car and track)"
            ],
            actions: [
                "Continuous: steering [−1, 1], gas [0, 1], brake [0, 1]",
                "Discrete variant: 5 actions (steer left/right, gas, brake, nothing)"
            ],
            rewards: [
                "+1000/N per new track tile visited (N = total tiles)",
                "−0.1 per timestep"
            ],
            tips: [
                "Requires a CNN features extractor for pixel observations",
                "Frame stacking can help the agent perceive velocity"
            ]
        )
    }
}
