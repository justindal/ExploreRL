//
//  ExploreView.swift
//

import SwiftUI

struct ExploreView: View {
    @State private var selectedEnvironment: EnvironmentInfo?
    @State private var selectedAlgorithm: AlgorithmLearnItem?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // What is RL
                rlIntroSection
                
                // The RL Loop
                rlLoopSection
                
                // Key Concepts
                keyConceptsSection
                
                // Discrete vs Continuous
                discreteContinuousSection
                
                // Algorithm Categories
                rlTypesSection
                
                // Training Concepts
                trainingConceptsSection
                
                // Environments
                sectionHeader(title: "Environments", subtitle: "Environments from Gymnasium with different observation/action spaces.")
                environmentsSection
                
                // Algorithms
                sectionHeader(title: "Algorithms", subtitle: "Different algorithms suited for different problem types.")
                algorithmsSection
            }
            .frame(maxWidth: 1000, alignment: .leading)
            .padding(24)
        }
        .frame(maxWidth: .infinity)
        .sheet(item: $selectedEnvironment) { env in
            NavigationStack {
                EnvironmentInfoTabView(model: EnvironmentInfoTabModels.forLearn(type: env.type))
                    .navigationTitle(env.displayName)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { selectedEnvironment = nil }
                        }
                    }
            }
            #if os(macOS)
            .frame(minWidth: 500, minHeight: 400)
            #endif
        }
        .sheet(item: $selectedAlgorithm) { algo in
            NavigationStack {
                EnvironmentInfoTabView(model: algo.model)
                    .navigationTitle(algo.title)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { selectedAlgorithm = nil }
                        }
                    }
            }
            #if os(macOS)
            .frame(minWidth: 500, minHeight: 400)
            #endif
        }
    }
    
    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }
    
    private var rlIntroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundStyle(.purple)
                Text("What is Reinforcement Learning?")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            Text("Reinforcement Learning (RL) is a branch of machine learning where an agent learns to make decisions by interacting with an environment. The agent discovers what works through trial and error, receiving rewards or penalties based on its actions.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Text("RL is used in robotics, autonomous vehicles, recommendation systems, and other decision-making processes.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.purple.opacity(0.08))
        .cornerRadius(12)
    }
    
    private var rlLoopSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("The RL Loop")
                .font(.title3)
                .fontWeight(.bold)
            
            Text("At each time step, the agent and environment interact in a cycle (Markov Decision Process):")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 0) {
                ForEach(["Observe", "Act", "Reward", "Next"], id: \.self) { step in
                    Text(step)
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.primary.opacity(0.04))
                    
                    if step != "Next" {
                        Text("→")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 4)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.08))
        .cornerRadius(12)
    }
    
    private var keyConceptsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Concepts")
                .font(.title3)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                conceptRow("State", "What the agent observes at each step")
                conceptRow("Action", "Decision the agent makes")
                conceptRow("Reward", "Scalar feedback signal")
                conceptRow("Policy (π)", "Strategy mapping states to actions")
                conceptRow("Value V(s)", "Expected return from state s")
                conceptRow("Q-Value Q(s,a)", "Expected return for action a in state s")
                conceptRow("Episode", "One complete run from start to end")
                conceptRow("Discount (γ)", "How much future rewards matter (0–1)")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.06))
        .cornerRadius(12)
    }
    
    private func conceptRow(_ term: String, _ definition: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(term)
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(width: 100, alignment: .leading)
            Text(definition)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var discreteContinuousSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Action & State Spaces")
                .font(.title3)
                .fontWeight(.bold)
            
            Text("The type of action/state space determines which algorithms apply.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Discrete")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Finite choices (left, right, jump). Used by Q-Learning, SARSA, DQN.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Continuous")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Real-valued outputs (torque, throttle). Used by SAC, PPO, DDPG.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(Color.primary.opacity(0.03))
            .cornerRadius(8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cyan.opacity(0.06))
        .cornerRadius(12)
    }
    
    private var rlTypesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Algorithm Categories")
                .font(.title3)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                categoryRow("Value-Based", "Learn Q or V, derive policy (Q-Learning, DQN)")
                categoryRow("Policy-Based", "Learn policy directly (REINFORCE, PPO)")
                categoryRow("Actor-Critic", "Actor picks actions, critic evaluates (SAC, A2C)")
                categoryRow("On-Policy", "Learn from current policy (SARSA)")
                categoryRow("Off-Policy", "Learn from any data (Q-Learning, DQN, SAC)")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.indigo.opacity(0.06))
        .cornerRadius(12)
    }
    
    private func categoryRow(_ title: String, _ description: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var trainingConceptsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Training Concepts")
                .font(.title3)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                trainingItem("Episode", "Complete run start → end")
                trainingItem("Step", "Single action taken")
                trainingItem("Replay Buffer", "Stored (s,a,r,s') tuples")
                trainingItem("Target Network", "Lagged copy for stability")
                trainingItem("Batch Size", "Samples per update")
                trainingItem("Learning Rate", "Step size for updates")
                trainingItem("Warmup", "Random steps to fill buffer")
                trainingItem("ε-Greedy", "Random action with prob ε")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.06))
        .cornerRadius(12)
    }
    
    private func trainingItem(_ term: String, _ definition: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(term)
                .font(.caption)
                .fontWeight(.semibold)
            Text(definition)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var environmentsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(EnvironmentRegistry.groupedEnvironments, id: \.category) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text(group.category.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: 240), spacing: 8)], spacing: 8) {
                        ForEach(group.environments) { env in
                            Button {
                                selectedEnvironment = env
                            } label: {
                                HStack(spacing: 6) {
                                    Text(env.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.primary.opacity(0.04))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
    
    private var algorithmsSection: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: 240), spacing: 8)], spacing: 8) {
            ForEach(AlgorithmLearnModels.all) { algo in
                Button {
                    selectedAlgorithm = algo
                } label: {
                    HStack(spacing: 6) {
                        Text(algo.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.primary.opacity(0.04))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    ExploreView()
}
