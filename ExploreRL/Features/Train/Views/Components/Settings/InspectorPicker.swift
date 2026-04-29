import SwiftUI

struct InspectorPicker<Page: Hashable>: View {
    struct Option: Identifiable {
        let value: Page
        let title: String

        var id: Page { value }
    }

    @Binding var selection: Page
    let options: [Option]

    var body: some View {
        Picker("Page", selection: $selection) {
            ForEach(options) { option in
                Text(option.title).tag(option.value)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .font(.subheadline.weight(.semibold))
        .controlSize(.large)
        .frame(maxWidth: .infinity)
    }
}
