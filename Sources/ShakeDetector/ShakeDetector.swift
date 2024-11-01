import Foundation
import Cocoa

public class ShakeDetector {
    // MARK: - Properties
    
    /// Closure to be executed when shake is detected
    private var onShakeHandler: (() -> Void)?
    
    /// Minimum velocity required to consider movement as shake (pixels per second)
    private var minimumVelocityThreshold: CGFloat
    
    /// Minimum number of direction changes required to detect shake
    private var minimumDirectionChanges: Int
    
    /// The maximum duration (in seconds) within which a shake gesture must be completed.
    /// If the required number of direction changes are not detected within this window,
    /// the gesture detection resets. This helps prevent false positives from slow,
    /// unintentional mouse movements.
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
    
    /// Time when the first movement in current gesture was detected
    private var gestureStartTime: TimeInterval?
    
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
    /// Initializes a new ShakeDetector instance with the specified sensitivity and debounce period.
    ///
    /// - Parameters:
    ///   - sensitivity: The sensitivity level for shake detection. Defaults to `.medium`.
    ///   - debouncePeriod: The debounce period for shake detection. Defaults to `0.5` seconds.
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
        case .custom(let minimumVelocityThreshold, let minimumDirectionChanges, let detectionWindow):
            self.minimumVelocityThreshold = minimumVelocityThreshold
            self.minimumDirectionChanges = minimumDirectionChanges
            self.detectionWindow = detectionWindow
        }
    }
    
    // MARK: - Public API

    /// Sets the handler for shake detection.
    public func onShake(_ handler: @escaping () -> Void) {
        onShakeHandler = handler
    }

    /// The sensitivity level for shake detection.
    public enum ShakeSensitivity {
        /// High sensitivity.
        case high
        /// Medium sensitivity.
        case medium
        /// Low sensitivity.
        case low
        /// Custom sensitivity.
        case custom(
            minimumVelocityThreshold: CGFloat,
            minimumDirectionChanges: Int,
            detectionWindow: TimeInterval
        )
    }
    
    /// Sets the sensitivity level for shake detection.
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
        case .custom(let minimumVelocityThreshold, let minimumDirectionChanges, let detectionWindow):
            self.minimumVelocityThreshold = minimumVelocityThreshold
            self.minimumDirectionChanges = minimumDirectionChanges
            self.detectionWindow = detectionWindow
        }
    }
    
    /// Sets the debounce period for shake detection.
    public func setDebouncePeriod(_ period: TimeInterval) {
        debouncePeriod = period
        // Update debouncer with new period
        debouncer = Debouncer(delay: period)
    }
    
    /// Starts monitoring for mouse movements.
    public func startMonitoring() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.processMouseEvent(event)
        }
    }
    
    /// Stops monitoring for mouse movements.
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
        
        // Start new gesture detection window if this is first movement or previous window expired
        if gestureStartTime == nil || (currentTime - gestureStartTime!) > detectionWindow {
            gestureStartTime = currentTime
            recentMovements.removeAll()
            directionChanges = 0
            previousDirection = nil
        }
        
        // Add current movement to recent movements
        recentMovements.append((position: currentPosition, timestamp: currentTime))
        
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
                    
                    // Check if we're still within detection window
                    if currentTime - gestureStartTime! <= detectionWindow {
                        // Check for direction change
                        if let previousDirection = previousDirection {
//                            print("Previous: \(previousDirection), Current: \(currentDirection), Velocity: \(velocity), Threshold: \(minimumVelocityThreshold)")
                            
                            if previousDirection != currentDirection &&
                                previousDirection.isHorizontal == currentDirection.isHorizontal &&
                                velocity >= minimumVelocityThreshold {
                                
                                directionChanges += 1
//                                print("Direction change detected! Count: \(directionChanges)")
                                
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
        }
        
        self.previousPosition = currentPosition
    }
    
    private func handleShakeDetected() {
        // Use debouncer instead of Timer
        debouncer.debounce { [weak self] in
            // Trigger shake handler
            self?.onShakeHandler?()
        }
        
        // Reset detection state
        resetDetection()
    }
    
    private func resetDetection() {
        recentMovements.removeAll()
        previousPosition = nil
        previousDirection = nil
        directionChanges = 0
        gestureStartTime = nil
    }
}
