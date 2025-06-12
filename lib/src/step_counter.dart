import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background/flutter_background.dart';

class KalmanFilter {
  double q, r, x, p, k;
  KalmanFilter({
    this.q = 0.001,
    this.r = 0.1,
    this.x = 0.0,
    this.p = 1.0,
    this.k = 0.0,
  });

  double filter(double measurement) {
    p += q;
    k = p / (p + r);
    x += k * (measurement - x);
    p *= (1 - k);
    return x;
  }
}

class StepCounter {
  static final StepCounter _instance = StepCounter._internal();
  factory StepCounter() => _instance;
  StepCounter._internal();

  // smoothing & detection
  final KalmanFilter _kalman = KalmanFilter();
  final List<double> _buffer = [];
  final int _bufferSize = 6;
  final double upperThr = 11.5;
  final double lowerThr = 9.0;
  final int _minDelayMs = 300;

  int _steps = 0;
  DateTime _lastStepTime = DateTime.now().subtract(Duration(seconds: 1));
  bool _stepDetected = false;

  // user data
  double _userWeightKg = 70;
  double _userHeightM = 1.75;
  late double _strideLengthM;

  DateTime? _startTime;
  StreamSubscription<AccelerometerEvent>? _sub;
  final _stepCtrl = StreamController<int>.broadcast();

  Stream<int> get stepStream => _stepCtrl.stream;
  int get currentStep => _steps;

  double get caloriesBurned {
    final dist = _steps * _strideLengthM;
    return _userWeightKg * 0.57 * (dist / 1000);
  }

  double get walkingSpeedKmh {
    if (_startTime == null) return 0;
    final seconds = DateTime.now().difference(_startTime!).inSeconds;
    if (seconds == 0) return 0;
    final dist = _steps * _strideLengthM;
    return dist / seconds * 3.6;
  }

  Future<void> init({
    required double weightKg,
    required double heightMeters,
  }) async {
    _userWeightKg = weightKg;
    _userHeightM = heightMeters;
    _strideLengthM = _userHeightM * 0.415;
    final prefs = await SharedPreferences.getInstance();
    _steps = prefs.getInt('step_count') ?? 0;
    _stepCtrl.add(_steps);
  }

  Future<void> _saveSteps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('step_count', _steps);
  }

  double _movingAvg(double v) {
    _buffer.add(v);
    if (_buffer.length > _bufferSize) {
      _buffer.removeAt(0);
    }
    return _buffer.reduce((a, b) => a + b) / _buffer.length;
  }

  Future<void> start() async {
    // enable background
    final ok = await FlutterBackground.initialize(
      androidConfig: const FlutterBackgroundAndroidConfig(
        notificationTitle: "Step Counter Running",
        notificationText: "Tracking steps in background",
        notificationImportance: AndroidNotificationImportance.normal,
      ),
    );
    if (ok) {
      await FlutterBackground.enableBackgroundExecution();
    }

    _startTime = DateTime.now();
    _sub = accelerometerEventStream().listen((event) {
      final now = DateTime.now();
      final rawMag = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      final smooth = _kalman.filter(_movingAvg(rawMag));
      final dt = now.difference(_lastStepTime).inMilliseconds;

      if (smooth > upperThr &&
          !_stepDetected &&
          dt > _minDelayMs) {
        _steps++;
        _lastStepTime = now;
        _stepDetected = true;
        _stepCtrl.add(_steps);
        _saveSteps();
      } else if (smooth < lowerThr) {
        _stepDetected = false;
      }
    });
  }

  Future<void> stop() async {
    await _sub?.cancel();
    if (FlutterBackground.isBackgroundExecutionEnabled) {
      await FlutterBackground.disableBackgroundExecution();
    }
  }

  Future<void> reset() async {
    _steps = 0;
    _stepCtrl.add(_steps);
    await _saveSteps();
  }
}
