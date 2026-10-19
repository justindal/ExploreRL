import Foundation

extension TrainViewModel {
    func setTrainingActive(_ isActive: Bool) {
        isTrainingActive = isActive
        guard !isActive else { return }

        for (id, task) in trainingTasks {
            trainingTimings[id]?.pause(at: .now)
            updateTrainingState(for: id) {
                $0.status = .paused
                $0.statusMessage = "Paused when the app became inactive. Resume to continue."
            }
            task.cancel()
        }
    }
}
