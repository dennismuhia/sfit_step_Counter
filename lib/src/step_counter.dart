import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background/flutter_background.dart';

class StepCounter {
  static final StepCounter _instance = StepCounter._internal();
  factory StepCounter() => _instance;
  StepCounter._internal();

  int _steps = 0;
  StreamSubscription<AccelerometerEvent>? _subscription;
  final double _threshold = 12.0;
  final int _minDelayMs = 300;
  DateTime _lastStepTime = DateTime.now().subtract(const Duration(seconds: 1));

  bool _stepDetected = false;
  final StreamController<int> _stepStreamController =
      StreamController<int>.broadcast();

  Stream<int> get stepStream => _stepStreamController.stream;

  Future<void> _loadSteps() async {
    final prefs = await SharedPreferences.getInstance();
    _steps = prefs.getInt('step_count') ?? 0;
    _stepStreamController.add(_steps);
  }

  Future<void> _saveSteps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('step_count', _steps);
  }

  Future<void> enableBackgroundExecution() async {
    var androidConfig = const FlutterBackgroundAndroidConfig(
      notificationTitle: "Step Counter Active",
      notificationText: "Tracking steps in background",
      notificationImportance: AndroidNotificationImportance.normal,
      notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
    );

    final hasPermissions = await FlutterBackground.initialize(androidConfig: androidConfig);
    if (hasPermissions) {
      await FlutterBackground.enableBackgroundExecution();
    }
  }

  int start() {
    _loadSteps();

    _subscription = accelerometerEvents.listen((AccelerometerEvent event) {
      final now = DateTime.now();
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      if (magnitude > _threshold &&
          !_stepDetected &&
          now.difference(_lastStepTime).inMilliseconds > _minDelayMs) {
        _steps++;
        _lastStepTime = now;
        _stepDetected = true;
        _saveSteps();
        _stepStreamController.add(_steps);
      } else if (magnitude < _threshold - 2) {
        _stepDetected = false;
      }
    });

    return _steps;
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  void reset() {
    _steps = 0;
    _saveSteps();
    _stepStreamController.add(_steps);
  }

  int get currentStep => _steps;
}

// Usage Example in your app:
// final stepCounter = StepCounter();
// await stepCounter.enableBackgroundExecution();
// stepCounter.start();
