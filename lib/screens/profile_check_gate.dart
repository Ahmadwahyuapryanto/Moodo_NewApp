import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moodo_app/screens/complete_profile_screen.dart';
import 'package:moodo_app/screens/home_screen.dart';

class ProfileCheckGate extends StatelessWidget {
  const ProfileCheckGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Seharusnya tidak pernah terjadi jika alurnya benar,
      // tapi sebagai pengaman, kembalikan ke AuthWrapper.
      return const Scaffold(body: Center(child: Text("Pengguna tidak ditemukan.")));
    }

    return StreamBuilder<DocumentSnapshot>(
      // Pantau dokumen profil pengguna secara real-time
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        // Saat sedang memuat data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Jika dokumen profil TIDAK ADA
        if (!snapshot.hasData || !snapshot.data!.exists) {
          // Arahkan ke halaman untuk melengkapi profil
          return CompleteProfileScreen(user: user);
        }

        // Jika dokumen profil ADA
        else {
          // Arahkan ke halaman utama aplikasi
          return const HomeScreen();
        }
      },
    );
  }
}