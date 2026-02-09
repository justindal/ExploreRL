import SwiftUI

struct CodeBlock: View {
    let lines: [String]

    init(_ lines: [String]) {
        self.lines = lines
    }

    init(_ text: String) {
        self.lines = text.components(separatedBy: "\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.system(.callout, design: .monospaced))
            }
        }
        .textSelection(.enabled)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
