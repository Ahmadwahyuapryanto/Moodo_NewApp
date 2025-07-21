import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:moodo_app/models/task_model.dart';
import 'package:moodo_app/screens/pomodoro_screen.dart';
import 'package:moodo_app/screens/task_completion_screen.dart';

class GroupTaskDetailSheet extends StatefulWidget {
  final Task task;

  const GroupTaskDetailSheet({super.key, required this.task});

  @override
  State<GroupTaskDetailSheet> createState() => _GroupTaskDetailSheetState();
}

class _GroupTaskDetailSheetState extends State<GroupTaskDetailSheet> {
  final TextEditingController _commentController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final ScrollController _scrollController = ScrollController();

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty || currentUser == null) {
      return;
    }

    final newComment = {
      'text': _commentController.text.trim(),
      'senderId': currentUser!.uid,
      'senderName': currentUser!.displayName ?? 'Tanpa Nama',
      'timestamp': Timestamp.now(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.task.id)
          .update({
        'comments': FieldValue.arrayUnion([newComment])
      });
      _commentController.clear();
      FocusScope.of(context).unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim komentar: $e')),
      );
    }
  }

  void _markTaskAsDone(BuildContext context, String taskTitle) {
    FirebaseFirestore.instance
        .collection('tasks')
        .doc(widget.task.id)
        .update({'isCompleted': true});

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TaskCompletionScreen(taskTitle: taskTitle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.task.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final updatedTask = Task.fromFirestore(snapshot.data!);
        final sisaHari = updatedTask.deadline.difference(DateTime.now()).inDays;

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF0F4F8),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                Text(
                  updatedTask.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF001E4C)),
                ),
                const SizedBox(height: 8),
                Text(
                    'Deadline : ${DateFormat('d MMMM yyyy').format(updatedTask.deadline)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.black54)),
                if (sisaHari >= 0) ...[
                  const SizedBox(height: 4),
                  Text('Sisa : $sisaHari Hari Lagi',
                      textAlign: TextAlign.center,
                      style:
                      const TextStyle(fontSize: 16, color: Colors.black54)),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      PomodoroScreen(task: updatedTask)));
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child:
                        const Text('Kerjakan', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _markTaskAsDone(context, updatedTask.title),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child:
                        const Text('Selesai', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.0)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Diskusi Kelompok',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const Divider(height: 24),
                      SizedBox(
                        height: 200,
                        child: updatedTask.comments.isEmpty
                            ? const Center(child: Text('Belum ada komentar.'))
                            : ListView.builder(
                          controller: _scrollController,
                          itemCount: updatedTask.comments.length,
                          itemBuilder: (context, index) {
                            final comment = updatedTask.comments[index];
                            final bool isMe = comment['senderId'] == currentUser?.uid;
                            return Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 4),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Theme.of(context).primaryColor.withOpacity(0.2)
                                      : Colors.grey.shade200,
                                  borderRadius:
                                  BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(comment['senderName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(comment['text']),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: const InputDecoration(
                                hintText: 'Ketik pesan...',
                                border: OutlineInputBorder(),
                                contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: _addComment,
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}