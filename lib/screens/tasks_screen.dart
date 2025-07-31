// lib/screens/tasks_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moodo_app/models/motivasi_quote.dart';
import 'package:moodo_app/models/task_model.dart';
import 'package:moodo_app/screens/add_task_screen.dart';
import 'package:moodo_app/widgets/group_task_detail_sheet.dart';
import 'package:moodo_app/widgets/task_card.dart';
import 'package:moodo_app/widgets/task_detail_sheet.dart';
import 'package:lottie/lottie.dart'; // Jangan lupa import Lottie

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String randomQuote = MotivasiQuote.getRandomQuote();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showTaskDetail(Task task) {
    if (task.type == 'individual') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => TaskDetailSheet(task: task),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => GroupTaskDetailSheet(task: task),
      );
    }
  }

  // --- WIDGET INI YANG DIPERBARUI ---
  Widget _buildTaskList(String taskType) {
    if (currentUser == null) {
      return const Center(child: Text("Silakan login terlebih dahulu."));
    }

    Query query = FirebaseFirestore.instance
        .collection('tasks')
        .where('isCompleted', isEqualTo: false);

    if (taskType == 'group') {
      query = query.where('members', arrayContains: currentUser!.uid)
          .where('type', isEqualTo: 'group');
    } else {
      query = query.where('leader', isEqualTo: currentUser!.uid)
          .where('type', isEqualTo: 'individual');
    }

    query = query.orderBy('deadline');

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                    "Terjadi error. Pastikan Anda sudah membuat indeks komposit yang benar di Firebase.\nError: ${snapshot.error}", textAlign: TextAlign.center),
              ));
        }
        // --- PERUBAHAN DI SINI ---
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // Tampilkan animasi dan teks jika tidak ada tugas
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/animations/Task.json', // Path ke file animasi Anda
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tidak Ada tugas aktif.\nSilahkan tambahkan Tugas Baru',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }
        // --- AKHIR PERUBAHAN ---

        final tasks = snapshot.data!.docs
            .map((doc) => Task.fromFirestore(doc))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return TaskCard(
              task: task,
              onTap: () => _showTaskDetail(task),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.purple.shade100 : const Color(0xFFD6E6FF);
    final textColor = isDarkMode ? Colors.black87 : Theme.of(context).textTheme.bodyMedium?.color;
    final titleColor = isDarkMode ? Colors.black : Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Moodo To-do List',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Motivasi Hari Ini',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        randomQuote,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Tugas Mandiri'),
                Tab(text: 'Tugas Kelompok'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tugas Mandiri',
                                style: TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle, size: 32),
                              color: Theme.of(context).primaryColor,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const AddTaskScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: _buildTaskList('individual')),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tugas Kelompok',
                                style: TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle, size: 32),
                              color: Theme.of(context).primaryColor,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const AddTaskScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: _buildTaskList('group')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}