import 'dart:async';
import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background/flutter_background.dart';

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

  StepData(this.steps, this.calories, this.speedKmh, this.status, this.cadence,
      this.time);
}

class StepCounter {
  static final StepCounter _instance = StepCounter._internal();
  factory StepCounter() => _instance;
  StepCounter._internal();

  static const EventChannel _stepDetectionChannel =
      EventChannel('step_detection');
  static const EventChannel _stepCountChannel = EventChannel('step_count');

  int _totalSteps = 0;
  final List<DateTime> _todayStepTimestamps = [];

  double userWeightKg = 70;
  double userHeightMeters = 1.75;
  DateTime? _startTime;
  String _status = _STILL;
  Timer? _statusTimer;

  final _stepStreamController = StreamController<StepData>.broadcast();
  Stream<StepData> get stepStream => _stepStreamController.stream;

  double get strideLengthMeters => userHeightMeters * 0.415;

  Future<void> init({
    required double weightKg,
    required double heightMeters,
  }) async {
    userWeightKg = weightKg;
    userHeightMeters = heightMeters;
    await _loadState();
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_steps', _totalSteps);

    final timestampStrings =
        _todayStepTimestamps.map((dt) => dt.toIso8601String()).toList();
    await prefs.setStringList('today_timestamps', timestampStrings);
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _totalSteps = prefs.getInt('total_steps') ?? 0;

    final timestampStrings = prefs.getStringList('today_timestamps') ?? [];
    _todayStepTimestamps.clear();
    _todayStepTimestamps.addAll(
        timestampStrings.map((s) => DateTime.tryParse(s)).whereType<DateTime>());

    _cleanupOldTimestamps();
    _emitStepData(DateTime.now());
  }

  void _cleanupOldTimestamps() {
    final now = DateTime.now();
    _todayStepTimestamps.removeWhere(
        (ts) => now.difference(ts).inDays > 31); // keep last 31 days
  }

  double get caloriesBurned =>
      _totalSteps * strideLengthMeters / 1000 * userWeightKg * 0.57;

  double get walkingSpeedKmh {
    if (_startTime == null) return 0;
    final duration = DateTime.now().difference(_startTime!).inSeconds;
    if (duration == 0) return 0;
    final meters = _totalSteps * strideLengthMeters;
    return (meters / duration) * 3.6;
  }

  double get cadence {
    if (_todayStepTimestamps.length < 2) return 0;
    final duration = _todayStepTimestamps.last
        .difference(_todayStepTimestamps.first)
        .inMinutes;
    return duration == 0 ? 0 : (_todayStepTimestamps.length / duration);
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

    if (Platform.isAndroid) {
      _startNativeListeners();
    } else {
      _startAccelerometerFallback();
    }
  }

  void _startNativeListeners() {
    _stepCountChannel.receiveBroadcastStream().listen((event) {
      _totalSteps = event as int;
      _todayStepTimestamps.add(DateTime.now());
      _cleanupOldTimestamps();
      _emitStepData(DateTime.now());
      _saveState();
    });

    _stepDetectionChannel.receiveBroadcastStream().listen((event) {
      _handleStatus(event);
    });
  }

  void _startAccelerometerFallback() {
    accelerometerEventStream().listen((event) {
      final magnitude =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (magnitude > 12.0) {
        _totalSteps++;
        _todayStepTimestamps.add(DateTime.now());
        _cleanupOldTimestamps();
        _handleStatus(1);
        _emitStepData(DateTime.now());
        _saveState();
      }
    });
  }

  void _handleStatus(int event) {
    _statusTimer?.cancel();

    if (event == 1) {
      final currentSpeed = walkingSpeedKmh;
      _status = (currentSpeed > 6.0) ? _RUNNING : _MOVING;
    }

    _statusTimer = Timer(const Duration(seconds: 2), () {
      _status = _STILL;
      _emitStepData(DateTime.now());
    });
  }

  void _emitStepData(DateTime timestamp) {
    _stepStreamController.add(
      StepData(
        _totalSteps,
        caloriesBurned,
        walkingSpeedKmh,
        _status,
        cadence,
        timestamp,
      ),
    );
  }

  Future<void> stop() async {
    _statusTimer?.cancel();
    if (FlutterBackground.isBackgroundExecutionEnabled) {
      await FlutterBackground.disableBackgroundExecution();
    }
  }

  Future<void> reset() async {
    _totalSteps = 0;
    _todayStepTimestamps.clear();
    _emitStepData(DateTime.now());
    await _saveState();
  }

  int get currentStep => _totalSteps;

  void updateUserWeight(double weightKg) {
    userWeightKg = weightKg;
  }

  void updateUserHeight(double heightMeters) {
    userHeightMeters = heightMeters;
  }

  int get todaySteps {
    final now = DateTime.now();
    return _todayStepTimestamps
        .where((ts) =>
            ts.year == now.year && ts.month == now.month && ts.day == now.day)
        .length;
  }

  int get weeklySteps {
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    return _todayStepTimestamps
        .where((ts) => ts.isAfter(oneWeekAgo) && ts.isBefore(now))
        .length;
  }

  int get monthlySteps {
    final now = DateTime.now();
    return _todayStepTimestamps
        .where((ts) => ts.year == now.year && ts.month == now.month)
        .length;
  }
}
