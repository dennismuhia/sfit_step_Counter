import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

class StepCounter {
  static final StepCounter _instance = StepCounter._internal();

  factory StepCounter() => _instance;

  StepCounter._internal();

  int _steps = 0;
  StreamSubscription? _subscription;
  double _threshold = 12.0; // adjust as needed

  final StreamController<int> _stepStreamController =
      StreamController<int>.broadcast();

  Stream<int> get stepStream => _stepStreamController.stream;

  void start() {
    _steps = 0;
    _subscription = accelerometerEvents.listen((AccelerometerEvent event) {
      final magnitude = (event.x * event.x +
              event.y * event.y +
              event.z * event.z)
          .sqrt();
      if (magnitude > _threshold) {
        _steps++;
        _stepStreamController.add(_steps);
      }
    });
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  void reset() {
    _steps = 0;
    _stepStreamController.add(_steps);
  }

  int get currentStep => _steps;
}
