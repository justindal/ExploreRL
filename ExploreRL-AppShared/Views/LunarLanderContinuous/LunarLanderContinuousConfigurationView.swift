//
//  LunarLanderContinuousConfigurationView.swift
//

import SwiftUI

struct LunarLanderContinuousConfigurationView: View {
    @Bindable var runner: LunarLanderContinuousRunner

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ConfigurationHeader {
                runner.resetToDefaults()
                runner.reset()
            }

            SpeedControlSection(
                renderEnabled: $runner.renderEnabled,
                targetFPS: $runner.targetFPS,
                turboMode: $runner.turboMode,
                isTraining: runner.isTraining,
                onRenderChange: {
                    runner.stopTraining()
                    runner.setupEnvironment()
                }
            )

            TrainingLimitsSection(
                episodesPerRun: $runner.episodesPerRun,
                maxStepsPerEpisode: $runner.maxStepsPerEpisode,
                isTraining: runner.isTraining,
                stepsRange: 100...2000,
                stepsStep: 100
            )

            SACHyperparametersSection(
                learningRate: $runner.learningRate,
                learningRateRange: 0.00001...0.01,
                gamma: $runner.gamma,
                tau: $runner.tau,
                tauRange: 0.001...0.1,
                batchSize: $runner.batchSize,
                isTraining: runner.isTraining,
                warmupSteps: $runner.warmupSteps,
                showWarmup: true,
                bufferSize: $runner.bufferSize,
                showBuffer: true
            )

            SACEntropySection(
                autoAlpha: $runner.autoAlpha,
                initAlpha: $runner.initAlpha,
                alphaLr: $runner.alphaLr,
                alpha: $runner.alpha,
                trainFreqSteps: $runner.trainFreqSteps,
                gradientStepsPerTrain: $runner.gradientStepsPerTrain,
                isTraining: runner.isTraining
            )

            networkSection
            lrScheduleSection

            SeedSection(
                useSeed: $runner.useSeed,
                seed: $runner.seed,
                isTraining: runner.isTraining
            )

            environmentSection
        }
        .padding()
        #if os(iOS)
            .background(Color(UIColor.secondarySystemBackground))
        #else
            .background(Color.gray.opacity(0.1))
        #endif
        .cornerRadius(10)
    }

    private var environmentSection: some View {
        DisclosureGroup("Environment") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Gravity")
                    Spacer()
                    TextField(
                        "-10.0",
                        value: $runner.envGravity,
                        format: .number
                    )
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                }

                Toggle("Enable Wind", isOn: $runner.enableWind)

                if runner.enableWind {
                    HStack {
                        Text("Wind Power")
                        Spacer()
                        TextField(
                            "15.0",
                            value: $runner.windPower,
                            format: .number
                        )
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    }

                    HStack {
                        Text("Turbulence Power")
                        Spacer()
                        TextField(
                            "1.5",
                            value: $runner.turbulencePower,
                            format: .number
                        )
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    }
                }

                Text("Wind adds random lateral forces during flight")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
            .onChange(of: runner.envGravity) { _, _ in
                runner.stopTraining()
                runner.setupEnvironment()
            }
            .onChange(of: runner.enableWind) { _, _ in
                runner.stopTraining()
                runner.setupEnvironment()
            }
            .onChange(of: runner.windPower) { _, _ in
                runner.stopTraining()
                runner.setupEnvironment()
            }
            .onChange(of: runner.turbulencePower) { _, _ in
                runner.stopTraining()
                runner.setupEnvironment()
            }
        }
        .disabled(runner.isTraining)
    }

    private var networkSection: some View {
        DisclosureGroup("Network") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Hidden 1")
                    Spacer()
                    TextField(
                        "400",
                        value: $runner.hiddenSize1,
                        format: .number
                    )
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 90)
                }
                HStack {
                    Text("Hidden 2")
                    Spacer()
                    TextField(
                        "300",
                        value: $runner.hiddenSize2,
                        format: .number
                    )
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 90)
                }
            }
            .padding(.top, 8)
            .onChange(of: runner.hiddenSize1) { _, _ in
                runner.stopTraining()
                runner.setupEnvironment()
            }
            .onChange(of: runner.hiddenSize2) { _, _ in
                runner.stopTraining()
                runner.setupEnvironment()
            }
        }
        .disabled(runner.isTraining)
    }

    private var lrScheduleSection: some View {
        DisclosureGroup("Learning Rate Schedule") {
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Linear LR Decay", isOn: $runner.useLinearLrSchedule)
                    .onChange(of: runner.useLinearLrSchedule) { _, _ in
                        runner.stopTraining()
                        runner.setupEnvironment()
                    }

                if runner.useLinearLrSchedule {
                    Toggle(
                        "Auto Total Timesteps (Episodes × Max Steps)",
                        isOn: $runner.autoLrScheduleTotalTimesteps
                    )
                    .onChange(of: runner.autoLrScheduleTotalTimesteps) { _, _ in
                        runner.stopTraining()
                        runner.setupEnvironment()
                    }

                    if runner.autoLrScheduleTotalTimesteps {
                        HStack {
                            Text("Total Timesteps (computed)")
                            Spacer()
                            Text("\(runner.effectiveLrScheduleTotalTimesteps)")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        HStack {
                            Text("Total Timesteps")
                            Spacer()
                            TextField(
                                "500000",
                                value: $runner.lrScheduleTotalTimesteps,
                                format: .number
                            )
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
        .disabled(runner.isTraining)
    }
}
