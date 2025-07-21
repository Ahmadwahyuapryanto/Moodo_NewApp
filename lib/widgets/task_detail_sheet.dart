import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:moodo_app/models/task_model.dart';
import 'package:moodo_app/screens/pomodoro_screen.dart';
import 'package:moodo_app/screens/task_completion_screen.dart';

class TaskDetailSheet extends StatefulWidget {
  final Task task;
  const TaskDetailSheet({super.key, required this.task});

  @override
  State<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<TaskDetailSheet> {
  final TextEditingController _noteController = TextEditingController();

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

  void _addOrUpdateNote({Map<String, dynamic>? noteToEdit, int? index}) {
    if (noteToEdit != null) {
      _noteController.text = noteToEdit['text'];
    } else {
      _noteController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(noteToEdit == null ? 'Tambah Catatan' : 'Edit Catatan'),
        content: TextField(
          controller: _noteController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Tulis catatanmu di sini'),
        ),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Simpan'),
            onPressed: () async {
              if (_noteController.text.isEmpty) return;

              final newNote = {
                'text': _noteController.text,
                'createdAt': Timestamp.now(),
              };

              final taskDoc = await FirebaseFirestore.instance.collection('tasks').doc(widget.task.id).get();
              final latestTask = Task.fromFirestore(taskDoc);
              List<Map<String, dynamic>> currentNotes = List.from(latestTask.notes);

              if (noteToEdit != null && index != null) {
                currentNotes[index] = newNote;
              } else {
                currentNotes.add(newNote);
              }

              await FirebaseFirestore.instance
                  .collection('tasks')
                  .doc(widget.task.id)
                  .update({'notes': currentNotes});

              _noteController.clear();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _deleteNote(int index) async {
    final taskDoc = await FirebaseFirestore.instance.collection('tasks').doc(widget.task.id).get();
    final latestTask = Task.fromFirestore(taskDoc);
    List<Map<String, dynamic>> currentNotes = List.from(latestTask.notes);
    currentNotes.removeAt(index);
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(widget.task.id)
        .update({'notes': currentNotes});
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Catatan Pribadi',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => _addOrUpdateNote(),
                            color: Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      SizedBox(
                        height: 200,
                        child: updatedTask.notes.isEmpty
                            ? const Center(child: Text('Belum ada catatan.'))
                            : ListView.builder(
                          itemCount: updatedTask.notes.length,
                          itemBuilder: (context, index) {
                            final note = updatedTask.notes[index];
                            return ListTile(
                              leading: const Icon(Icons.note_alt_outlined),
                              title: Text(note['text']),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    onPressed: () => _addOrUpdateNote(
                                        noteToEdit: note, index: index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 20, color: Colors.redAccent),
                                    onPressed: () => _deleteNote(index),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
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