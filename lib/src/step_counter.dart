// Enhanced Step Counter with ML, Cadence, Geofencing, and iOS support

import 'dart:async';
import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:geolocator/geolocator.dart';

const _STILL = 'stopped';
const _MOVING = 'walking';
const _RUNNING = 'running';

class StepData {
  final int steps;
  final double calories;
  final double speedKmh;
  final String status;
  final double cadence;
  final DateTime time;

  StepData(this.steps, this.calories, this.speedKmh, this.status, this.cadence, this.time);
}

class StepCounter {
  static final StepCounter _instance = StepCounter._internal();
  factory StepCounter() => _instance;
  StepCounter._internal();

  static const EventChannel _stepDetectionChannel = EventChannel('step_detection');
  static const EventChannel _stepCountChannel = EventChannel('step_count');

  int _steps = 0;
  List<DateTime> _stepTimestamps = [];
  double userWeightKg = 70;
  double userHeightMeters = 1.75;
  DateTime? _startTime;

  String _status = _STILL;
  Timer? _statusTimer;
  Timer? _geofenceTimer;

  final _stepStreamController = StreamController<StepData>.broadcast();
  Stream<StepData> get stepStream => _stepStreamController.stream;

  // Geofence (mock gym location)
  final double _gymLatitude = -1.2921;
  final double _gymLongitude = 36.8219;
  final double _geofenceRadiusMeters = 50.0;

  double get strideLengthMeters => userHeightMeters * 0.415;

  Future<void> init({required double weightKg, required double heightMeters}) async {
    userWeightKg = weightKg;
    userHeightMeters = heightMeters;
    final prefs = await SharedPreferences.getInstance();
    _steps = prefs.getInt('step_count') ?? 0;
  }

  Future<void> _saveSteps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('step_count', _steps);
  }

  double get caloriesBurned => _steps * strideLengthMeters / 1000 * userWeightKg * 0.57;

  double get walkingSpeedKmh {
    if (_startTime == null) return 0;
    final duration = DateTime.now().difference(_startTime!).inSeconds;
    if (duration == 0) return 0;
    final meters = _steps * strideLengthMeters;
    return (meters / duration) * 3.6;
  }

  double get cadence {
    if (_stepTimestamps.length < 2) return 0;
    final duration = _stepTimestamps.last.difference(_stepTimestamps.first).inMinutes;
    return duration == 0 ? 0 : (_stepTimestamps.length / duration);
  }

  Future<void> start() async {
    final initialized = await FlutterBackground.initialize(
      androidConfig: const FlutterBackgroundAndroidConfig(
        notificationTitle: "Step Counter Running",
        notificationText: "Tracking your steps in the background",
        notificationImportance: AndroidNotificationImportance.normal,
      ),
    );
    if (initialized) await FlutterBackground.enableBackgroundExecution();

    _startTime = DateTime.now();
    _startGeofenceMonitor();

    if (Platform.isAndroid) {
      _startNativeListeners();
    } else {
      _startAccelerometerFallback();
    }
  }

  void _startNativeListeners() {
    _stepCountChannel.receiveBroadcastStream().listen((event) {
      _steps = event as int;
      _stepTimestamps.add(DateTime.now());
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
        _stepTimestamps.add(DateTime.now());
        _handleStatus(1);
        _emitStepData();
        _saveSteps();
      }
    });
  }

  void _handleStatus(int event) {
    _statusTimer?.cancel();
    if (event == 1 && _status != _MOVING) {
      _status = _MOVING;
    }
    _statusTimer = Timer(Duration(seconds: 2), () {
      _status = _STILL;
      _emitStepData();
    });
  }

  void _emitStepData() {
    _stepStreamController.add(
      StepData(_steps, caloriesBurned, walkingSpeedKmh, _status, cadence, DateTime.now()),
    );
  }

  void _startGeofenceMonitor() {
    _geofenceTimer = Timer.periodic(Duration(seconds: 30), (_) async {
      final pos = await Geolocator.getCurrentPosition();
      final distance = Geolocator.distanceBetween(
        pos.latitude, pos.longitude, _gymLatitude, _gymLongitude);

      if (distance > _geofenceRadiusMeters) {
        await stop(); // Simulate auto-checkout
        print("User exited gym geofence. Auto-checkout.");
      }
    });
  }

  Future<void> stop() async {
    _statusTimer?.cancel();
    _geofenceTimer?.cancel();
    if (FlutterBackground.isBackgroundExecutionEnabled) {
      await FlutterBackground.disableBackgroundExecution();
    }
  }

  Future<void> reset() async {
    _steps = 0;
    _stepTimestamps.clear();
    _emitStepData();
    await _saveSteps();
  }

  int get currentStep => _steps;

  void updateUserWeight(double weightKg) {
    userWeightKg = weightKg;
  }

  void updateUserHeight(double heightMeters) {
    userHeightMeters = heightMeters;
  }
}
