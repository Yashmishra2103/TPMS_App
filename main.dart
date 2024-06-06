import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sensor_data_provider.dart';
import 'sensor_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => SensorDataProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TPMS App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SensorScreen(),
    );
  }
}
