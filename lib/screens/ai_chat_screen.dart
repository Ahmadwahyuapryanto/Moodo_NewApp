// lib/screens/ai_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moodo_app/services/ai_chat_service.dart';

// Model untuk menampung pesan (tidak berubah)
class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final AiChatService _aiService = AiChatService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isLoading = false;
  bool _moodSelected = false; // State untuk menandai apakah mood sudah dipilih
  String _aiName = 'Moodo'; // Nama default AI

  @override
  void initState() {
    super.initState();
    _fetchAiName();
  }

  // Mengambil nama AI dari pengaturan pengguna
  Future<void> _fetchAiName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (mounted && doc.exists && doc.data() != null) {
      final senderName = doc.data()!['notificationSenderName'] as String?;
      if (senderName != null && senderName.isNotEmpty) {
        setState(() {
          _aiName = senderName;
        });
      }
    }
  }

  // Fungsi yang dijalankan saat mood dipilih
  Future<void> _handleMoodSelection(String mood) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    // 1. Simpan mood ke Firestore
    try {
      await FirebaseFirestore.instance.collection('mood_history').add({
        'userId': user.uid,
        'mood': mood,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Gagal menyimpan mood: $e");
    }

    // Tambahkan pesan mood pengguna ke UI
    _addMessage('Hari ini aku merasa $mood', true);

    // 2. Dapatkan respons awal dari AI
    final response = await _aiService.getInitialResponse(mood, _aiName);
    _addMessage(response, false);

    // 3. Ubah UI ke mode chat
    setState(() {
      _isLoading = false;
      _moodSelected = true;
    });
  }

  // Fungsi untuk mengirim pesan chat lanjutan
  Future<void> _sendMessage() async {
    final messageText = _textController.text.trim();
    if (messageText.isEmpty) return;

    _addMessage(messageText, true);
    _textController.clear();
    setState(() { _isLoading = true; });

    // Membuat riwayat chat untuk konteks AI
    final chatHistory = _messages.map((m) => "${m.isUser ? 'User' : _aiName}: ${m.text}").toList();

    // Panggil service AI untuk mendapatkan balasan
    final response = await _aiService.getChatResponse(messageText, _aiName, chatHistory);
    _addMessage(response, false);
    setState(() { _isLoading = false; });
  }

  // Helper untuk menambah pesan dan auto-scroll
  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: isUser));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Asisten $_aiName'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Tampilkan chat jika mood sudah dipilih
          if (_moodSelected)
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildChatBubble(_messages[index]);
                },
              ),
            ),

          // Tampilkan pilihan mood jika belum dipilih
          if (!_moodSelected)
            Expanded(
              child: _buildMoodSelectionArea(),
            ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),

          // Tampilkan area input teks jika mood sudah dipilih
          if (_moodSelected)
            _buildTextInputArea(),
        ],
      ),
    );
  }

  // UI untuk area pemilihan mood
  Widget _buildMoodSelectionArea() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Hai! Bagaimana perasaanmu hari ini?',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildMoodButton('😄 Senang'),
                _buildMoodButton('🙂 Biasa Aja'),
                _buildMoodButton('😥 Sedih'),
                _buildMoodButton('😠 Marah'),
                _buildMoodButton('😫 Lelah'),
              ],
            )
          ],
        ),
      ),
    );
  }

  // UI untuk gelembung chat
  Widget _buildChatBubble(ChatMessage message) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isUser
              ? Theme.of(context).primaryColor
              : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser
                ? Colors.white
                : (isDarkMode ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  // UI untuk area input teks
  Widget _buildTextInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(color: Theme.of(context).cardColor),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration.collapsed(hintText: 'Balas pesan...'),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _isLoading ? null : _sendMessage,
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  // UI untuk tombol mood
  Widget _buildMoodButton(String mood) {
    return ElevatedButton(
      onPressed: _isLoading ? null : () => _handleMoodSelection(mood),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 16),
      ),
      child: Text(mood),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}