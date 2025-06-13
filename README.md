# 🏃‍♂️ Step Counter

A lightweight, reliable Flutter step counting utility that uses **native Android step detection** (via `EventChannel`) and **accelerometer-based fallback** enhanced with **Kalman filtering** and **pedestrian status detection**. Includes real-time updates for steps, walking speed, and calories burned.

---

## ✅ Features

* ✅ Native Android step detection
* ✅ Accelerometer fallback logic with filtering
* ✅ Real-time step stream
* ✅ Walking status: `walking` / `stopped`
* ✅ Calories burned estimation
* ✅ Walking speed calculation (km/h)
* ✅ Persistent step tracking with `SharedPreferences`
* ✅ Background execution with `flutter_background`

---

## 🚀 Getting Started

### 1️⃣ Add Dependencies

In your `pubspec.yaml`:

```yaml
dependencies:
  sensors_plus: ^3.0.3
  shared_preferences: ^2.2.2
  flutter_background: ^1.0.0
  permission_handler: ^11.3.0
```

---

### 2️⃣ Android Setup

#### a. `AndroidManifest.xml`

Add the following **outside** the `<application>` tag:

```xml
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

Inside the `<application>` tag:

```xml
<application
   ...>
   <service android:name="com.pravera.flutter_background.FlutterBackgroundService"
            android:enabled="true" android:exported="false" />
   <receiver android:enabled="true" android:exported="true"
             android:permission="android.permission.RECEIVE_BOOT_COMPLETED">
     <intent-filter>
       <action android:name="android.intent.action.BOOT_COMPLETED"/>
       <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
     </intent-filter>
   </receiver>
</application>
```

#### b. `android/app/build.gradle`

Ensure minimum SDK version is **21 or higher**:

```gradle
defaultConfig {
  minSdkVersion 21
  ...
}
```

---

### 3️⃣ Request Permissions

Add the following before starting the counter:

```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  final status = await Permission.activityRecognition.request();
  if (!status.isGranted) {
    throw Exception("Activity Recognition permission denied");
  }
}
```

---

## 🧰 How to Use

### ✅ Step 1: Import and Initialize

```dart
import 'package:your_project/step_counter.dart';

final stepCounter = StepCounter();

await requestPermissions();
await stepCounter.init(weightKg: 70, heightMeters: 1.75);
```

---

### ✅ Step 2: Start the Counter

```dart
await stepCounter.start();
```

---

### ✅ Step 3: Listen to Updates

```dart
stepCounter.stepStream.listen((steps) {
  print('Steps: $steps');
  print('Calories: ${stepCounter.caloriesBurned.toStringAsFixed(2)} kcal');
  print('Speed: ${stepCounter.walkingSpeedKmh.toStringAsFixed(2)} km/h');
});
```

---

### ✅ Step 4: Stop or Reset

```dart
await stepCounter.stop();
await stepCounter.reset();
```

---

## 📦 `StepData` DTO (Optional)

If you choose to stream richer objects instead of just step counts:

```dart
class StepData {
  final int steps;
  final String status; // "walking" or "stopped"
  final double calories;
  final double speed; // in km/h
}
```

Update the stream to emit `StepData` if needed.

---

## 💡 Tips

* 📱 Keep the app running in background using `flutter_background`.
* ✅ Ensure permissions are granted, or step tracking will not work.
* 🧪 You can add unit tests using mock streams if needed.
* 🧠 Use [Google’s Activity Recognition API](https://developers.google.com/location-context/activity-recognition) for more advanced use cases.

---

## 🐛 Troubleshooting

| Problem                          | Solution                                                                        |
| -------------------------------- | ------------------------------------------------------------------------------- |
| Steps not counting               | Ensure ACTIVITY\_RECOGNITION permission is granted.                             |
| App stops counting in background | Ensure `flutter_background` is properly configured and active.                  |
| Counter is too sensitive         | Adjust debounce threshold (e.g., time between steps or magnitude) in the logic. |

---

## ✅ Example Integration

```dart
void main() async {
  final stepCounter = StepCounter();

  await requestPermissions();
  await stepCounter.init(weightKg: 70, heightMeters: 1.75);
  await stepCounter.start();

  stepCounter.stepStream.listen((steps) {
    print('Steps: $steps');
    print('Calories: ${stepCounter.caloriesBurned.toStringAsFixed(2)} kcal');
    print('Speed: ${stepCounter.walkingSpeedKmh.toStringAsFixed(2)} km/h');
  });
}
```

---

## 🔮 Coming Soon

* [ ] iOS support
* [ ] Step goals
* [ ] Integration with Google Fit / Apple Health
* [ ] Weekly/monthly stats
* [ ] Notification badge with daily steps

---

## 🤝 Contributing

Feel free to submit issues, improvements, or PRs! You can also ask for:

* GetX integration (`StepsController`)
* ML-based activity recognition
* Chart display of progress

