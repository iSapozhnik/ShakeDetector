# ShakeDetector

🌋 A lightweight Swift package for detecting mouse shake gestures on macOS.

## Features
- 🎯 Mouse shake detection with configurable sensitivity
- ⚡️ High performance with minimal CPU usage
- ↔️ Horizontal and vertical shake detection
- 🎚️ Adjustable detection parameters
- ⏱️ Built-in configurable debouncing to prevent multiple triggers
- 🛡️ Memory-safe implementation with proper cleanup
- 💻 Pure Swift implementation

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:
```swift
dependencies: [
    .package(url: "https://github.com/iSapozhnik/ShakeDetector", from: "1.0.0")
]
```

## Usage

### Basic Setup ⚡️
```swift
import ShakeDetector

// Initialize with default settings
let detector = ShakeDetector()

// Or initialize with custom settings
let configuredDetector = ShakeDetector(
    sensitivity: .high,
    debouncePeriod: 0.35  // in seconds
)

// Set up shake handler
detector.onShake {
    print("Shake detected!")
}
```

### Sensitivity Settings 🎚️
```swift
// Available options: .high, .medium, .low, .custom
detector.setSensitivity(.high)

// Custom sensitivity
detector.setSensitivity(.custom(
    minimumVelocityThreshold: 500,
    minimumDirectionChanges: 4,
    detectionWindow: 0.75
))
```

### Sensitivity Levels 📊

| Level  | Velocity | Direction Changes | Detection Window |
|--------|----------|------------------|------------------|
| High   | 400      | 3                | 0.5s            |
| Medium | 600      | 4                | 0.75s           |
| Low    | 800      | 5                | 1.0s            |

### Control 🎮
```swift
// Stop monitoring
detector.stopMonitoring()

// Resume monitoring
detector.startMonitoring()
```

## Requirements 🔧
- macOS 10.12+
- Swift 5.4+

## License 📝

This project is available under the MIT license. See the LICENSE file for more info.

## Contributing 🤝

Contributions are welcome! Please feel free to submit a Pull Request.
