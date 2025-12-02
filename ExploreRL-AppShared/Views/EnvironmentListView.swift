//
//  EnvironmentListView.swift
//

import SwiftUI

struct EnvironmentListView: View {
    private var trainingState = TrainingState.shared
    @State private var showTrainingAlert = false
    
    @State private var frozenLakeRunner = FrozenLakeRunner()
    @State private var cartPoleRunner = CartPoleRunner()
    @State private var mountainCarRunner = MountainCarRunner()
    @State private var mountainCarContinuousRunner = MountainCarContinuousRunner()
    @State private var acrobotRunner = AcrobotRunner()
    @State private var pendulumRunner = PendulumRunner()
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(EnvironmentRegistry.groupedEnvironments, id: \.category) { group in
                    Section(group.category.rawValue) {
                        ForEach(group.environments) { envInfo in
                            environmentLink(for: envInfo)
                        }
                    }
                }
                
                if trainingState.isTraining, let env = trainingState.activeEnvironment {
                    Section {
                        HStack {
                            Image(systemName: "bolt.fill").foregroundStyle(.orange)
                            Text("Training \(env)...").foregroundStyle(.secondary)
                            Spacer()
                            ProgressView().controlSize(.small)
                        }
                    }
                }
                
                Section("Evaluate") {
                    NavigationLink {
                        EvaluationView()
                    } label: {
                        Label("Evaluation Mode", systemImage: "play.circle")
                    }
                    .disabled(trainingState.isTraining)
                }
                
                Section("Library") {
                    NavigationLink {
                        SavedAgentsView()
                    } label: {
                        Label("Saved Agents", systemImage: "books.vertical")
                    }
                    .disabled(trainingState.isTraining)
                }
            }
            .navigationTitle("ExploreRL")
            #if os(macOS)
            .navigationSplitViewColumnWidth(min: 200, ideal: 250)
            #endif
        } detail: {
            Text("Select an Environment")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private func environmentLink(for envInfo: EnvironmentInfo) -> some View {
        let isActive = trainingState.activeEnvironment == envInfo.displayName
        let isDisabled = trainingState.isTraining && !isActive
        
        NavigationLink {
            destinationView(for: envInfo.type)
        } label: {
            EnvironmentRow(
                name: envInfo.displayName,
                icon: envInfo.icon,
                color: envInfo.accentColor,
                isActive: isActive
            )
        }
        .disabled(isDisabled)
    }
    
    @ViewBuilder
    private func destinationView(for type: EnvironmentType) -> some View {
        switch type {
        case .frozenLake:
            FrozenLakeView(runner: frozenLakeRunner)
        case .cartPole:
            CartPoleView(runner: cartPoleRunner)
        case .mountainCar:
            MountainCarView(runner: mountainCarRunner)
        case .mountainCarContinuous:
            MountainCarContinuousView(runner: mountainCarContinuousRunner)
        case .acrobot:
            AcrobotView(runner: acrobotRunner)
        case .pendulum:
            PendulumView(runner: pendulumRunner)
        }
    }
}

private struct EnvironmentRow: View {
    let name: String
    let icon: String
    let color: Color
    let isActive: Bool
    
    var body: some View {
        HStack {
            Label(name, systemImage: icon)
                .foregroundStyle(color)
            if isActive {
                Spacer()
                ProgressView().controlSize(.small)
            }
        }
    }
}

#Preview {
    EnvironmentListView()
}
