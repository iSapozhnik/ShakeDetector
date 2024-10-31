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
        
        // Wait for debounce period plus a small buffer
        try await Task.sleep(for: .milliseconds(2000))
        
        #expect(shakeDetected == true, "Shake should be detected")
    }
    
    @Test func testSensitivitySettings() async throws {
        let detector = ShakeDetector()
        var shakeDetected = false
        
        detector.onShake = {
            shakeDetected = true
        }
        
        // Test with low sensitivity - should not detect a small shake
        detector.setSensitivity(.low)
        let smallShake: [(CGFloat, CGFloat)] = [(100, 0), (-100, 0), (100, 0), (-100, 0)]  // Smaller movements
        simulateCustomShake(detector: detector, startPosition: .zero, movements: smallShake)
        try await Task.sleep(for: .milliseconds(600))
        #expect(shakeDetected == false, "Small shake should not be detected with low sensitivity")
        
        // Test with high sensitivity - should detect the small shake
        shakeDetected = false
        detector.setSensitivity(.high)
        simulateCustomShake(detector: detector, startPosition: .zero, movements: smallShake)
        try await Task.sleep(for: .milliseconds(600))
        #expect(shakeDetected == true, "Small shake should be detected with high sensitivity")
    }
    
    @Test func testDebouncePeriod() async throws {
        let detector = ShakeDetector(debouncePeriod: 0.5)
        var shakeCount = 0
        
        detector.onShake = {
            shakeCount += 1
        }
        
        // Simulate multiple shakes in quick succession
        let startPosition = CGPoint(x: 100, y: 100)
        simulateShakeGesture(detector: detector, startPosition: startPosition)
        
        // Wait a bit before second shake
        try await Task.sleep(for: .milliseconds(100))
        
        simulateShakeGesture(detector: detector, startPosition: startPosition)
        
        // Wait for debounce period plus a small buffer
        try await Task.sleep(for: .milliseconds(600))
        
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
    let movements: [(CGFloat, CGFloat)] = [
        (200, 0),    // Right
        (-400, 0),   // Left
        (400, 0),    // Right
        (-400, 0),   // Left
        (400, 0),    // Right
    ]
    
    var currentPosition = startPosition
    let baseTime: TimeInterval = 1000.0
    
    // Add initial position
    let initialEvent = MockNSEvent(
        locationInWindow: currentPosition,
        timestamp: baseTime
    )
    detector.processMouseEvent(initialEvent)
    
    for (index, movement) in movements.enumerated() {
        // Calculate new position
        currentPosition = CGPoint(
            x: currentPosition.x + movement.0,
            y: currentPosition.y + movement.1
        )
        
        // Create intermediate points to make movement more realistic
        let steps = 3  // Reduced steps for higher velocity
        let stepX = movement.0 / CGFloat(steps)
        let stepY = movement.1 / CGFloat(steps)
        let timeStep = 0.01  // Reduced time step for higher velocity
        
        for step in 0..<steps {
            let intermediatePosition = CGPoint(
                x: currentPosition.x - movement.0 + (stepX * CGFloat(step + 1)),
                y: currentPosition.y - movement.1 + (stepY * CGFloat(step + 1))
            )
            
            let event = MockNSEvent(
                locationInWindow: intermediatePosition,
                timestamp: baseTime + Double(index) * 0.05 + (Double(step) * timeStep)
            )
            
            detector.processMouseEvent(event)
            Thread.sleep(forTimeInterval: 0.005)  // Reduced sleep time
        }
    }
}

// Add this helper method for custom shake patterns
private func simulateCustomShake(detector: ShakeDetector, startPosition: CGPoint, movements: [(CGFloat, CGFloat)]) {
    var currentPosition = startPosition
    let baseTime: TimeInterval = 1000.0
    
    let initialEvent = MockNSEvent(
        locationInWindow: currentPosition,
        timestamp: baseTime
    )
    detector.processMouseEvent(initialEvent)
    
    for (index, movement) in movements.enumerated() {
        currentPosition = CGPoint(
            x: currentPosition.x + movement.0,
            y: currentPosition.y + movement.1
        )
        
        let steps = 3
        let stepX = movement.0 / CGFloat(steps)
        let stepY = movement.1 / CGFloat(steps)
        let timeStep = 0.01
        
        for step in 0..<steps {
            let intermediatePosition = CGPoint(
                x: currentPosition.x - movement.0 + (stepX * CGFloat(step + 1)),
                y: currentPosition.y - movement.1 + (stepY * CGFloat(step + 1))
            )
            
            let event = MockNSEvent(
                locationInWindow: intermediatePosition,
                timestamp: baseTime + Double(index) * 0.05 + (Double(step) * timeStep)
            )
            
            detector.processMouseEvent(event)
            Thread.sleep(forTimeInterval: 0.005)
        }
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

