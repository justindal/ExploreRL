import SwiftUI

struct NumericSettingRow: View {
    let id: String
    let title: String
    @Binding var value: Double
    var range: ClosedRange<Double>?
    var step: Double?
    var wholeNumbers = false
    var usesFloatPrecision = false
    @Binding var validationErrors: Set<String>
    @State private var input = ""
    @FocusState private var isFocused: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                : AnyLayout(HStackLayout())
            layout {
                Text(title)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                if !dynamicTypeSize.isAccessibilitySize { Spacer() }
                TextField(title, text: $input)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                    .frame(minWidth: 88, maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : 140)
                    .focused($isFocused)
                    .accessibilityLabel(title)
                    #if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    #endif
            }
            if let range, range.lowerBound < range.upperBound {
                if let step {
                    Slider(value: $value, in: range, step: step, onEditingChanged: sliderEditing)
                        .accessibilityLabel(title)
                } else {
                    Slider(value: $value, in: range, onEditingChanged: sliderEditing)
                        .accessibilityLabel(title)
                }
            }
            if !input.isEmpty || isFocused, parsedValue == nil {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .onAppear { input = formatted(value) }
        .onChange(of: input) { _, _ in
            if let parsedValue {
                validationErrors.remove(validationKey)
                value = parsedValue
            } else {
                validationErrors.insert(validationKey)
            }
        }
        .onChange(of: value) { _, newValue in
            if !isFocused { input = formatted(newValue) }
        }
        .onChange(of: isFocused) { _, focused in
            if !focused, parsedValue != nil { input = formatted(value) }
        }
        .onDisappear { validationErrors.remove(validationKey) }
    }

    private var validationKey: String { "numeric:\(id)" }

    private var parsedValue: Double? {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let number = Double(text) ?? (try? Double(text, format: .number, lenient: false)),
            number.isFinite,
            !usesFloatPrecision || Float(number).isFinite,
            !wholeNumbers || Int(exactly: number) != nil,
            range?.contains(number) ?? true
        else { return nil }
        return number
    }

    private var validationMessage: String {
        let kind = wholeNumbers ? "a whole number" : "a number"
        if let range {
            return "Enter \(kind) from \(formatted(range.lowerBound)) to \(formatted(range.upperBound))."
        }
        return "Enter \(kind)."
    }

    private func formatted(_ number: Double) -> String {
        if wholeNumbers, let integer = Int(exactly: number) { return String(integer) }
        return usesFloatPrecision ? String(Float(number)) : String(number)
    }

    private func sliderEditing(_ editing: Bool) {
        if editing { isFocused = false }
        input = formatted(value)
    }
}
