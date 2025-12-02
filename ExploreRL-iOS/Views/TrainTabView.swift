//
//  TrainTabView.swift
//

import SwiftUI

struct TrainTabView: View {
    private var trainingState = TrainingState.shared
    @State private var navigationPath = NavigationPath()
    
    @State private var frozenLakeRunner = FrozenLakeRunner()
    @State private var cartPoleRunner = CartPoleRunner()
    @State private var mountainCarRunner = MountainCarRunner()
    @State private var mountainCarContinuousRunner = MountainCarContinuousRunner()
    @State private var acrobotRunner = AcrobotRunner()
    @State private var pendulumRunner = PendulumRunner()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
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
                
                ForEach(EnvironmentRegistry.groupedEnvironments, id: \.category) { group in
                    Section(group.category.rawValue) {
                        ForEach(group.environments) { envInfo in
                            Button { navigationPath.append(envInfo.type) } label: {
                                EnvironmentRowView(envInfo: envInfo)
                            }
                            .disabled(trainingState.isTraining && trainingState.activeEnvironment != envInfo.displayName)
                        }
                    }
                }
            }
            .navigationTitle("Train")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: EnvironmentType.self) { type in
                destinationView(for: type)
            }
        }
        .onAppear {
            if trainingState.isTraining, let envName = trainingState.activeEnvironment {
                if let envInfo = EnvironmentRegistry.environments.first(where: { $0.displayName == envName }) {
                    if navigationPath.isEmpty {
                        navigationPath.append(envInfo.type)
                    }
                }
            }
        }
        .onChange(of: navigationPath.count) { oldCount, newCount in
            if newCount == 0 && trainingState.isTraining {
                if let envName = trainingState.activeEnvironment,
                   let envInfo = EnvironmentRegistry.environments.first(where: { $0.displayName == envName }) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        navigationPath.append(envInfo.type)
                    }
                }
            }
        }
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

struct EnvironmentRowView: View {
    let envInfo: EnvironmentInfo
    var trainingState = TrainingState.shared
    
    private var isTrainingThis: Bool {
        trainingState.activeEnvironment == envInfo.displayName
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(envInfo.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: envInfo.icon)
                    .font(.title2)
                    .foregroundStyle(envInfo.accentColor)
            }
            .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(envInfo.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if isTrainingThis {
                        ProgressView().controlSize(.small)
                            .accessibilityLabel("Training in progress")
                    }
                }
                Text(envInfo.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(envInfo.displayName). \(envInfo.description)")
        .accessibilityHint(isTrainingThis ? "Currently training" : "Double tap to open")
    }
}

#Preview {
    TrainTabView()
}
