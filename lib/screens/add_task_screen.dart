import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:moodo_app/screens/search_users_screen.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  String _taskType = 'individual';
  List<String> _groupMembers = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _presentDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _openSearchUsersScreen() async {
    final selectedUids = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => SearchUsersScreen(initialMembers: _groupMembers),
      ),
    );

    if (selectedUids != null) {
      setState(() {
        _groupMembers = selectedUids;
      });
    }
  }

  Future<void> _submitTask() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih tenggat waktu.')),
        );
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      List<String> finalMembers = List.from(_groupMembers);
      if (!finalMembers.contains(user.uid)) {
        finalMembers.add(user.uid);
      }

      try {
        await FirebaseFirestore.instance.collection('tasks').add({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'deadline': Timestamp.fromDate(_selectedDate!),
          'type': _taskType,
          'isCompleted': false,
          'leader': user.uid,
          'members': _taskType == 'group' ? finalMembers : [user.uid],
          'comments': [],
          'notes': [], // --- PERBAIKAN DI SINI: Inisialisasi notes ---
          'createdAt': FieldValue.serverTimestamp(),
          'memberStatus': {}
        });

        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan tugas: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Tugas Baru'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submitTask,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Judul Tugas'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Judul tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? 'Pilih Tenggat Waktu'
                          : 'Tenggat: ${DateFormat.yMd().format(_selectedDate!)}',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _presentDatePicker,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _taskType,
                decoration: const InputDecoration(labelText: 'Jenis Tugas'),
                items: const [
                  DropdownMenuItem(
                    value: 'individual',
                    child: Text('Tugas Mandiri'),
                  ),
                  DropdownMenuItem(
                    value: 'group',
                    child: Text('Tugas Kelompok'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _taskType = value!;
                  });
                },
              ),
              if (_taskType == 'group') ...[
                const SizedBox(height: 24),
                const Text('Anggota Kelompok',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.group_add),
                  label: const Text('Undang Anggota'),
                  onPressed: _openSearchUsersScreen,
                ),
                const SizedBox(height: 8),
                Text('${_groupMembers.length} anggota dipilih.'),
              ]
            ],
          ),
        ),
      ),
    );
  }
}