import Foundation

final class Debouncer {
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    
    init(delay: TimeInterval) {
        self.delay = delay
    }
    
    func debounce(action: @escaping () -> Void) {
        workItem?.cancel()
        let newWorkItem = DispatchWorkItem { action() }
        workItem = newWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
    }
    
    func cancel() {
        workItem?.cancel()
        workItem = nil
    }
}
