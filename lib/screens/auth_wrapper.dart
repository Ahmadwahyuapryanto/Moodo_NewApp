import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:moodo_app/screens/login_screen.dart';
import 'package:moodo_app/screens/register_screen.dart';

// Import file baru untuk pengecekan profil
import 'package:moodo_app/screens/profile_check_gate.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Jika user sudah login, arahkan ke gerbang pengecekan profil
          if (snapshot.hasData) {
            // --- PERUBAHAN HANYA DI BARIS INI ---
            return const ProfileCheckGate();
            // ------------------------------------
          }
          // Jika belum, tampilkan halaman login/register
          else {
            return const LoginOrRegister();
          }
        },
      ),
    );
  }
}


// WIDGET INI TETAP SAMA SEPERTI MILIK ANDA (TIDAK DIUBAH)
class LoginOrRegister extends StatefulWidget {
  const LoginOrRegister({super.key});

  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  // Secara default, tampilkan halaman login
  bool showLoginPage = true;

  // Fungsi untuk mengubah state (berpindah halaman)
  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      // Kirim fungsi togglePages ke LoginScreen
      return LoginScreen(showRegisterPage: togglePages);
    } else {
      // Kirim fungsi togglePages ke RegisterScreen
      return RegisterScreen(showLoginPage: togglePages);
    }
  }
}