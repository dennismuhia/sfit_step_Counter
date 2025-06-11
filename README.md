# Step Counter

A simple Flutter package to count steps using device accelerometer.

## Features
- Count steps using `sensors_plus`
- Provides live step count stream
- Simple API: `start()`, `stop()`, `reset()`

## Getting Started

```dart
final counter = StepCounter();
counter.start();
counter.stepStream.listen((steps) {
  print("Steps: $steps");
});




### 2. `CHANGELOG.md`
```md
## 0.0.1

- Initial release with step counting support.
MIT License

Copyright (c) 2025 [Your Name]

Permission is hereby granted...
