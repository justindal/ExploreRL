import Gymnazo

struct EnvValueContract: Sendable {
    let observation: SpaceContract
    let action: SpaceContract

    static func load(id: String, options: EnvOptions) async throws -> EnvValueContract {
        let env = try await Gymnazo.makeValue(id, options: options)
        do {
            var generator = SeededGenerator(seed: 0)
            let observation = try env.observationSpace.sample(using: &generator)
            let action = try env.actionSpace.sample(using: &generator)
            let contract = EnvValueContract(
                observation: SpaceContract(
                    value: observation,
                    flatDimension: env.observationSpace.flatDimension
                ),
                action: SpaceContract(
                    value: action,
                    flatDimension: env.actionSpace.flatDimension
                )
            )
            await env.close()
            return contract
        } catch {
            await env.close()
            throw error
        }
    }
}

struct SpaceContract: Sendable {
    let kind: SpaceKind
    let flatDimension: Int?

    init(value: SpaceValue, flatDimension: Int?) {
        self.kind = SpaceKind(value)
        self.flatDimension = flatDimension
    }
}

indirect enum SpaceKind: Sendable {
    case discrete
    case continuous
    case multiDiscrete
    case multiBinary
    case tuple([SpaceKind])
    case dictionary([String: SpaceKind])
    case sequence([SpaceKind])
    case graph
    case text
    case scalar

    init(_ value: SpaceValue) {
        switch value {
        case .discrete:
            self = .discrete
        case .continuous, .floatTensor:
            self = .continuous
        case .multiDiscrete, .intTensor:
            self = .multiDiscrete
        case .multiBinary, .boolTensor:
            self = .multiBinary
        case .tuple(let values):
            self = .tuple(values.map(SpaceKind.init))
        case .dictionary(let values):
            self = .dictionary(values.mapValues(SpaceKind.init))
        case .sequence(let values):
            self = .sequence(values.map(SpaceKind.init))
        case .graph:
            self = .graph
        case .text:
            self = .text
        case .bool, .double:
            self = .scalar
        }
    }

    var isDiscrete: Bool {
        if case .discrete = self { return true }
        return false
    }

    var isContinuous: Bool {
        if case .continuous = self { return true }
        return false
    }

    var isTabular: Bool {
        switch self {
        case .discrete:
            return true
        case .tuple(let values):
            return values.allSatisfy(\.isDiscrete)
        default:
            return false
        }
    }
}
