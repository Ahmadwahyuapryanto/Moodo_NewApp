// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:moodo_app/screens/tasks_screen.dart';
import 'package:moodo_app/screens/calendar_screen.dart';
import 'package:moodo_app/screens/profile_screen.dart';
// --- TAMBAHKAN IMPORT UNTUK HALAMAN AI BARU ---
import 'package:moodo_app/screens/ai_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // --- TAMBAHKAN HALAMAN AI KE DALAM DAFTAR ---
  static const List<Widget> _pages = <Widget>[
    TasksScreen(),
    CalendarScreen(),
    AiChatScreen(), // Halaman AI ditambahkan di sini
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      // --- TAMBAHKAN TOMBOL NAVIGASI UNTUK AI ---
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Tugas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Kalender',
          ),
          // Ini adalah tombol baru Anda
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_emotions_outlined),
            activeIcon: Icon(Icons.emoji_emotions),
            label: 'Asisten',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        // Properti di bawah ini penting agar semua item terlihat
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        unselectedItemColor: Colors.grey,
        selectedItemColor: Theme.of(context).primaryColor,
      ),
    );
  }
}