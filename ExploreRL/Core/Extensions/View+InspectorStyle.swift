import SwiftUI

private struct InspectorStyleKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isInspectorStyle: Bool {
        get { self[InspectorStyleKey.self] }
        set { self[InspectorStyleKey.self] = newValue }
    }
}
