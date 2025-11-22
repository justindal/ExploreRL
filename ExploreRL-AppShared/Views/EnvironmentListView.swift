//
//  EnvironmentListView.swift
//

import SwiftUI

struct EnvironmentListView: View {
    var body: some View {
        NavigationSplitView {
            List {
                Section("Toy Text") {
                    NavigationLink {
                        FrozenLakeView()
                    } label: {
                        Label("Frozen Lake", systemImage: "snowflake")
                    }
                }
                
                Section("Classic Control") {
                    Label("Cart Pole (Coming Soon)", systemImage: "cart")
                        .foregroundStyle(.secondary)
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
}

#Preview {
    EnvironmentListView()
}

