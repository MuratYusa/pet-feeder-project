import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'bluetooth_service.dart' as my_bluetooth;

class BluetoothScanPage extends StatefulWidget {
  const BluetoothScanPage({super.key});

  @override
  State<BluetoothScanPage> createState() => _BluetoothScanPageState();
}

class _BluetoothScanPageState extends State<BluetoothScanPage> {
  List<ScanResult> _devices = [];
  bool _scanning = false;
  BluetoothDevice? connectedDevice;

  @override
  void initState() {
    super.initState();
    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        _devices = results;
      });
    });
    _checkConnectedDevice();
  }

  Future<void> _checkConnectedDevice() async {
    List<BluetoothDevice> devices = await FlutterBluePlus.connectedDevices;

    if (devices.isNotEmpty) {
      setState(() {
        connectedDevice = devices.first; // İlk bağlı cihazı al
      });
    }
  }

  Future<void> _checkBluetoothAndScan() async {
    try {
      List<Permission> permissions = [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ];

      for (Permission permission in permissions) {
        if (await permission.status != PermissionStatus.granted) {
          await permission.request();
        }
      }

      bool allGranted = await _allPermissionsGranted();
      if (!allGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lütfen Bluetooth ve konum izinlerini verin.")),
        );
        return;
      }

      BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        _showBluetoothDialog();
        return;
      }

      setState(() {
        _devices.clear();
        _scanning = true;
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

      Future.delayed(const Duration(seconds: 5), () {
        setState(() {
          _scanning = false;
        });
      });
    } catch (e) {
      debugPrint("Bluetooth taraması başlatılamadı: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
      setState(() {
        _scanning = false;
      });
    }
  }

  Future<bool> _allPermissionsGranted() async {
    return await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothConnect.isGranted &&
        await Permission.location.isGranted;
  }

  void _showBluetoothDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Bluetooth Kapalı"),
        content: const Text("Bluetooth'u açmak için ayarlara gitmek ister misiniz?"),
        actions: [
          TextButton(
            child: const Text("İptal"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Ayarlar"),
            onPressed: () async {
              Navigator.pop(context);
              const url = 'app-settings:';
              if (await canLaunch(url)) {
                await launch(url);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Bluetooth ayarlarına gidilemedi!")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bluetooth Cihazları")),
      body: Column(
        children: [
          if (_scanning)
            const LinearProgressIndicator()
          else
            ElevatedButton.icon(
              onPressed: _checkBluetoothAndScan,
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text("Taramayı Başlat"),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final result = _devices[index];
                final device = result.device;
                return ListTile(
                  title: Text(device.name.isNotEmpty
                      ? device.name
                      : "Bilinmeyen Cihaz"),
                  subtitle: Text(device.id.toString()),
                  trailing: connectedDevice?.id == device.id
                      ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () async {
                            await device.disconnect();
                            setState(() {
                              connectedDevice = null;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Bluetooth bağlantısı kesildi.")),
                            );
                          },
                          child: const Text("Bağlantıyı Kes"),
                        )
                      : Text("${result.rssi} dBm"),
                  onTap: () async {
                    try {
                      await my_bluetooth.BluetoothService().connectToDevice(device);
                      setState(() {
                        connectedDevice = device;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Bluetooth bağlantısı kuruldu.")),
                      );
                      Navigator.pop(context); // istenirse yorum satırı yapılabilir
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Bağlantı hatası: $e")),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
