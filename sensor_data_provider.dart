import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class SensorDataProvider extends ChangeNotifier {
  bool _isConnected = false;
  bool _isScanning = false;
  bool _isConnecting = false;
  String _deviceData = '';
  late BluetoothCharacteristic _rxCharacteristic;
  final List<String> _logs = [];
  final List<String> _receivedData = [];

  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  String get deviceData => _deviceData;
  List<String> get logs => _logs;
  List<String> get receivedData => _receivedData;

  final String serviceUuid = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  final String rxCharacteristicUuid = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';
  final String txCharacteristicUuid = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
  final String targetDeviceId = 'EF:EE:89:54:52:78';

  final FlutterBluePlus flutterBlue = FlutterBluePlus();
  late StreamController<String> _advertisedDataController;

  Stream<String> get advertisedData => _advertisedDataController.stream;

  SensorDataProvider() {
    _advertisedDataController = StreamController<String>.broadcast();
    startScanningAndConnect();
  }

  Future<void> startScanningAndConnect() async {
    try {
      _isScanning = true;
      _isConnecting = false;
      notifyListeners();
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
      addLog('Started scanning for BLE devices.');

      FlutterBluePlus.scanResults.listen((results) async {
        for (ScanResult result in results) {
          addLog('Found device: ${result.device.id}');
          if (result.device.id.id == targetDeviceId) {
            await FlutterBluePlus.stopScan();
            addLog('Found target device, stopping scan.');

            _isScanning = false;
            _isConnecting = true;
            notifyListeners();

            try {
              await result.device.connect(autoConnect: false);
              addLog('Connected to device.');

              List<BluetoothService> services =
                  await result.device.discoverServices();
              BluetoothService service =
                  services.firstWhere((s) => s.uuid.toString() == serviceUuid);

              _rxCharacteristic = service.characteristics
                  .firstWhere((c) => c.uuid.toString() == rxCharacteristicUuid);

              await _rxCharacteristic.setNotifyValue(true);
              addLog('Subscribed to notifications.');

              _rxCharacteristic.value.listen((data) {
                if (data.isNotEmpty) {
                  _deviceData = utf8.decode(data);
                  _receivedData.add(_deviceData);
                  _advertisedDataController.add(_deviceData);
                  addLog('Received data: $_deviceData');
                  notifyListeners();
                }
              });

              _isConnected = true;
              _isConnecting = false;
              notifyListeners();

              // Listen for device disconnection
              result.device.state.listen((state) {
                if (state == BluetoothConnectionState.disconnected) {
                  _isConnected = false;
                  addLog('Device disconnected.');
                  notifyListeners();
                }
              });
            } catch (e) {
              addLog('Error connecting to device: $e');
              _isConnecting = false;
              notifyListeners();
            }

            return;
          }
        }
      });

      await Future.delayed(const Duration(seconds: 4));
      if (!_isConnected) {
        _isScanning = false;
        _isConnecting = false;
        notifyListeners();
      }
    } catch (e) {
      addLog('Error connecting to BLE device: $e');
      _isConnected = false;
      _isScanning = false;
      _isConnecting = false;
      notifyListeners();
    }
  }

  void addLog(String log) {
    _logs.add(log);
    if (_logs.length > 100) _logs.removeAt(0);
    notifyListeners();
  }

  void disconnect() {
    if (_isConnected) {
      _isConnected = false;
      _deviceData = '';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _advertisedDataController.close();
    super.dispose();
  }
}
