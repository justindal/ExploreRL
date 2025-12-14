//
//  LibrarySettingsView.swift
//

import SwiftUI

struct LibrarySettingsView: View {
    @State private var autoSync = true
    @State private var confirmations = true
    @State private var haptics = true
    @State private var analytics = false
    
    var body: some View {
        List {
            Section("General") {
                settingsRow(icon: "arrow.triangle.2.circlepath", title: "Auto-sync saved agents", toggle: $autoSync)
                settingsRow(icon: "exclamationmark.bubble", title: "Show confirmations", toggle: $confirmations)
                settingsRow(icon: "waveform.path", title: "Haptics & sounds", toggle: $haptics)
            }
            
            Section("Privacy") {
                settingsRow(icon: "chart.bar.xaxis", title: "Share anonymous analytics", toggle: $analytics)
                NavigationLink {
                    Text("Manage data export and deletion.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Data export")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section("Support") {
                NavigationLink {
                    Text("Contact support or view FAQs.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "questionmark.circle")
                        Text("Help & feedback")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .navigationTitle("Settings")
    }
    
    private func settingsRow(icon: String, title: String, toggle: Binding<Bool>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
            Toggle(isOn: toggle) {
                Text(title)
            }
        }
        .toggleStyle(.switch)
    }
}

#Preview {
    NavigationStack {
        LibrarySettingsView()
    }
}

