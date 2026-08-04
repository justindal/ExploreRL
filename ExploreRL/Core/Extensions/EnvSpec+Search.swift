import Foundation
import Gymnazo

extension EnvSpec {
    func matchesSearch(_ query: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }

        return (displayName ?? name).localizedStandardContains(query)
            || id.localizedStandardContains(query)
            || (description?.localizedStandardContains(query) ?? false)
            || (category?.rawValue.localizedStandardContains(query) ?? false)
    }
}
