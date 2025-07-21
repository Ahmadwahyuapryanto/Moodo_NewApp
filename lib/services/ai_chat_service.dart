// lib/services/ai_chat_service.dart

import 'package:google_generative_ai/google_generative_ai.dart';

class AiChatService {
  // API Key Anda
  static const String _apiKey = 'AIzaSyCbwByCFaZEOLGW-ElBhwRwnzZKIhtMxUA';

  // Fungsi untuk merespons mood awal yang dipilih pengguna
  Future<String> getInitialResponse(String userMood, String aiName) async {
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);

      // Prompt khusus untuk merespons mood awal
      final prompt =
          'Peranmu adalah sebagai asisten AI bernama "$aiName". '
          'Pengguna baru saja memberitahumu bahwa perasaan mereka hari ini adalah "$userMood". '
          'Jika mood pengguna adalah "Sedih", "Marah", atau "Lelah", berikan respons empatik dan tanyakan mengapa mereka merasa seperti itu. Contoh: "Aku turut merasakannya. Kalau boleh cerita, kenapa kamu merasa $userMood hari ini?". '
          'Jika mood pengguna adalah "Senang" atau "Biasa Aja", berikan respons positif. Contoh: "Senang mendengarnya! Ada cerita menarik apa hari ini?". '
          'Gunakan Bahasa Indonesia yang santai.';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      return response.text ?? 'Maaf, aku sedang tidak bisa berpikir jernih saat ini.';
    } catch (e) {
      print('Error saat memanggil Gemini API (Initial): $e');
      return 'Oops, koneksiku sedang bermasalah.';
    }
  }

  // Fungsi untuk percakapan selanjutnya
  Future<String> getChatResponse(String userMessage, String aiName, List<String> chatHistory) async {
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);

      // Menggabungkan riwayat chat untuk memberikan konteks pada AI
      final history = chatHistory.join('\n');

      final prompt =
          'Peranmu adalah sebagai asisten AI bernama "$aiName". '
          'Anda ceria, positif, dan empatik. '
          'Berikut adalah riwayat percakapan sejauh ini:\n$history\n\n'
          'Sekarang, berikan respons untuk pesan terbaru dari pengguna: "$userMessage". '
          'Gunakan Bahasa Indonesia yang santai dan jangan ulangi sapaan jika percakapan sudah berjalan.';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      return response.text ?? 'Maaf, aku sedang tidak bisa berpikir jernih saat ini.';
    } catch (e) {
      print('Error saat memanggil Gemini API (Chat): $e');
      return 'Oops, koneksiku sedang bermasalah.';
    }
  }
}