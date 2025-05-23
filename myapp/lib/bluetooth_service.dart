import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();
  final StreamController<String> _rawMessageController = StreamController<String>.broadcast();
Stream<String> get rawMessageStream => _rawMessageController.stream;


  BluetoothDevice? _connectedDevice;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  BluetoothCharacteristic? _writeCharacteristic;

  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  final StreamController<double> _weightController = StreamController<double>.broadcast();
  Stream<double> get weightStream => _weightController.stream;

  Future<void> connectToDevice(BluetoothDevice device) async {
  try {
    await device.connect();
    _connectedDevice = device;
    _connectionStatusController.add(true);

    device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _connectionStatusController.add(false);
      }
    });

    final services = await device.discoverServices();

    for (var service in services) {
      for (var c in service.characteristics) {
        // Yazma karakteristiğini tespit et
        if (c.properties.write || c.properties.writeWithoutResponse) {
          _writeCharacteristic = c;
          print("Yazma karakteristiği bulundu: ${c.uuid}");
        }
        if (c.properties.notify || c.properties.read) {
          await c.setNotifyValue(true);
          c.value.listen((value) => _parseArduinoData(value));
        }
      }
    }

    if (_writeCharacteristic == null) {
      print("Uyarı: Yazma karakteristiği bulunamadı.");
    }
  } catch (e) {
    _connectionStatusController.add(false);
    rethrow;
  }
}


  Future<void> writeData(String data) async {
    if (_writeCharacteristic == null) {
      throw Exception("Bağlı cihaz yazma karakteristiği bulunamadı.");
    }
    List<int> bytes = data.codeUnits;
    await _writeCharacteristic!.write(bytes, withoutResponse: true);
  }

  void _parseArduinoData(List<int> data) {
  try {
    String dataStr = String.fromCharCodes(data);
    print("Alınan veri: $dataStr");

    _rawMessageController.add(dataStr); // Gelen tüm veriyi ilet

    if (dataStr.contains("AGIRLIK:")) {
      String weightStr = dataStr.split(":")[1].trim();
      double weight = double.parse(weightStr) / 1000.0;
      _weightController.add(weight);
      print("İşlenen ağırlık: $weight kg");
    }
  } catch (e) {
    print("Veri ayrıştırma hatası: $e");
  }
}



  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _writeCharacteristic = null;
      _connectionStatusController.add(false);
    }
  }

  void dispose() {
    _connectionStatusController.close();
    _weightController.close();
  }
}
