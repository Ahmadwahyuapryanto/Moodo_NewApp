import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompleteProfileScreen extends StatefulWidget {
  final User user;
  const CompleteProfileScreen({super.key, required this.user});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Jika Google memberikan nama, langsung isikan ke form
    if (widget.user.displayName != null && widget.user.displayName!.isNotEmpty) {
      _nameController.text = widget.user.displayName!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = widget.user;
        final displayName = _nameController.text.trim();

        // 1. Buat dokumen profil di Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'displayName': displayName,
          'email': user.email,
          'avatarUrl': user.photoURL, // Ambil foto dari Google jika ada
          'createdAt': Timestamp.now(),
        });

        // 2. Update profil di Firebase Auth juga
        await user.updateDisplayName(displayName);

        // Navigasi tidak diperlukan karena AuthWrapper akan otomatis mendeteksi
        // perubahan dan mengarahkan ke HomeScreen setelah data dibuat.

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan profil: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lengkapi Profil Anda'),
        automaticallyImplyLeading: false, // Sembunyikan tombol kembali
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Satu Langkah Lagi!',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Masukkan nama panggilan Anda untuk melanjutkan.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Panggilan',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text('SIMPAN & LANJUTKAN'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}