struct TrainNavigation {
    var path: [String] = []

    var selectedEnvironmentID: String? {
        get { path.last }
        set { path = newValue.map { [$0] } ?? [] }
    }
}
