import 'dart:async';
import 'dart:math';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background/flutter_background.dart';

const _STILL = 'stopped';
const _MOVING = 'walking';

class StepData {
  final int steps;
  final double calories;
  final double speedKmh;
  final String status;
  final DateTime time;

  StepData(this.steps, this.calories, this.speedKmh, this.status, this.time);
}

class StepCounter {
  static final StepCounter _instance = StepCounter._internal();
  factory StepCounter() => _instance;
  StepCounter._internal();

  static const EventChannel _stepDetectionChannel = EventChannel('step_detection');
  static const EventChannel _stepCountChannel = EventChannel('step_count');

  int _steps = 0;
  double _userWeightKg = 70;
  double _userHeightMeters = 1.75;
  late double _strideLengthMeters;
  DateTime? _startTime;

  String _status = _STILL;
  Timer? _statusTimer;

  final _stepStreamController = StreamController<StepData>.broadcast();
  Stream<StepData> get stepStream => _stepStreamController.stream;

  Future<void> init({required double weightKg, required double heightMeters}) async {
    _userWeightKg = weightKg;
    _userHeightMeters = heightMeters;
    _strideLengthMeters = _userHeightMeters * 0.415;
    final prefs = await SharedPreferences.getInstance();
    _steps = prefs.getInt('step_count') ?? 0;
  }

  Future<void> _saveSteps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('step_count', _steps);
  }

  double get caloriesBurned => _steps * _strideLengthMeters / 1000 * _userWeightKg * 0.57;

  double get walkingSpeedKmh {
    if (_startTime == null) return 0;
    final duration = DateTime.now().difference(_startTime!).inSeconds;
    if (duration == 0) return 0;
    final meters = _steps * _strideLengthMeters;
    return (meters / duration) * 3.6;
  }

  Future<void> start() async {
    final initialized = await FlutterBackground.initialize(
      androidConfig: const FlutterBackgroundAndroidConfig(
        notificationTitle: "Step Counter Running",
        notificationText: "Tracking your steps in the background",
        notificationImportance: AndroidNotificationImportance.normal,
      ),
    );
    if (initialized) {
      await FlutterBackground.enableBackgroundExecution();
    }

    _startTime = DateTime.now();

    if (Platform.isAndroid) {
      _startNativeListeners();
    } else {
      _startAccelerometerFallback();
    }
  }

  void _startNativeListeners() {
    _stepCountChannel.receiveBroadcastStream().listen((event) {
      _steps = event as int;
      _emitStepData();
      _saveSteps();
    });

    _stepDetectionChannel.receiveBroadcastStream().listen((event) {
      _handleStatus(event);
    });
  }

  void _startAccelerometerFallback() {
    accelerometerEventStream().listen((event) {
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (magnitude > 12.0) {
        _steps++;
        _handleStatus(1);
        _emitStepData();
        _saveSteps();
      }
    });
  }

  void _handleStatus(int event) {
    _statusTimer?.cancel();

    if (event == 1 && _status == _STILL) {
      _status = _MOVING;
    }

    _statusTimer = Timer(Duration(seconds: 2), () {
      _status = _STILL;
      _emitStepData();
    });
  }

  void _emitStepData() {
    _stepStreamController.add(
      StepData(_steps, caloriesBurned, walkingSpeedKmh, _status, DateTime.now()),
    );
  }

  Future<void> stop() async {
    _statusTimer?.cancel();
    _statusTimer = null;
    if (FlutterBackground.isBackgroundExecutionEnabled) {
      await FlutterBackground.disableBackgroundExecution();
    }
  }

  Future<void> reset() async {
    _steps = 0;
    _emitStepData();
    await _saveSteps();
  }

  int get currentStep => _steps;
}
