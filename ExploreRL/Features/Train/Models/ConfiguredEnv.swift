import Gymnazo
import MLX

struct ConfiguredEnv: Env {
    var base: any Env
    var resetSeed: UInt64?
    var resetOptions: EnvOptions

    var actionSpace: any Space { base.actionSpace }
    var observationSpace: any Space { base.observationSpace }

    var spec: EnvSpec? {
        get { base.spec }
        set { base.spec = newValue }
    }

    var renderMode: RenderMode? {
        get { base.renderMode }
        set { base.renderMode = newValue }
    }

    var unwrapped: any Env { base.unwrapped }

    mutating func step(_ action: MLXArray) throws -> Step {
        try base.step(action)
    }

    mutating func reset(seed: UInt64?, options: EnvOptions?) throws -> Reset {
        var merged = resetOptions
        if let options {
            for (key, value) in options.storage {
                merged[key] = value
            }
        }

        let resolvedSeed: UInt64?
        if let seed {
            resolvedSeed = seed
        } else if let storedSeed = resetSeed {
            resolvedSeed = storedSeed
            resetSeed = nil
        } else {
            resolvedSeed = nil
        }

        let payload = merged.isEmpty ? nil : merged
        return try base.reset(seed: resolvedSeed, options: payload)
    }

    func render() throws -> RenderOutput? {
        try base.render()
    }

    mutating func close() {
        base.close()
    }
}
