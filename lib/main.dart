// MOODO_App-main/lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:moodo_app/firebase_options.dart';
import 'package:moodo_app/providers/theme_provider.dart';
import 'package:moodo_app/screens/splash_screen.dart';
import 'package:moodo_app/themes/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await Hive.initFlutter();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Bagian ini sudah benar, TIDAK PERLU DIUBAH
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- PERBAIKAN DILAKUKAN DI SINI ---
    // Kita tidak memanggil Provider.of() secara langsung di sini.
    // Kita gunakan widget "Consumer" agar tema bisa didapatkan dengan benar.
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Mood-Do',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          // Menggunakan `themeProvider` dari builder
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
        );
      },
    );
    // --- AKHIR DARI PERBAIKAN ---
  }
}