import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';

class TaskCompletionScreen extends StatefulWidget {
  final String taskTitle;

  const TaskCompletionScreen({super.key, required this.taskTitle});

  @override
  State<TaskCompletionScreen> createState() => _TaskCompletionScreenState();
}

class _TaskCompletionScreenState extends State<TaskCompletionScreen> {
  @override
  void initState() {
    super.initState();
    // Kembali ke halaman utama setelah 4 detik
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'animations/document.json',
              width: 300,
              height: 300,
              repeat: false, // Animasi hanya diputar sekali
            ),
            const SizedBox(height: 24),
            const Text(
              'Kerja Bagus!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                'Anda telah menyelesaikan tugas:\n"${widget.taskTitle}"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}