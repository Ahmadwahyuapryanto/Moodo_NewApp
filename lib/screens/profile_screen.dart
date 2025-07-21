// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:moodo_app/screens/settings_screen.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:moodo_app/widgets/mood_chart.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  // --- STATE BARU UNTUK DROPDOWN DAN GRAFIK ---
  String _selectedTimeRange = 'Minggu Ini'; // Nilai default dropdown
  Future<Map<String, int>>? _moodDataFuture; // Untuk menampung data grafik
  // ---------------------------------------------

  @override
  void initState() {
    super.initState();
    // Memuat data grafik untuk pertama kali saat halaman dibuka
    _updateChartData();
  }

  // --- FUNGSI BARU UNTUK MENG-UPDATE GRAFIK ---
  void _updateChartData() {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    if (_selectedTimeRange == 'Minggu Ini') {
      // Mengambil data dari 7 hari terakhir
      start = now.subtract(const Duration(days: 6));
    } else { // Bulan Ini
      // Mengambil data dari tanggal 1 bulan ini
      start = DateTime(now.year, now.month, 1);
    }

    setState(() {
      _moodDataFuture = _fetchMoodData(start, end);
    });
  }
  // ----------------------------------------------

  // --- FUNGSI BARU UNTUK MENGAMBIL DATA MOOD ---
  Future<Map<String, int>> _fetchMoodData(DateTime start, DateTime end) async {
    if (currentUser == null) return {};

    final snapshot = await FirebaseFirestore.instance
        .collection('mood_history')
        .where('userId', isEqualTo: currentUser!.uid)
        .where('timestamp', isGreaterThanOrEqualTo: start)
        .where('timestamp', isLessThanOrEqualTo: end)
        .get();

    if (snapshot.docs.isEmpty) return {};

    final Map<String, int> moodCounts = {};
    for (var doc in snapshot.docs) {
      final mood = doc.data()['mood'] as String? ?? 'Lainnya';
      moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
    }
    return moodCounts;
  }
  // ----------------------------------------------

  // Fungsi _pickAndUploadImage tidak diubah
  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 800);
    if (image == null || currentUser == null) return;
    setState(() { _isUploading = true; });
    try {
      final String filePath = 'avatars/${currentUser!.uid}/profile_pic.png';
      final storageRef = FirebaseStorage.instance.ref().child(filePath);
      if (kIsWeb) {
        await storageRef.putData(await image.readAsBytes());
      } else {
        await storageRef.putFile(File(image.path));
      }
      final String downloadUrl = await storageRef.getDownloadURL();
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({'avatarUrl': downloadUrl});
      await currentUser!.updatePhotoURL(downloadUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto profil berhasil diperbarui!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengunggah foto: $e')));
      }
    } finally {
      if (mounted) {
        setState(() { _isUploading = false; });
      }
    }
  }

  // Fungsi _buildStatisticsCard tidak diubah
  Widget _buildStatisticsCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tasks').where('members', arrayContains: currentUser!.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        int completedTasks = 0, ongoingTasks = 0;
        for (var doc in snapshot.data!.docs) {
          if (doc['isCompleted'] == true) {
            completedTasks++;
          } else {
            ongoingTasks++;
          }
        }
        int totalTasks = completedTasks + ongoingTasks;
        double completionRate = totalTasks == 0 ? 0 : (completedTasks / totalTasks);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Statistik Produktivitas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Selesai', completedTasks.toString(), Colors.green),
                    _buildStatItem('Aktif', ongoingTasks.toString(), Colors.orange),
                    _buildStatItem('Total', totalTasks.toString(), Colors.blue),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: completionRate, minHeight: 10, backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green), borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${(completionRate * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // Fungsi _buildStatItem tidak diubah
  Widget _buildStatItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(title),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'Pengaturan',
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data pengguna tidak ditemukan.'));
          }
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          final String? avatarUrl = userData['avatarUrl'];
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Kartu Info Profil Anda (tidak diubah)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 50, backgroundColor: Colors.grey.shade300,
                            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                            child: avatarUrl == null
                                ? Icon(Icons.person, size: 50, color: Colors.grey.shade600)
                                : (_isUploading ? const CircularProgressIndicator(color: Colors.white) : null),
                          ),
                          InkWell(
                            onTap: _isUploading ? null : _pickAndUploadImage,
                            child: const CircleAvatar(
                              radius: 18, backgroundColor: Colors.white70,
                              child: Icon(Icons.camera_alt, size: 22, color: Colors.black87),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(userData['displayName'] ?? 'Tanpa Nama', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(userData['email'] ?? 'Tidak ada email', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Kartu Statistik Produktivitas Anda (tidak diubah)
              _buildStatisticsCard(),
              const SizedBox(height: 16),

              const Divider(height: 24),

              // =========================================================
              // ===> BAGIAN STATISTIK MOOD BARU DENGAN DROPDOWN <===
              // =========================================================
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Rangkuman Mood',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      DropdownButton<String>(
                        value: _selectedTimeRange,
                        items: <String>['Minggu Ini', 'Bulan Ini']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedTimeRange = newValue;
                            });
                            _updateChartData();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<Map<String, int>>(
                    future: _moodDataFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox(
                          height: 200,
                          child: Center(
                            child: Text(
                              'Belum ada data mood pada periode ini.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      }
                      return SizedBox(
                        height: 200,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: MoodChart(moodData: snapshot.data!),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}