import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'info_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<String?> _getSavedAnimalName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('animalName');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mama Takip',
      theme: ThemeData(primarySwatch: Colors.brown),
      home: FutureBuilder<String?>(
        future: _getSavedAnimalName(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const AnimalNameInputScreen();
          } else {
            return InfoScreen(animalName: snapshot.data!);
          }
        },
      ),
    );
  }
}

class AnimalNameInputScreen extends StatefulWidget {
  const AnimalNameInputScreen({super.key});

  @override
  State<AnimalNameInputScreen> createState() => _AnimalNameInputScreenState();
}

class _AnimalNameInputScreenState extends State<AnimalNameInputScreen> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _saveAnimalName() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen hayvan adı girin')));
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('animalName', name);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => InfoScreen(animalName: name)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hayvan Adı Girin')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Lütfen hayvanınızın adını girin:',
              style: TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Hayvan Adı',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveAnimalName,
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
