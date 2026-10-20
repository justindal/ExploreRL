import Foundation

@Observable
final class TrainingEvaluationViewModel {
    let evaluation = EvaluateViewModel()
    private(set) var snapshot: TrainingSnapshot?
    private(set) var isConfirmed = false
    private(set) var isSaving = false
    private(set) var errorMessage: String?
    var saveToLibrary = false
    var name = ""
    private var isClosed = false

    func prepare(using train: TrainViewModel, id: String) async {
        guard snapshot == nil, !isClosed else { return }
        errorMessage = nil
        do {
            let prepared = try await train.makeSnapshot(for: id)
            guard !isClosed, !Task.isCancelled else {
                SessionStorage.shared.discard(prepared)
                return
            }
            snapshot = prepared
            name = "\(id) - \(prepared.session.trainingState.currentTimestep.formatted()) steps"
        } catch is CancellationError {
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func confirm() async {
        guard let snapshot, !isSaving, !isConfirmed, !isClosed else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            if saveToLibrary { _ = try SessionStorage.shared.saveSnapshot(snapshot, name: name) }
            isConfirmed = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func close() async {
        isClosed = true
        await evaluation.finishEvaluation()
        if let snapshot { SessionStorage.shared.discard(snapshot) }
        snapshot = nil
    }
}
