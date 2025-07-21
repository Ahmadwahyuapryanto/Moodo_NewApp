// lib/themes/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Tema Terang (tidak diubah)
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Colors.blue, // Warna biru untuk item terpilih di mode terang
      unselectedItemColor: Colors.grey,
    ),
  );

  // Tema Gelap diperbarui
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: const Color(0xFF121212),

    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),

    appBarTheme: const AppBarTheme(
      foregroundColor: Colors.white,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white54),
      ),
    ),

    tabBarTheme: const TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
    ),

    // --- PERBAIKAN UTAMA DI SINI ---
    // Mendefinisikan warna navigasi bawah secara eksplisit untuk tema gelap
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.black, // Warna latar belakang navigasi
      selectedItemColor: Colors.white, // Warna ikon & label yang DIPILIH menjadi PUTIH
      unselectedItemColor: Colors.grey,  // Warna ikon & label yang TIDAK DIPILIH
    ),
    // -----------------------------

    cardTheme: CardThemeData(
      color: const Color(0xFF303030),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}