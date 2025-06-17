import 'package:flutter/material.dart';
import 'package:step_counter/step_counter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final stepCounter = StepCounter();
  await stepCounter.init(weightKg: 70, heightMeters: 1.75);
  await stepCounter.start();

  runApp(MyApp(stepCounter: stepCounter));
}

class MyApp extends StatelessWidget {
  final StepCounter stepCounter;
  const MyApp({required this.stepCounter});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Step Counter')),
        body: StreamBuilder<StepData>(
          stream: stepCounter.stepStream,
          builder: (context, snapshot) {
            final data = snapshot.data;
            if (data == null) return Center(child: CircularProgressIndicator());

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Steps: ${data.steps}'),
                Text('Calories: ${data.calories.toStringAsFixed(2)} kcal'),
                Text('Speed: ${data.speedKmh.toStringAsFixed(2)} km/h'),
                Text('Cadence: ${data.cadence.toStringAsFixed(2)} spm'),
                Text('Status: ${data.status}')
              ],
            );
          },
        ),
      ),
    );
  }
}