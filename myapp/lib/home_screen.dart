import 'package:flutter/material.dart';
import 'bluetooth_scan_page.dart';
import 'info_screen.dart';
import 'bluetooth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _animalName;

  @override
  void initState() {
    super.initState();
    _loadAnimalName();
  }

  Future<void> _loadAnimalName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _animalName = prefs.getString('animalName');
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: BluetoothService().connectionStatusStream,
      builder: (context, snapshot) {
        final connected = snapshot.data ?? false;

        if (connected && _animalName != null && _animalName!.isNotEmpty) {
          // Bluetooth bağlı ve hayvan adı varsa yönlendir
          Future.microtask(() {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => InfoScreen(animalName: _animalName!),
              ),
            );
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Bağlı değilse veya hayvan adı yoksa buton göster
        return Scaffold(
          appBar: AppBar(
            title: const Text('Ana Ekran'),
          ),
          body: Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.bluetooth),
              label: const Text('Bluetooth Cihazlarını Tara'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BluetoothScanPage()),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
