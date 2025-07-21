// MOODO_App-main/lib/widgets/quote_card.dart

import 'package:flutter/material.dart';

class QuoteCard extends StatelessWidget {
  final String quote;

  const QuoteCard({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    // 1. Mendeteksi apakah mode gelap sedang aktif
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 2. Menentukan warna latar belakang kartu berdasarkan tema
    final cardColor = isDarkMode
        ? Colors.purple.shade100 // Warna ungu muda untuk dark mode
        : Theme.of(context).colorScheme.secondary.withOpacity(0.2); // Warna asli Anda untuk light mode

    // 3. Menentukan warna teks berdasarkan tema
    final textColor = isDarkMode
        ? Colors.black87 // Warna hitam untuk dark mode
        : Theme.of(context).textTheme.bodyLarge?.color; // Warna default teks untuk light mode

    final titleColor = isDarkMode
        ? Colors.black // Warna hitam pekat untuk judul di dark mode
        : Theme.of(context).textTheme.titleMedium?.color; // Warna default judul untuk light mode

    return Card(
      color: cardColor, // Menggunakan warna yang sudah ditentukan
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Motivasi Hari Ini',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: titleColor, // Menggunakan warna judul yang sudah ditentukan
              ),
            ),
            const SizedBox(height: 8),
            Text(
              quote,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: textColor, // Menggunakan warna teks yang sudah ditentukan
              ),
            ),
          ],
        ),
      ),
    );
  }
}