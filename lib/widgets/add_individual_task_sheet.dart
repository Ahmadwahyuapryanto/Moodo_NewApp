// lib/widgets/add_individual_task_sheet.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddIndividualTaskSheet extends StatefulWidget {
  const AddIndividualTaskSheet({super.key});

  @override
  State<AddIndividualTaskSheet> createState() => _AddIndividualTaskSheetState();
}

class _AddIndividualTaskSheetState extends State<AddIndividualTaskSheet> {
  final _titleController = TextEditingController();
  DateTime? _selectedDate;

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul tugas harus diisi!')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('tasks').add({
        'title': title,
        'deadline': _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
        'type': 'mandiri',
        'isCompleted': false,
        'createdAt': Timestamp.now(),
        'notes': [],
        'leader': null,
        'memberStatus': {},
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan tugas: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Padding agar keyboard tidak menutupi sheet
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 10, 0, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFD6E6FF), // Warna biru muda
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle kecil di atas
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextField(
                controller: _titleController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Tambahkan Tugas',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              _selectedDate == null
                                  ? 'Deadline'
                                  : DateFormat('dd MMM yyyy').format(_selectedDate!),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.all(12)),
                    icon: const Icon(Icons.send),
                    onPressed: _saveTask,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}