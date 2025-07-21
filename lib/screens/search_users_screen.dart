import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// --- TAMBAHKAN BARIS INI UNTUK MEMPERBAIKI EROR ---
import 'package:firebase_auth/firebase_auth.dart';
// ----------------------------------------------------

class SearchUsersScreen extends StatefulWidget {
  final List<String> initialMembers;
  const SearchUsersScreen({super.key, required this.initialMembers});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  List<String> _selectedMemberUids = [];
  bool _hasSearched = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedMemberUids = List.from(widget.initialMembers);
  }

  void _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isGreaterThanOrEqualTo: query.trim())
        .where('email', isLessThanOrEqualTo: '${query.trim()}\uf8ff')
        .limit(10)
        .get();

    setState(() {
      _searchResults = result.docs;
      _isLoading = false;
    });
  }

  void _toggleMember(String uid) {
    setState(() {
      if (_selectedMemberUids.contains(uid)) {
        _selectedMemberUids.remove(uid);
      } else {
        _selectedMemberUids.add(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Undang Anggota'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, _selectedMemberUids);
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Cari pengguna berdasarkan email',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchUsers,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isNotEmpty
                ? ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                var user = _searchResults[index].data() as Map<String, dynamic>;
                String uid = user['uid'];
                bool isSelected = _selectedMemberUids.contains(uid);

                // Jangan tampilkan diri sendiri di hasil pencarian
                if (uid == FirebaseAuth.instance.currentUser?.uid) {
                  return const SizedBox.shrink();
                }

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(user['displayName'][0].toUpperCase()),
                  ),
                  title: Text(user['displayName']),
                  subtitle: Text(user['email']),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) {
                      _toggleMember(uid);
                    },
                  ),
                  onTap: () => _toggleMember(uid),
                );
              },
            )
                : _hasSearched
                ? const Center(
              child: Text(
                'Tidak ada user tersebut.',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Ketik email pengguna untuk memulai pencarian.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}