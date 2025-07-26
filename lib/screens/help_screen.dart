import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Model untuk menampung data tutorial
class TutorialStep {
  final String title;
  final String content;
  TutorialStep({required this.title, required this.content});
}

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  late Future<List<TutorialStep>> _tutorialFuture;

  @override
  void initState() {
    super.initState();
    _tutorialFuture = _fetchTutorial();
  }

  Future<List<TutorialStep>> _fetchTutorial() async {
    // PENTING: Ganti alamat IP jika menjalankan di emulator Android
    // Gunakan 'http://10.0.2.2:3000/tutorial' untuk emulator Android
    // Gunakan 'http://localhost:3000/tutorial' jika menjalankan di Chrome
    const url = 'http://localhost:3000/tutorial';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => TutorialStep(
          title: item['title'],
          content: item['content'],
        )).toList();
      } else {
        throw Exception('Gagal memuat data dari server.');
      }
    } catch (e) {
      // Menangani error jika server tidak aktif atau ada masalah jaringan
      print('Error fetching tutorial: $e');
      throw Exception('Tidak dapat terhubung ke server bantuan.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bantuan & Tutorial'),
      ),
      body: FutureBuilder<List<TutorialStep>>(
        future: _tutorialFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: ${snapshot.error}\n\nPastikan JSON Server sudah berjalan di komputer Anda.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada data tutorial ditemukan.'));
          }

          final tutorialSteps = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: tutorialSteps.length,
            itemBuilder: (context, index) {
              final step = tutorialSteps[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: ExpansionTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(step.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(step.content, textAlign: TextAlign.justify),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}