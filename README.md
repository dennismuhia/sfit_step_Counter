# 🏃‍♂️ Step Counter

A lightweight, reliable Flutter step counting utility that uses **native Android step detection** (via `EventChannel`) and **accelerometer-based fallback** enhanced with **Kalman filtering**, **step cadence monitoring**, **pedestrian activity classification**, and **geofenced auto-checkout**. Includes real-time updates for steps, speed, calories, cadence, and movement status.

---

## ✅ Features

* ✅ Native Android step detection
* ✅ Accelerometer fallback logic with filtering
* ✅ Real-time step stream
* ✅ Walking status: `walking` / `stopped` / `running`
* ✅ Calories burned estimation
* ✅ Walking speed calculation (km/h)
* ✅ Step cadence tracking (steps/min)
* ✅ Geofenced auto-checkout when exiting gym area
* ✅ Persistent step tracking with `SharedPreferences`
* ✅ Background execution with `flutter_background`
* ✅ User-defined weight and height for calorie/speed accuracy
* ✅ iOS Core Motion support (Coming Soon)

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
  geolocator: ^10.0.0
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
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
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
  await [
    Permission.activityRecognition,
    Permission.location,
  ].request();
}
```

---

## 🧰 How to Use

### ✅ Step 1: Import and Initialize

```dart
final stepCounter = StepCounter();

await requestPermissions();
await stepCounter.init(weightKg: 72, heightMeters: 1.78); // user input values
```

---

### ✅ Step 2: Start the Counter

```dart
await stepCounter.start();
```

---

### ✅ Step 3: Listen to Updates

```dart
stepCounter.stepStream.listen((StepData data) {
  print('Steps: ${data.steps}');
  print('Calories: ${data.calories.toStringAsFixed(2)} kcal');
  print('Speed: ${data.speedKmh.toStringAsFixed(2)} km/h');
  print('Cadence: ${data.cadence.toStringAsFixed(2)} steps/min');
  print('Status: ${data.status}');
});
```

---

### ✅ Step 4: Stop or Reset

```dart
await stepCounter.stop();
await stepCounter.reset();
```

---

## 📦 `StepData` DTO

```dart
class StepData {
  final int steps;
  final double calories;
  final double speedKmh;
  final String status;
  final double cadence;
  final DateTime time;

  StepData(this.steps, this.calories, this.speedKmh, this.status, this.cadence, this.time);
}
```

---

## 📍 Geofencing (Auto-Checkout)

* The system checks every 30 seconds if the user has moved **outside a 50-meter radius** from the gym.
* When detected, it automatically stops the step counter (simulating checkout).
* You can customize the `_gymLatitude`, `_gymLongitude`, and `_geofenceRadiusMeters` fields.

---

## 💡 Tips

* ✅ Keep the app running in background using `flutter_background`.
* 🎯 Pass user height and weight for better stride and calorie estimation.
* 🧠 ML logic uses cadence + motion patterns to enhance walking status.
* 📍 Test geofence behavior by simulating GPS position changes.

---

## 🐛 Troubleshooting

| Problem                          | Solution                                                                        |
| -------------------------------- | ------------------------------------------------------------------------------- |
| Steps not counting               | Ensure ACTIVITY_RECOGNITION and LOCATION permissions are granted.              |
| App stops counting in background | Ensure `flutter_background` is configured and active.                           |
| Counter is too sensitive         | Adjust fallback accelerometer threshold if needed.                             |

---

## ✅ Example Integration

```dart
void main() async {
  final stepCounter = StepCounter();

  await requestPermissions();
  await stepCounter.init(weightKg: 68, heightMeters: 1.72); // example user data
  await stepCounter.start();

  stepCounter.stepStream.listen((StepData data) {
    print('Steps: ${data.steps}');
    print('Calories: ${data.calories.toStringAsFixed(2)} kcal');
    print('Speed: ${data.speedKmh.toStringAsFixed(2)} km/h');
    print('Status: ${data.status}');
    print('Cadence: ${data.cadence.toStringAsFixed(2)} steps/min');
  });
}
```

---

## 🔮 Coming Soon

* [x] iOS Core Motion Support (partial work in progress)
* [ ] Step goals and daily targets
* [ ] Charts, weekly/monthly reports
* [ ] Firebase sync & notification triggers
* [ ] Google Fit / Apple Health sync

---

## 🤝 Contributing

Feel free to fork the repo, submit PRs, or report issues.
You can request:

* Flutter + GetX Controller Integration
* ML model customization for step vs run classification
* Integration with Wear OS / Android watches
