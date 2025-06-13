# 🏃 Step Counter

A lightweight step counting utility that uses both native Android step detection (via `EventChannel`) and an accelerometer-based fallback enhanced with Kalman filtering and pedestrian status detection. It also estimates walking speed and calories burned.

---

### ✅ Features

* Native step counting on Android
* Accelerometer fallback logic with filtering
* Real-time pedestrian status (`walking` / `stopped`)
* Calories burned estimation
* Walking speed calculation (km/h)
* Persistent step storage with `SharedPreferences`
* Background execution with `flutter_background`

---

## 🚀 Getting Started

### 1. ⚙️ Add the dependencies

```yaml
dependencies:
  sensors_plus: ^3.0.3
  shared_preferences: ^2.2.2
  flutter_background: ^1.0.0
  permission_handler: ^11.3.0
```

---

### 2. 📱 Android Configuration

In `android/app/src/main/AndroidManifest.xml`, add:

```xml
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

Inside `<application>`:

```xml
<service android:name="com.pravera.flutter_background.FlutterBackgroundService"
         android:enabled="true"
         android:exported="false"/>

<receiver android:enabled="true"
          android:exported="true"
          android:permission="android.permission.RECEIVE_BOOT_COMPLETED">
  <intent-filter>
    <action android:name="android.intent.action.BOOT_COMPLETED"/>
    <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
    <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
  </intent-filter>
</receiver>
```

Also in `android/app/build.gradle`:

```gradle
defaultConfig {
    minSdkVersion 21
    ...
}
```

---

### 3. 📋 Request Permissions

```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  await Permission.activityRecognition.request();
}
```

Call `requestPermissions()` before starting the step counter.

---

## 🔧 Initialization & Usage

### Step 1: Import the package

```dart
import 'package:your_package_name/step_counter.dart';
```

> Replace `your_package_name` with the correct import path if this is inside your app or a custom package.

---

### Step 2: Initialize

```dart
final stepCounter = StepCounter();

await stepCounter.init(weightKg: 68, heightMeters: 1.72);
```

---

### Step 3: Start the Step Counter

```dart
await stepCounter.start();
```

---

### Step 4: Listen for updates

```dart
stepCounter.stepStream.listen((StepData data) {
  print('Steps: ${data.steps}');
  print('Status: ${data.status}');
  print('Calories: ${data.calories.toStringAsFixed(2)} kcal');
  print('Speed: ${data.speed.toStringAsFixed(2)} km/h');
});
```

---

### Step 5: Stop / Reset

```dart
await stepCounter.stop();
await stepCounter.reset();
```

---

## 📦 `StepData` DTO

This object is returned in the stream:

```dart
class StepData {
  final int steps;
  final String status; // "walking" or "stopped"
  final double calories;
  final double speed; // km/h
}
```

---

## 🧪 Example Integration

```dart
void main() async {
  final stepCounter = StepCounter();

  await requestPermissions();
  await stepCounter.init(weightKg: 70, heightMeters: 1.75);
  await stepCounter.start();

  stepCounter.stepStream.listen((data) {
    print('Steps: ${data.steps}');
    print('Calories: ${data.calories}');
    print('Speed: ${data.speed}');
    print('Status: ${data.status}');
  });
}
```

---

## 📝 Notes

* On Android, this uses native `EventChannel` for accurate steps.
* On iOS or unsupported platforms, it falls back to accelerometer-based detection.
* Calories and speed calculations are estimates, not medical-grade.
