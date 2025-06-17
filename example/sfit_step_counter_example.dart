import 'package:flutter/material.dart';
import 'package:sfit_step_counter/sfit_step_counter.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final stepCounter = StepCounter();
  await Permission.activityRecognition.request();
  await stepCounter.init(weightKg: 70, heightMeters: 1.75);
  await stepCounter.start();

  runApp(MyApp(stepCounter));
}

class MyApp extends StatelessWidget {
  final StepCounter counter;
  const MyApp(this.counter, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Step Counter Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('Step Counter')),
        body: StreamBuilder<StepData>(
          stream: counter.stepStream,
          builder: (context, snapshot) {
            final data = snapshot.data;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Steps: ${data?.steps ?? 0}'),
                  Text('Status: ${data?.status ?? "waiting..."}'),
                  Text('Speed: ${data?.speedKmh.toStringAsFixed(2) ?? "0.00"} km/h'),
                  Text('Calories: ${data?.calories.toStringAsFixed(2) ?? "0.00"} kcal'),
                  Text('Cadence: ${data?.cadence.toStringAsFixed(2) ?? "0.00"} steps/min'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
