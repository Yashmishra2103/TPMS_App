import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sensor_data_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';

class SensorScreen extends StatefulWidget {
  const SensorScreen({super.key});

  @override
  SensorScreenState createState() => SensorScreenState();
}

class SensorScreenState extends State<SensorScreen> {
  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.location
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TPMS App'),
          bottom: const TabBar(
            tabs: [
              Tab(text: "TPMS"),
              Tab(text: "Logger"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            carDisplayTab(context),
            loggerTab(context),
          ],
        ),
      ),
    );
  }

  Widget carDisplayTab(BuildContext context) {
    return Consumer<SensorDataProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Image.asset('assets/travel.png', width: 200, height: 200),
                const SizedBox(height: 20),
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    children: [
                      buildTireData('Front Left', generateRandomTireData()),
                      buildTireData('Front Right', generateRandomTireData()),
                      buildTireData('Rear Left', generateRandomTireData()),
                      buildTireData('Rear Right', generateRandomTireData()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget loggerTab(BuildContext context) {
    return Consumer<SensorDataProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            if (provider.isConnecting)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Connecting to Nordic UART...',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            if (provider.isConnected)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Connected',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: provider.receivedData.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(provider.receivedData[index]),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String generateRandomTireData() {
    Random random = Random();
    return 'Sensor ID: 1\nPressure: ${random.nextInt(10) + 30} psi\nTemperature: ${random.nextInt(5) + 25} °C\nAcceleration: ${random.nextInt(10) + 20} m/s²';
  }

  Widget buildTireData(String tirePosition, String data) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            tirePosition,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
