import Foundation
import Cocoa

public class ShakeDetector {
    // MARK: - Properties
    
    /// Closure to be executed when shake is detected
    public var onShake: (() -> Void)?
    
    /// Minimum velocity required to consider movement as shake (pixels per second)
    private var minimumVelocityThreshold: CGFloat
    
    /// Minimum number of direction changes required to detect shake
    private var minimumDirectionChanges: Int
    
    /// Time window to detect shake gesture (in seconds)
    private var detectionWindow: TimeInterval
    
    /// Cooldown period between shake detections (in seconds)
    private var debouncePeriod: TimeInterval
    
    /// Timer to track detection window
    private var detectionWorkItem: DispatchWorkItem?
    
    /// Array to store recent mouse movements
    private var recentMovements: [(position: CGPoint, timestamp: TimeInterval)] = []
    
    /// Previous mouse position
    private var previousPosition: CGPoint?
    
    /// Previous movement direction
    private var previousDirection: MovementDirection?
    
    /// Direction changes counter
    private var directionChanges = 0
    
    /// Minimum movement threshold (pixels)
    private let minimumMovementThreshold: CGFloat = 5.0
    
    // Add debouncer property
    private lazy var debouncer: Debouncer = {
        Debouncer(delay: debouncePeriod)
    }()
    
    private var monitor: Any?
    
    // MARK: - Types
    
    private enum MovementDirection {
        case left, right, up, down
        
        var isHorizontal: Bool {
            switch self {
            case .left, .right: return true
            case .up, .down: return false
            }
        }
    }
    
    // MARK: - Initialization
    
    public init(sensitivity: ShakeSensitivity = .medium, debouncePeriod: TimeInterval = 0.5) {
        self.debouncePeriod = debouncePeriod
        
        switch sensitivity {
        case .high:
            minimumVelocityThreshold = 400
            minimumDirectionChanges = 3
            detectionWindow = 0.5
        case .medium:
            minimumVelocityThreshold = 600
            minimumDirectionChanges = 4
            detectionWindow = 0.75
        case .low:
            minimumVelocityThreshold = 800
            minimumDirectionChanges = 5
            detectionWindow = 1.0
        }
        
        startMonitoring()
    }
    
    // MARK: - Public API
    
    public enum ShakeSensitivity {
        case high
        case medium
        case low
    }
    
    public func setSensitivity(_ sensitivity: ShakeSensitivity) {
        switch sensitivity {
        case .high:
            minimumVelocityThreshold = 400
            minimumDirectionChanges = 3
            detectionWindow = 0.5
        case .medium:
            minimumVelocityThreshold = 600
            minimumDirectionChanges = 4
            detectionWindow = 0.75
        case .low:
            minimumVelocityThreshold = 800
            minimumDirectionChanges = 5
            detectionWindow = 1.0
        }
    }
    
    public func setDebouncePeriod(_ period: TimeInterval) {
        debouncePeriod = period
        // Update debouncer with new period
        debouncer = Debouncer(delay: period)
    }
    
    public func startMonitoring() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.processMouseEvent(event)
        }
    }
    
    public func stopMonitoring() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        detectionWorkItem?.cancel()
        detectionWorkItem = nil
        debouncer.cancel()
        recentMovements.removeAll()
        previousPosition = nil
        previousDirection = nil
        directionChanges = 0
    }
    
    // MARK: - Private Methods
    
    internal func processMouseEvent(_ event: NSEvent) {
        guard monitor != nil else { return }
        
        let currentPosition = event.locationInWindow
        let currentTime = event.timestamp
        
        // Add current movement to recent movements
        recentMovements.append((position: currentPosition, timestamp: currentTime))
        
        // Remove old movements outside detection window
        recentMovements = recentMovements.filter {
            currentTime - $0.timestamp <= detectionWindow
        }
        
        // Process movement if we have enough data
        if let previousPosition = previousPosition {
            let deltaX = currentPosition.x - previousPosition.x
            let deltaY = currentPosition.y - previousPosition.y
            
            // Calculate velocity
            if let firstMovement = recentMovements.first {
                let timeElapsed = currentTime - firstMovement.timestamp
                let horizontalDistance = abs(currentPosition.x - firstMovement.position.x)
                let verticalDistance = abs(currentPosition.y - firstMovement.position.y)
                let horizontalVelocity = horizontalDistance / CGFloat(timeElapsed)
                let verticalVelocity = verticalDistance / CGFloat(timeElapsed)
                
                
                // Determine primary movement direction based on larger delta
                if abs(deltaX) >= minimumMovementThreshold || abs(deltaY) >= minimumMovementThreshold {
                    let currentDirection: MovementDirection
                    let velocity: CGFloat
                    
                    if abs(deltaX) > abs(deltaY) {
                        currentDirection = deltaX > 0 ? .right : .left
                        velocity = horizontalVelocity
                    } else {
                        currentDirection = deltaY > 0 ? .up : .down
                        velocity = verticalVelocity
                    }
                    
                    // Check for direction change
                    if let previousDirection = previousDirection {
//                        print("Previous: \(previousDirection), Current: \(currentDirection), Velocity: \(velocity), Threshold: \(minimumVelocityThreshold)")
                        
                        if previousDirection != currentDirection &&
                            previousDirection.isHorizontal == currentDirection.isHorizontal &&
                            velocity >= minimumVelocityThreshold {
                            
                            directionChanges += 1
//                            print("Direction change detected! Count: \(directionChanges)")
                            
                            // Check if we've reached the required number of direction changes
                            if directionChanges >= minimumDirectionChanges {
                                handleShakeDetected()
                            }
                        }
                    }
                    
                    // Only update previous direction if velocity is above threshold
                    if velocity >= minimumVelocityThreshold {
                        self.previousDirection = currentDirection
                    }
                }
            }
        }
        
        self.previousPosition = currentPosition
        
        // Reset detection if no shake detected within window
        detectionWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.resetDetection()
        }
        detectionWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + detectionWindow, execute: workItem)
    }
    
    private func handleShakeDetected() {
        // Use debouncer instead of Timer
        debouncer.debounce { [weak self] in
            // Trigger shake handler
            self?.onShake?()
        }
        
        // Reset detection state
        resetDetection()
    }
    
    private func resetDetection() {
        recentMovements.removeAll()
        previousPosition = nil
        previousDirection = nil
        directionChanges = 0
        detectionWorkItem?.cancel()
        detectionWorkItem = nil
    }
}
