## 🏃‍♂️ Step Counter with Cadence, Speed, Calories & Background Support

This Flutter-based step counter supports both native Android step detection (via EventChannel) and an accelerometer fallback (for iOS or unsupported devices). It also provides:

* ✅ Real-time step tracking
* 🔥 Cadence (steps per minute)
* ⚡ Speed in km/h
* 🥗 Calorie estimation
* 📦 SharedPreferences persistence
* 📱 Background execution

---

## 📦 Installation

Add the following packages in `pubspec.yaml`:

```yaml
dependencies:
  sensors_plus: ^4.0.1
  shared_preferences: ^2.2.2
  flutter_background: ^1.2.0
```

---

## 🧑‍💻 How to Use

### 1. **Import and initialize**

```dart
import 'step_counter.dart';

final stepCounter = StepCounter();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await stepCounter.init(weightKg: 70, heightMeters: 1.75); // Customize
  runApp(MyApp());
}
```

---

### 2. **Start Tracking Steps**

```dart
await stepCounter.start();
```

---

### 3. **Listen to Step Stream**

```dart
stepCounter.stepStream.listen((StepData data) {
  print("Steps: ${data.steps}");
  print("Status: ${data.status}");
  print("Speed: ${data.speedKmh.toStringAsFixed(2)} km/h");
  print("Cadence: ${data.cadence.toStringAsFixed(2)} steps/min");
  print("Calories: ${data.calories.toStringAsFixed(1)} cal");
});
```

---

### 4. **Stop and Reset**

```dart
await stepCounter.stop();
await stepCounter.reset();
```

---

### 5. **Access Aggregates**

```dart
print("Today Steps: ${stepCounter.todaySteps}");
print("Weekly Steps: ${stepCounter.weeklySteps}");
print("Monthly Steps: ${stepCounter.monthlySteps}");
```

---

## 🧠 Key Features Explained

| Feature        | Method/Property                             | Description                                                          |
| -------------- | ------------------------------------------- | -------------------------------------------------------------------- |
| 🎯 Start       | `start()`                                   | Begins tracking via native Android or accelerometer fallback         |
| 🛑 Stop        | `stop()`                                    | Disables background tracking                                         |
| 🔄 Reset       | `reset()`                                   | Clears step data                                                     |
| 📡 Stream      | `stepStream`                                | Emits `StepData` on each new step                                    |
| 🔥 Calories    | `caloriesBurned`                            | Estimate using METs formula                                          |
| 🚶 Cadence     | `cadence`                                   | Steps per minute                                                     |
| 🚀 Speed       | `walkingSpeedKmh`                           | Approximate km/h speed                                               |
| 📊 Aggregates  | `todaySteps`, `weeklySteps`, `monthlySteps` | Time-based metrics                                                   |
| 💾 Persistence | SharedPreferences                           | Restores steps and timestamps across restarts                        |
| 🔋 Background  | `flutter_background`                        | Keeps tracking even when the app is in the background (Android only) |

---

## 📱 Platform Behavior

| Platform    | Behavior                                                         |
| ----------- | ---------------------------------------------------------------- |
| Android     | Uses native `step_detection` and `step_count` via `EventChannel` |
| iOS / Other | Uses accelerometer magnitude threshold > 12.0                    |

> ⚠️ iOS requires additional work if you want to support HealthKit directly (not included in this version).

---

## 🚨 Permissions

### Android

Ensure the following permissions are in your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
```

And inside `<application>`:

```xml
<service android:name="com.ekasetiawans.stepcounter.StepService"
         android:enabled="true"
         android:exported="false"/>
```

### iOS

No permissions are strictly required for the accelerometer fallback, but you must test on a real device.

---

## ✅ Example UI Widget

```dart
class StepWidget extends StatefulWidget {
  @override
  _StepWidgetState createState() => _StepWidgetState();
}

class _StepWidgetState extends State<StepWidget> {
  late StreamSubscription<StepData> _sub;
  StepData? _data;

  @override
  void initState() {
    super.initState();
    _sub = StepCounter().stepStream.listen((d) {
      setState(() => _data = d);
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _data == null
        ? CircularProgressIndicator()
        : Column(
            children: [
              Text("Steps: ${_data!.steps}"),
              Text("Status: ${_data!.status}"),
              Text("Speed: ${_data!.speedKmh.toStringAsFixed(2)} km/h"),
              Text("Calories: ${_data!.calories.toStringAsFixed(1)} cal"),
              Text("Cadence: ${_data!.cadence.toStringAsFixed(1)} spm"),
            ],
          );
  }
}
```

---

## 📌 Summary

✅ Cross-platform step detection
✅ Real-time stream
✅ Supports cadence, calories, and speed
✅ Persistent with `SharedPreferences`
✅ Background support (Android)

