import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fantasy_5omasi/models/user_model.dart';
import 'package:fantasy_5omasi/themes/app_color.dart';
import 'package:flutter/material.dart';

class AddPlayerModal extends StatefulWidget {
  final List<String> selectedIds;

  const AddPlayerModal({super.key, required this.selectedIds});

  @override
  State<AddPlayerModal> createState() => _AddPlayerModalState();
}

class _AddPlayerModalState extends State<AddPlayerModal> {
  List<UserModel> allUsers = [];
  List<UserModel> filteredUsers = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection("users").get();
    final users = snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data()))
        .where((user) => !widget.selectedIds.contains(user.uid))
        .toList();

    setState(() {
      allUsers = users;
      filteredUsers = users;
    });
  }

  void _filterUsers(String query) {
    setState(() {
      searchQuery = query;
      filteredUsers = allUsers
          .where((user) => user.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.secondary,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 16), // ← نزلنا السيرش بار شويه
        child: Column(
          children: [
            TextField(
              onChanged: _filterUsers,
              decoration: InputDecoration(
                hintText: "🔍 ابحث باسم اللاعب",
                filled: true,
                fillColor: AppColors.surface,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredUsers.isEmpty
                  ? const Center(
                      child: Text("🙁 لا يوجد لاعبين بهذا الاسم", style: TextStyle(color: Colors.white)),
                    )
                  : ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                          ),
                          title: Text(user.name, style: const TextStyle(color: Colors.white)),
                          onTap: () => Navigator.pop(context, user),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
