import Foundation
import MLX

actor ComputeCheck {
    func verify() throws -> Bool {
        try Task.checkCancellation()
        let lhs = MLXArray.ones([64, 64])
        let rhs = MLXArray.ones([64, 64])
        let result = MLX.sum(MLX.matmul(lhs, rhs, stream: .gpu))
        eval(result)
        let value = result.item(Float.self)
        try Task.checkCancellation()
        return value.isFinite && abs(value - 262_144) < 1
    }
}
