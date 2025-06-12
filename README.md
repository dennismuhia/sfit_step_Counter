# 🏃 Step Counter

A lightweight Flutter package to help you **count steps using the device's gyroscope and Kalman filtering**. This package is a modern alternative to deprecated or unstable step tracking packages like `health` and `pedometer`, which often crash on certain devices.

Built with simplicity, performance, and compatibility in mind.

---

## 🚀 Features

* 📱 Step detection using [`sensors_plus`](https://pub.dev/packages/sensors_plus)
* 📊 Real-time step stream
* 🔁 Simple API: `start()`, `stop()`, `reset()`
* 🔥 Calculates:

  * Total **steps**
  * **Calories burned**
  * **Walking speed (km/h)**
* ⚙️ Lightweight Kalman filter for noise reduction
* ✅ No activity recognition dependency required

---

## 🧪 Usage

```dart
import 'package:sfit_step_counter/sfit_step_counter.dart';

final stepCounter = StepCounter();

await stepCounter.init(weightKg: 68, heightMeters: 1.72);

stepCounter.start();

stepCounter.stepStream.listen((steps) {
  print('Steps: $steps');
  print('Calories: ${stepCounter.caloriesBurned.toStringAsFixed(2)} kcal');
  print('Speed: ${stepCounter.walkingSpeedKmh.toStringAsFixed(2)} km/h');
});
```

---

## 🔐 Permissions

You’ll need to request the **activity recognition** permission:

```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  if (await Permission.activityRecognition.request().isGranted) {
    // Permission granted
  }
}
```

---

## 🛠 Android Setup

Update your **AndroidManifest.xml**:

```xml
<!-- Required Permissions -->
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

Inside the `<application>` tag:

```xml
<application
    android:label="your_app_name"
    android:icon="@mipmap/ic_launcher"
    android:usesCleartextTraffic="true">

    <!-- Required for background execution -->
    <service
        android:name="com.pravera.flutter_background.FlutterBackgroundService"
        android:enabled="true"
        android:exported="false"/>

    <receiver
        android:enabled="true"
        android:exported="true"
        android:permission="android.permission.RECEIVE_BOOT_COMPLETED">
        <intent-filter>
            <action android:name="android.intent.action.BOOT_COMPLETED"/>
            <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
            <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
        </intent-filter>
    </receiver>
</application>
```

Also update `android/app/build.gradle`:

```gradle
defaultConfig {
  minSdkVersion 21
  // other configs...
}
```

---

## 📦 Installing

Add to your `pubspec.yaml`:

```yaml
dependencies:
  sfit_step_counter: ^0.0.11
```

---

## 🙏 Thanks

Thank you for using this package! If you find it useful, feel free to [like on pub.dev](https://pub.dev/packages/sfit_step_counter) and share with fellow Flutter developers.

Happy coding! 😊

