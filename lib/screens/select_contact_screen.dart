import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';

class SelectContactScreen extends StatefulWidget {
  const SelectContactScreen({super.key});

  @override
  State<SelectContactScreen> createState() => _SelectContactScreenState();
}

class _SelectContactScreenState extends State<SelectContactScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    _nameCtrl.clear();
    _phoneCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1F2C33),
          title: const Text('إضافة جهة اتصال جديدة', style: TextStyle(color: Color(0xFFE9EDEF), fontSize: 18)),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(color: Color(0xFFE9EDEF)),
                  decoration: InputDecoration(
                    labelText: 'الاسم',
                    labelStyle: const TextStyle(color: Color(0xFF8696A0)),
                    filled: true,
                    fillColor: const Color(0xFF2A3942),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'أدخل الاسم' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A3942),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('+966', style: TextStyle(color: Color(0xFFE9EDEF))),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneCtrl,
                        textDirection: TextDirection.ltr,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Color(0xFFE9EDEF)),
                        decoration: InputDecoration(
                          labelText: 'رقم الهاتف',
                          labelStyle: const TextStyle(color: Color(0xFF8696A0)),
                          filled: true,
                          fillColor: const Color(0xFF2A3942),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                        validator: (v) => v == null || v.trim().length < 9 ? 'رقم غير صحيح' : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Color(0xFF8696A0))),
            ),
            ElevatedButton(
              onPressed: () => _saveContact(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A884)),
              child: const Text('حفظ', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveContact(BuildContext dialogCtx) async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameCtrl.text.trim();
    final phone = '+966${_phoneCtrl.text.trim()}';

    try {
      await FirebaseService.users.doc(phone).set({
        'uid': phone,
        'phoneNumber': phone,
        'displayName': name,
        'email': '',
        'photoUrl': null,
        'status': 'مرحباً، أنا على واتساب',
        'isOnline': false,
        'lastSeen': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل حفظ جهة الاتصال')),
        );
      }
    }
  }

  Future<void> _startChat(AppUser user) async {
    final auth = context.read<AuthProvider>();
    final chatProv = context.read<ChatProvider>();
    final myUid = auth.userId;
    if (myUid.isEmpty) return;

    final participants = [myUid, user.uid];
    participants.sort();
    final chatId = participants.join('_');

    try {
      final doc = await FirebaseService.firestore.collection('chats').doc(chatId).get();
      if (!doc.exists) {
        await chatProv.createChat(
          participants,
          user.displayName,
          user.displayName[0].toUpperCase(),
        );
      }
      chatProv.selectChat(chatId, user.displayName, user.displayName[0].toUpperCase());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل بدء المحادثة')),
        );
      }
    }
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
        title: const Text('جهات الاتصال', style: TextStyle(color: Color(0xFFE9EDEF), fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE9EDEF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          InkWell(
            onTap: _showAddDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              color: const Color(0xFF111B21),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A884),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.person_add, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Text('جهة اتصال جديدة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFFE9EDEF))),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFF313D45)),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.firestore
                  .collection('users')
                  .orderBy('displayName')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('خطأ: ${snapshot.error}', style: const TextStyle(color: Color(0xFF8696A0))),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF00A884)));
                }
                final users = snapshot.data?.docs
                    .map((doc) => AppUser.fromMap(doc.data() as Map<String, dynamic>))
                    .where((u) => u.uid != myUid)
                    .toList() ?? [];

                if (users.isEmpty) {
                  return const Center(
                    child: Text('لا توجد جهات اتصال', style: TextStyle(color: Color(0xFF8696A0))),
                  );
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final initial = user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?';
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF313D45),
                        child: Text(initial, style: const TextStyle(color: Color(0xFFE9EDEF), fontWeight: FontWeight.bold)),
                      ),
                      title: Text(user.displayName, style: const TextStyle(color: Color(0xFFE9EDEF), fontSize: 16)),
                      subtitle: user.phoneNumber != null && user.phoneNumber!.isNotEmpty
                          ? Text(user.phoneNumber!, style: const TextStyle(color: Color(0xFF8696A0), fontSize: 13))
                          : Text(user.email.isNotEmpty ? user.email : '', style: const TextStyle(color: Color(0xFF8696A0), fontSize: 13)),
                      onTap: () => _startChat(user),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
