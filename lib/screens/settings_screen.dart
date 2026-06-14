import 'dart:html' as html;
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  String? _photoBase64;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().appUser;
    if (user != null) _nameCtrl.text = user.displayName;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _pickImage() {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    input.onChange.listen((e) {
      final files = input.files;
      if (files!.isEmpty) return;
      final reader = html.FileReader();
      reader.readAsDataUrl(files[0]);
      reader.onLoadEnd.listen((_) {
        if (mounted) setState(() => _photoBase64 = reader.result as String?);
      });
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final auth = context.read<AuthProvider>();
    final uid = auth.userId;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);

    try {
      final data = <String, dynamic>{
        'displayName': name,
        'updatedAt': Timestamp.now(),
      };
      if (_photoBase64 != null) {
        data['photoUrl'] = _photoBase64;
      }

      html.window.console.log('Saving profile uid=$uid data=${data.keys}');
      await FirebaseService.firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
      html.window.console.log('Profile saved successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ')));
        Navigator.pop(context);
      }
    } catch (e) {
      html.window.console.error('Save profile error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), duration: const Duration(seconds: 5)),
        );
      }
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.appUser;

    return Scaffold(
      backgroundColor: const Color(0xFF111B21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF202C33),
        elevation: 0,
        title: const Text('الإعدادات', style: TextStyle(color: Color(0xFFE9EDEF), fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE9EDEF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: const Color(0xFF313D45),
                    backgroundImage: _photoBase64 != null
                        ? MemoryImage(base64Decode(_photoBase64!.split(',').last))
                        : (user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                            ? (user.photoUrl!.startsWith('data:')
                                ? MemoryImage(base64Decode(user.photoUrl!.split(',').last))
                                : NetworkImage(user.photoUrl!))
                            : null),
                    child: _photoBase64 == null && (user?.photoUrl == null || user!.photoUrl!.isEmpty)
                        ? Text(
                            (user?.displayName ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(fontSize: 36, color: Color(0xFFE9EDEF)),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 32, height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00A884), shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nameCtrl,
            textDirection: ui.TextDirection.rtl,
            style: const TextStyle(color: Color(0xFFE9EDEF), fontSize: 16),
            decoration: InputDecoration(
              labelText: 'الاسم',
              labelStyle: const TextStyle(color: Color(0xFF8696A0)),
              filled: true,
              fillColor: const Color(0xFF2A3942),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2C33),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('معلومات الحساب', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF00A884))),
                const SizedBox(height: 12),
                _infoRow('البريد', user?.email ?? ''),
                const Divider(color: Color(0xFF313D45), height: 1),
                _infoRow('الحالة', user?.status ?? ''),
                const Divider(color: Color(0xFF313D45), height: 1),
                _infoRow('آخر ظهور', user?.lastSeen?.toString() ?? ''),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A884),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('حفظ', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Color(0xFF8696A0), fontSize: 14)),
          Expanded(
            child: Text(value, style: const TextStyle(color: Color(0xFFE9EDEF), fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
