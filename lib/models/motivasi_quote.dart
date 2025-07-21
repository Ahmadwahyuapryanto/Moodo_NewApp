import 'dart:math';

class MotivasiQuote {
  // Pastikan list quotes ini static
  static final List<String> quotes = [
    'Jangan takut gagal, itu bagian dari belajar.',
    'Kerja keras akan membuahkan hasil.',
    'Satu-satunya cara untuk melakukan pekerjaan hebat adalah dengan mencintai apa yang Anda lakukan.',
    'Mulai dari mana Anda berada. Gunakan apa yang Anda miliki. Lakukan apa yang Anda bisa.',
    'Percayalah Anda bisa dan Anda sudah setengah jalan.',
    'Jangan berhenti ketika lelah, berhentilah ketika selesai.',
    'Masa depan adalah milik mereka yang menyiapkan hari ini.',
  ];

  // Pastikan method ini static
  static String getRandomQuote() {
    final random = Random();
    return quotes[random.nextInt(quotes.length)];
  }
}