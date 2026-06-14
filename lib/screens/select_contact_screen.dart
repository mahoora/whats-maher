import 'dart:html' as html;
import 'dart:convert';
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
  String _countryCode = '+966';

  final _countries = [
    'SA', 'AE', 'EG', 'KW', 'QA', 'BH', 'OM', 'IQ', 'YE', 'SY', 'JO', 'LB', 'PS',
    'DZ', 'MA', 'TN', 'LY', 'SD',
  ];
  final _codes = {
    'SA': '+966', 'AE': '+971', 'EG': '+20', 'KW': '+965', 'QA': '+974',
    'BH': '+973', 'OM': '+968', 'IQ': '+964', 'YE': '+967', 'SY': '+963',
    'JO': '+962', 'LB': '+961', 'PS': '+970', 'DZ': '+213', 'MA': '+212',
    'TN': '+216', 'LY': '+218', 'SD': '+249',
  };
  final _names = {
    'SA': 'السعودية', 'AE': 'الإمارات', 'EG': 'مصر', 'KW': 'الكويت', 'QA': 'قطر',
    'BH': 'البحرين', 'OM': 'عمان', 'IQ': 'العراق', 'YE': 'اليمن', 'SY': 'سوريا',
    'JO': 'الأردن', 'LB': 'لبنان', 'PS': 'فلسطين', 'DZ': 'الجزائر', 'MA': 'المغرب',
    'TN': 'تونس', 'LY': 'ليبيا', 'SD': 'السودان',
  };

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
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A3942),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _countryCode,
                          dropdownColor: const Color(0xFF2A3942),
                          style: const TextStyle(color: Color(0xFFE9EDEF), fontSize: 14),
                          items: _countries.map((c) {
                            return DropdownMenuItem(
                              value: _codes[c],
                              child: Text('${_codes[c]} (${_names[c]})'),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _countryCode = v!),
                        ),
                      ),
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
                        validator: (v) => v == null || v.trim().length < 6 ? 'رقم غير صحيح' : null,
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
    final phone = '$_countryCode${_phoneCtrl.text.trim().replaceAll(RegExp(r'\s'), '')}';

    try {
      final auth = context.read<AuthProvider>();
      final uid = auth.userId;
      if (uid.isEmpty) throw Exception('غير مصرح');
      final phoneKey = phone.replaceAll('+', '');

      html.window.console.log('Saving contact uid=$uid phone=$phone');

      // Read existing user doc
      final userDoc = FirebaseService.firestore.collection('users').doc(uid);
      final docSnap = await userDoc.get();

      if (!docSnap.exists) {
        html.window.console.log('User doc $uid does not exist, creating');
        await userDoc.set({
          'uid': uid,
          'email': auth.appUser?.email ?? '',
          'displayName': auth.appUser?.displayName ?? '',
          'contacts': {
            phoneKey: {
              'phoneNumber': phone,
              'displayName': name,
              'createdAt': DateTime.now().toIso8601String(),
            },
          },
        });
      } else {
        html.window.console.log('User doc $uid exists, updating contacts');
        final data = docSnap.data() as Map<String, dynamic>;
        final contacts = data['contacts'] is Map ? Map<String, dynamic>.from(data['contacts'] as Map) : <String, dynamic>{};
        contacts[phoneKey] = {
          'phoneNumber': phone,
          'displayName': name,
          'createdAt': DateTime.now().toIso8601String(),
        };
        await userDoc.set({'contacts': contacts}, SetOptions(merge: true));
      }

      html.window.console.log('Contact saved successfully');
      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ')));
    } catch (e) {
      html.window.console.error('Save contact error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), duration: const Duration(seconds: 5)),
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
      html.window.console.error('Start chat error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
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
