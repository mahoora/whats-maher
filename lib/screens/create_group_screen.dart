import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameCtrl = TextEditingController();
  final _selected = <String>{};
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _selected.isEmpty) return;
    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final chatProv = context.read<ChatProvider>();
    final participants = [auth.userId, ..._selected];
    participants.sort();

    try {
      final chatId = await chatProv.createChat(participants, name, name[0].toUpperCase());
      chatProv.selectChat(chatId, name, name[0].toUpperCase());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final myUid = auth.userId;

    return Scaffold(
      backgroundColor: const Color(0xFF111B21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF202C33),
        elevation: 0,
        title: const Text('مجموعة جديدة', style: TextStyle(color: Color(0xFFE9EDEF), fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE9EDEF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _nameCtrl,
              textDirection: ui.TextDirection.rtl,
              style: const TextStyle(color: Color(0xFFE9EDEF), fontSize: 16),
              decoration: InputDecoration(
                labelText: 'اسم المجموعة',
                labelStyle: const TextStyle(color: Color(0xFF8696A0)),
                filled: true,
                fillColor: const Color(0xFF2A3942),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('${_selected.length} مشارك تم اختياره', style: const TextStyle(color: Color(0xFF8696A0), fontSize: 13)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.firestore
                  .collection('users')
                  .orderBy('displayName')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF00A884)));

                final users = snapshot.data!.docs
                    .map((doc) => AppUser.fromMap(doc.data() as Map<String, dynamic>))
                    .where((u) => u.uid != myUid)
                    .toList();

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final isSelected = _selected.contains(user.uid);
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: isSelected ? const Color(0xFF00A884) : const Color(0xFF313D45),
                        child: Text(
                          user.displayName[0].toUpperCase(),
                          style: const TextStyle(color: Color(0xFFE9EDEF), fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(user.displayName, style: const TextStyle(color: Color(0xFFE9EDEF), fontSize: 16)),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Color(0xFF00A884))
                          : const Icon(Icons.circle_outlined, color: Color(0xFF8696A0)),
                      onTap: () {
                        setState(() {
                          if (isSelected) _selected.remove(user.uid);
                          else _selected.add(user.uid);
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _selected.isNotEmpty && _nameCtrl.text.trim().isNotEmpty
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF00A884),
              onPressed: _isLoading ? null : _createGroup,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : const Icon(Icons.arrow_forward, color: Colors.white),
            )
          : null,
    );
  }
}
