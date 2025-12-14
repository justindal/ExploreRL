//
//  EnvironmentInfoTabView.swift
//

import SwiftUI

struct EnvironmentInfoTabModel {
    struct KV: Identifiable {
        let id = UUID()
        let label: String
        let value: String
    }
    
    struct Section: Identifiable {
        enum Kind {
            case keyValues([KV])
            case bullets([String])
            case paragraph(String)
        }
        
        let id = UUID()
        let title: String
        let kind: Kind
    }
    
    let title: String
    var subtitle: String? = nil
    var overview: String? = nil
    var sections: [Section] = []
}

struct EnvironmentInfoTabView: View {
    let model: EnvironmentInfoTabModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                
                if let overview = model.overview, !overview.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    ConfigurationContainer {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Overview", icon: "text.alignleft")
                            Text(overview)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                
                ForEach(model.sections) { section in
                    ConfigurationContainer {
                        sectionView(section)
                    }
                }
            }
            .frame(maxWidth: 700, alignment: .leading)
            .padding(20)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(model.title)
                .font(.title3)
                .bold()
            
            if let subtitle = model.subtitle, !subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private func sectionView(_ section: EnvironmentInfoTabModel.Section) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: section.title)
            
            switch section.kind {
            case .keyValues(let kvs):
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(kvs) { item in
                        EnvironmentInfoRow(label: item.label, value: item.value)
                    }
                }
                
            case .bullets(let bullets):
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(bullets, id: \.self) { line in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundStyle(.secondary)
                            Text(line)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                
            case .paragraph(let text):
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    EnvironmentInfoTabView(
        model: EnvironmentInfoTabModel(
            title: "Cart Pole — Info",
            subtitle: "Gymnasium-style reference",
            overview: "Balance a pole on a moving cart by applying left/right force.",
            sections: [
                .init(
                    title: "Spaces",
                    kind: .keyValues([
                        .init(label: "Observation Space", value: "Box(4,)"),
                        .init(label: "Action Space", value: "Discrete(2)")
                    ])
                ),
                .init(
                    title: "Episode end",
                    kind: .bullets([
                        "Termination: pole angle or cart position exceeds limits.",
                        "Truncation: max steps per episode (app setting)."
                    ])
                )
            ]
        )
    )
}


