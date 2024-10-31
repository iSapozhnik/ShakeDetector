import Testing
@testable import ShakeDetector
import CoreGraphics
import Cocoa

@Suite struct ShakeDetectorTests {
    
    @Test func testInitialization() throws {
        let detector = ShakeDetector()
        #expect(detector != nil)
    }
    
    @Test func testShakeDetection() async throws {
        let detector = ShakeDetector(sensitivity: .high)
        var shakeDetected = false
        
        detector.onShake = {
            shakeDetected = true
        }
        
        // Simulate shake gesture
        let startPosition = CGPoint(x: 100, y: 100)
        simulateShakeGesture(detector: detector, startPosition: startPosition)
        
        // Wait for debounce period
        try await Task.sleep(for: .milliseconds(1000))
        
        #expect(shakeDetected == true, "Shake should be detected")
    }
    
    @Test func testSensitivitySettings() throws {
        let detector = ShakeDetector()
        
        // Test changing sensitivity
        detector.setSensitivity(.high)
        detector.setSensitivity(.medium)
        detector.setSensitivity(.low)
    }
    
    @Test func testDebouncePeriod() async throws {
        let detector = ShakeDetector(debouncePeriod: 1.0)
        var shakeCount = 0
        
        detector.onShake = {
            shakeCount += 1
        }
        
        // Simulate multiple shakes in quick succession
        let startPosition = CGPoint(x: 100, y: 100)
        simulateShakeGesture(detector: detector, startPosition: startPosition)
        simulateShakeGesture(detector: detector, startPosition: startPosition)
        
        // Wait for debounce period
        try await Task.sleep(for: .milliseconds(1100))
        
        #expect(shakeCount == 1, "Multiple shakes within debounce period should only trigger once")
    }
    
    @Test func testStopMonitoring() throws {
        let detector = ShakeDetector()
        var shakeDetected = false
        
        detector.onShake = {
            shakeDetected = true
        }
        
        detector.stopMonitoring()
        
        let startPosition = CGPoint(x: 100, y: 100)
        simulateShakeGesture(detector: detector, startPosition: startPosition)
        
        #expect(shakeDetected == false, "Shake should not be detected after stopping monitoring")
    }
}

// MARK: - Helper Methods

private func simulateShakeGesture(detector: ShakeDetector, startPosition: CGPoint) {
    // Create mock mouse movements that simulate a shake gesture
    let movements: [(CGFloat, CGFloat)] = [
        (50, 0),   // Right
        (-50, 0),  // Left
        (50, 0),   // Right
        (-50, 0),  // Left
        (50, 0),   // Right
    ]
    
    var currentPosition = startPosition
    let baseTime = ProcessInfo.processInfo.systemUptime
    
    for (index, movement) in movements.enumerated() {
        currentPosition = CGPoint(
            x: currentPosition.x + movement.0,
            y: currentPosition.y + movement.1
        )
        
        // Create a mock NSEvent
        let event = MockNSEvent(
            locationInWindow: currentPosition,
            timestamp: baseTime + Double(index) * 0.1
        )
        
        // Process the mock event
        detector.processMouseEvent(event)
    }
}

// MARK: - Mock NSEvent

private class MockNSEvent: NSEvent {
    private let mockedLocationInWindow: CGPoint
    private let mockedTimestamp: TimeInterval
    
    init(locationInWindow: CGPoint, timestamp: TimeInterval) {
        self.mockedLocationInWindow = locationInWindow
        self.mockedTimestamp = timestamp
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var locationInWindow: CGPoint {
        return mockedLocationInWindow
    }
    
    override var timestamp: TimeInterval {
        return mockedTimestamp
    }
}
