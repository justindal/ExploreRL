//
//  InfoButton.swift
//

import SwiftUI

struct InfoButton: View {
    @Binding var isPresented: Bool
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        Button(action: { isPresented.toggle() }) {
            Image(systemName: "info.circle")
                .foregroundStyle(.blue)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isPresented) {
            TooltipContent(title: title, description: description, icon: icon)
        }
    }
}

struct TooltipContent: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                    .font(.title3)
                Text(title)
                    .font(.headline)
            }
            
            Divider()
            
            Text(description)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(width: 280)
        .presentationCompactAdaptation(.popover)
    }
}

