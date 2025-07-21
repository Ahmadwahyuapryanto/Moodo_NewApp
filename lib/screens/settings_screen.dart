// MOODO_App-main/lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moodo_app/screens/auth_wrapper.dart';
import 'package:moodo_app/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Menghapus `final User? currentUser` dari sini untuk selalu mendapatkan data terbaru
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  // --- FUNGSI DIPERBAIKI ---
  // Memuat preferensi pengguna dengan lebih aman
  void _loadUserPreferences() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Keluar jika user null

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid) // Menggunakan user.uid yang dijamin tidak null di sini
        .get()
        .then((doc) {
      if (mounted && doc.exists) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _nameController.text = data['notificationSenderName'] ?? '';
          });
        }
      }
    });
  }

  // --- FUNGSI DIPERBAIKI ---
  // Menyimpan Nama Pengingatku dengan lebih aman
  Future<void> _saveNotificationName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login untuk menyimpan.')),
      );
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama pengingat tidak boleh kosong.')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({'notificationSenderName': _nameController.text.trim()}, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nama pengingat berhasil disimpan!')),
    );
    FocusScope.of(context).unfocus();
  }

  // --- FUNGSI DIPERBAIKI ---
  // Mengubah password dengan lebih aman
  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login untuk mengubah password.')),
      );
      return;
    }

    if (_passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password baru tidak boleh kosong.')),
      );
      return;
    }

    setState(() { _isLoading = true; });
    try {
      await user.updatePassword(_passwordController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password berhasil diubah. Silakan login kembali.')),
      );

      await FirebaseAuth.instance.signOut();

      if(mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
              (route) => false,
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah password: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  // --- FUNGSI DIPERBAIKI ---
  // Menghapus akun dengan lebih aman
  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login untuk menghapus akun.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Akun'),
          content: const Text('Apakah Anda yakin ingin menghapus akun Anda secara permanen? Tindakan ini tidak dapat diurungkan.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                // Logika penghapusan akun (memerlukan re-autentikasi)
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Bagian Tampilan (Tidak Diubah)
          _buildSectionHeader('Tampilan'),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: const Text('Sesuai Sistem'),
                    value: ThemeMode.system,
                    groupValue: themeProvider.themeMode,
                    onChanged: (value) => themeProvider.setTheme(value!),
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Terang'),
                    value: ThemeMode.light,
                    groupValue: themeProvider.themeMode,
                    onChanged: (value) => themeProvider.setTheme(value!),
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Gelap'),
                    value: ThemeMode.dark,
                    groupValue: themeProvider.themeMode,
                    onChanged: (value) => themeProvider.setTheme(value!),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Bagian Notifikasi (Tidak Diubah)
          _buildSectionHeader('Notifikasi'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Pengingatku',
                      hintText: 'Misal: Masa Depanmu, Mama',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveNotificationName,
                      child: const Text('Simpan Nama Pengingat'),
                    ),
                  ),
                  const Divider(height: 32),
                  SwitchListTile(
                    title: const Text('Notifikasi Deadline Tugas'),
                    value: true,
                    onChanged: (value) {},
                  ),
                  SwitchListTile(
                    title: const Text('Notifikasi Pomodoro'),
                    value: true,
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Bagian Akun (Tidak Diubah)
          _buildSectionHeader('Akun'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password Baru',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _changePassword,
                      child: const Text('Ubah Password'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Bagian Keluar & Hapus (Tidak Diubah)
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.orange),
            title: const Text('Keluar (Logout)'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthWrapper()),
                      (route) => false,
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: const Text('Hapus Akun', style: TextStyle(color: Colors.redAccent)),
            onTap: _deleteAccount,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey[800],
        ),
      ),
    );
  }
}