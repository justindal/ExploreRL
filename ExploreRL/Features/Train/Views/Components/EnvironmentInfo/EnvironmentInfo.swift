//
//  EnvironmentInfo.swift
//  ExploreRL
//
//  Created by Justin Daludado on 2026-02-04.
//

import MLX
import Gymnazo
import SwiftUI

struct EnvironmentInfo: View {
    let env: (any Env)?

    var body: some View {
        if let env = env {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection(env: env)

                    if let description = env.spec?.description {
                        descriptionSection(description)
                    }

                    specSection(env: env)
                    spaceSection(title: "Action Space", space: env.actionSpace)
                    spaceSection(
                        title: "Observation Space",
                        space: env.observationSpace
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
        } else {
            ContentUnavailableView(
                "No Environment",
                systemImage: "questionmark.circle",
                description: Text("Environment data is not available.")
            )
        }
    }

    @ViewBuilder
    private func headerSection(env: any Env) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(env.spec?.displayName ?? env.spec?.id ?? "Unknown Environment")
                .font(.title)
                .fontWeight(.bold)

            if let category = env.spec?.category {
                Text(category.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Description", systemImage: "text.alignleft")
                .font(.headline)

            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func specSection(env: any Env) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Specifications", systemImage: "list.bullet.rectangle")
                .font(.headline)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                alignment: .leading,
                spacing: 12
            ) {
                if let threshold = env.spec?.rewardThreshold {
                    specItem(
                        label: "Reward Threshold",
                        value: String(format: "%.1f", threshold)
                    )
                }

                if let maxSteps = env.spec?.maxEpisodeSteps {
                    specItem(label: "Max Steps", value: "\(maxSteps)")
                }

                specItem(
                    label: "Deterministic",
                    value: env.spec?.nondeterministic == true ? "No" : "Yes"
                )

                if let version = env.spec?.version {
                    specItem(label: "Version", value: "v\(version)")
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func specItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
    }

    @ViewBuilder
    private func spaceSection(title: String, space: any Space) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(
                title,
                systemImage: title.contains("Action")
                    ? "arrow.right.circle" : "eye.circle"
            )
            .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                spaceTypeRow(space: space)

                if let shape = space.shape {
                    spaceRow(
                        label: "Shape",
                        value:
                            "[\(shape.map(String.init).joined(separator: ", "))]"
                    )
                }

                if let dtype = space.dtype {
                    spaceRow(label: "Data Type", value: dtypeName(dtype))
                }

                spaceSpecificInfo(space: space)
            }
            .padding()
            .background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: 12)
            )
        }
    }

    @ViewBuilder
    private func spaceTypeRow(space: any Space) -> some View {
        HStack {
            Text("Type")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(spaceTypeName(space))
                .font(.body)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.blue.opacity(0.1), in: Capsule())
        }
    }

    @ViewBuilder
    private func spaceRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.body.monospaced())
        }
    }

    @ViewBuilder
    private func spaceSpecificInfo(space: any Space) -> some View {
        if let discrete = space as? Discrete {
            spaceRow(label: "Values", value: "\(discrete.n)")
            if discrete.start != 0 {
                spaceRow(label: "Start Index", value: "\(discrete.start)")
            }
        } else if let box = space as? Box {
            spaceRow(
                label: "Range",
                value: "[\(formatBound(box.low)), \(formatBound(box.high))]"
            )
        } else if let tuple = space as? Tuple {
            spaceRow(label: "Sub-spaces", value: "\(tuple.spaces.count)")
            ForEach(Array(tuple.spaces.enumerated()), id: \.offset) { index, sub in
                spaceRow(label: "[\(index)]", value: subSpaceSummary(sub))
            }
        }
    }

    private func subSpaceSummary(_ space: any Space) -> String {
        if let d = space as? Discrete {
            return "Discrete(\(d.n))"
        } else if space is Box {
            let shape = space.shape.map { "[\($0.map(String.init).joined(separator: ", "))]" } ?? "?"
            return "Box \(shape)"
        } else {
            return spaceTypeName(space)
        }
    }

    private func formatBound(_ array: MLXArray) -> String {
        if array.size == 1 {
            return String(format: "%.2g", array.item(Float.self))
        }
        return "..."
    }

    private func spaceTypeName(_ space: any Space) -> String {
        switch space {
        case is Discrete:
            return "Discrete"
        case is Box:
            return "Box (Continuous)"
        case is MultiDiscrete:
            return "Multi-Discrete"
        case is MultiBinary:
            return "Multi-Binary"
        case is Dict:
            return "Dictionary"
        case is Tuple:
            return "Tuple"
        default:
            return String(describing: type(of: space))
        }
    }

    private func dtypeName(_ dtype: DType) -> String {
        switch dtype {
        case .bool: return "Bool"
        case .uint8: return "UInt8"
        case .uint16: return "UInt16"
        case .uint32: return "UInt32"
        case .uint64: return "UInt64"
        case .int8: return "Int8"
        case .int16: return "Int16"
        case .int32: return "Int32"
        case .int64: return "Int64"
        case .float16: return "Float16"
        case .float32: return "Float32"
        case .bfloat16: return "BFloat16"
        case .complex64: return "Complex64"
        case .float64:
            return "Float64"
        @unknown default: return "Unknown"
        }
    }

}
