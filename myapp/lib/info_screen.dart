import 'package:flutter/material.dart';
import 'bluetooth_service.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'bluetooth_scan_page.dart';

class InfoScreen extends StatefulWidget {
  final String animalName;
  const InfoScreen({super.key, required this.animalName});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  final List<DateTime> mamaVerilmeZamanlari = [];

  late final StreamSubscription<String> _rawMessageSub;
  late final StreamSubscription<bool> _connectionSub;

  @override
  void initState() {
    super.initState();
    _loadMamaVerilmeZamanlari();

    _connectionSub = BluetoothService().connectionStatusStream.listen((connected) {
      if (!connected && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Bluetooth bağlantısı kesildi!'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });

    _rawMessageSub = BluetoothService().rawMessageStream.listen((String data) {
      if (data.contains("MAMA:VERILDI")) {
        _addMamaVerilmeZamani(DateTime.now());
      }
    });
  }

  Future<void> _loadMamaVerilmeZamanlari() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedList = prefs.getStringList('mamaVerilmeZamanlari');
    if (savedList != null) {
      setState(() {
        mamaVerilmeZamanlari.clear();
        mamaVerilmeZamanlari.addAll(savedList.map((e) => DateTime.parse(e)));
      });
    }
  }

  Future<void> _addMamaVerilmeZamani(DateTime time) async {
    setState(() {
      mamaVerilmeZamanlari.insert(0, time);
    });
    final prefs = await SharedPreferences.getInstance();
    final List<String> stringList =
        mamaVerilmeZamanlari.map((e) => e.toIso8601String()).toList();
    await prefs.setStringList('mamaVerilmeZamanlari', stringList);
  }

  @override
  void dispose() {
    _rawMessageSub.cancel();
    _connectionSub.cancel();
    super.dispose();
  }

  String formatDateTime(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/"
        "${dt.month.toString().padLeft(2, '0')}/"
        "${dt.year} "
        "${dt.hour.toString().padLeft(2, '0')}:" 
        "${dt.minute.toString().padLeft(2, '0')}:" 
        "${dt.second.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Colors.brown.shade50;
    final iconColor = Colors.brown.shade700;
    final cardElevation = 4.0;
    final borderRadius = BorderRadius.circular(15);

    Widget buildCard({required Widget child}) {
      return Card(
        color: cardColor,
        elevation: cardElevation,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: child,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Üst ikonlar ve hayvan adı kartları
              Row(
                children: [
                  // Hayvan adı kartı
                  Expanded(
                    child: buildCard(
                      child: Row(
                        children: [
                          Icon(Icons.pets, size: 30, color: iconColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.animalName,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: iconColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Bluetooth durum kartı
                  StreamBuilder<bool>(
                    stream: BluetoothService().connectionStatusStream,
                    initialData: false,
                    builder: (context, snapshot) {
                      final connected = snapshot.data ?? false;
                      return buildCard(
                        child: IconButton(
                          icon: Icon(
                            connected
                                ? Icons.bluetooth_connected
                                : Icons.bluetooth_disabled,
                            color: connected ? Colors.blue : Colors.grey,
                            size: 30,
                          ),
                          tooltip: 'Bluetooth Cihazlarını Tara',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BluetoothScanPage(),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 12),

                  // Düzenleme kartı
                  buildCard(
                    child: IconButton(
                      icon: Icon(Icons.edit, color: iconColor, size: 30),
                      tooltip: "Hayvan Adını Değiştir",
                      onPressed: () async {
                        final yeniAd = await showDialog<String>(
                          context: context,
                          builder: (context) {
                            final TextEditingController controller =
                                TextEditingController(text: widget.animalName);
                            return AlertDialog(
                              title: const Text('Hayvan Adını Değiştir'),
                              content: TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                    labelText: 'Yeni Hayvan Adı'),
                                textCapitalization: TextCapitalization.words,
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('İptal')),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, controller.text.trim()),
                                    child: const Text('Kaydet')),
                              ],
                            );
                          },
                        );

                        if (yeniAd != null && yeniAd.isNotEmpty) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('animalName', yeniAd);
                          if (!mounted) return;

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InfoScreen(animalName: yeniAd),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Mama veriliş kayıtları başlığı
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Mama Veriliş Kayıtları",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Mama veriliş kayıtları listesi
              Expanded(
                child: mamaVerilmeZamanlari.isEmpty
                    ? Center(
                        child: Text(
                          "Henüz mama verilmedi.",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: mamaVerilmeZamanlari.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final dt = mamaVerilmeZamanlari[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: borderRadius,
                            ),
                            elevation: cardElevation,
                            color: cardColor,
                            child: ListTile(
                              leading: Icon(Icons.check_circle, color: Colors.green),
                              title: Text(
                                "${widget.animalName} için mama verildi",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: iconColor,
                                ),
                              ),
                              subtitle: Text(formatDateTime(dt)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
