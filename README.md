# ShakeDetector

🌋 A lightweight and customizable mouse shake detection library for macOS applications.

## Features

- 🎯 Detects mouse shake gestures in both horizontal and vertical directions
- ⚡️ High performance with minimal CPU usage
- 🎚️ Adjustable sensitivity levels
- ⏱️ Configurable debounce period
- 🛡️ Memory-safe implementation with proper cleanup
- 💻 Pure Swift implementation

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:
```swift
dependencies: [
    .package(url: "https://github.com/isapozhnik/ShakeDetector.git", from: "1.0.0")
]
```

## Usage

### Basic Implementation
```swift
import ShakeDetector

class ViewController {
    private let shakeDetector = ShakeDetector()
    func setupShakeDetection() {
        // Set up shake handler
        shakeDetector.onShake = { [weak self] in
            print("Shake detected!")
            // Handle shake event
        }
    }
}
```

### Customizing Sensitivity
```swift
// Available sensitivity levels: .high, .medium, .low
shakeDetector.setSensitivity(.medium)
```

### Adjusting Debounce Period
```swift
// Set debounce period in seconds
shakeDetector.setDebouncePeriod(0.5)
```

### Manual Control
```swift
// Start monitoring (automatically called after initialization)
shakeDetector.startMonitoring()
// Stop monitoring
shakeDetector.stopMonitoring()
```


## Configuration

The ShakeDetector can be initialized with custom sensitivity and debounce period:
```swift
let detector = ShakeDetector1(
    sensitivity: .medium, // Default
    debouncePeriod: 0.5 // Default: 0.5 seconds
)
```

### Sensitivity Levels

| Level  | Velocity Threshold | Direction Changes | Detection Window |
|--------|-------------------|-------------------|------------------|
| High   | 400              | 3                 | 0.5s            |
| Medium | 600              | 4                 | 0.75s           |
| Low    | 800              | 5                 | 1.0s            |

## Requirements

- macOS 10.12+
- Swift 5.4+

## License

This project is available under the MIT license. See the LICENSE file for more info.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
