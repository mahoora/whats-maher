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
  Map<String, dynamic>? _rawDoc;

  @override
  void initState() {
    super.initState();
    _loadDoc();
  }

  Future<void> _loadDoc() async {
    final auth = context.read<AuthProvider>();
    final uid = auth.userId;
    if (uid.isEmpty) return;
    try {
      final doc = await FirebaseService.firestore.collection('users').doc(uid).get();
      if (mounted && doc.exists) {
        setState(() => _rawDoc = doc.data() as Map<String, dynamic>?);
        _nameCtrl.text = _rawDoc?['displayName'] as String? ?? auth.appUser?.displayName ?? '';
      } else if (mounted) {
        // Doc doesn't exist — create it
        final email = auth.firebaseUser?.email ?? '';
        final defaultData = {
          'uid': uid,
          'email': email,
          'displayName': email.split('@').first,
          'photoUrl': null,
          'status': 'مرحباً، أنا على واتساب',
          'isOnline': true,
          'lastSeen': DateTime.now().toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
        };
        await FirebaseService.firestore.collection('users').doc(uid).set(defaultData);
        setState(() => _rawDoc = defaultData);
        _nameCtrl.text = defaultData['displayName'] as String;
      }
    } catch (e) {
      html.window.console.error('Load doc error: $e');
    }
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
      html.window.console.log('Saving: $uid');

      // Read existing doc
      final doc = await FirebaseService.firestore.collection('users').doc(uid).get();
      final data = doc.exists
          ? Map<String, dynamic>.from(doc.data() as Map)
          : <String, dynamic>{
              'uid': uid,
              'email': auth.firebaseUser?.email ?? '',
              'displayName': name,
              'photoUrl': null,
              'status': 'مرحباً، أنا على واتساب',
              'isOnline': true,
              'lastSeen': DateTime.now().toIso8601String(),
              'createdAt': DateTime.now().toIso8601String(),
            };

      data['displayName'] = name;
      data['updatedAt'] = DateTime.now().toIso8601String();
      if (_photoBase64 != null) {
        data['photoUrl'] = _photoBase64;
      }

      // Write ENTIRE document (not merge) — avoids permission issues
      await FirebaseService.firestore.collection('users').doc(uid).set(data);
      html.window.console.log('Saved OK');

      // Reload
      setState(() => _rawDoc = data);
      // Reload profile in AuthProvider so home screen updates
      if (mounted) {
        context.read<AuthProvider>().reloadProfile();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ')));
        Navigator.pop(context);
      }
    } catch (e) {
      html.window.console.error('Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), duration: const Duration(seconds: 8)),
        );
      }
    }
    setState(() => _saving = false);
  }

  Future<void> _testWrite() async {
    final uid = context.read<AuthProvider>().userId;
    if (uid.isEmpty) return;
    try {
      // Test 1: simple set
      html.window.console.log('TEST: writing test field');
      await FirebaseService.firestore.collection('users').doc(uid).set({'testField': 'ok'}, SetOptions(merge: true));
      html.window.console.log('TEST write OK');

      // Test 2: add to contacts collection (not nested)
      await FirebaseService.firestore.collection('contacts_test').add({
        'uid': uid, 'name': 'test', 'createdAt': Timestamp.now(),
      });
      html.window.console.log('TEST contacts add OK');

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختبار الكتابة نجح')));
    } catch (e) {
      html.window.console.error('TEST error: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1F2C33),
            title: const Text('خطأ', style: TextStyle(color: Colors.red)),
            content: Text('$e', style: const TextStyle(color: Color(0xFFE9EDEF), fontSize: 14)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً'))
            ],
          ),
        );
      }
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: Color(0xFF8696A0)),
            onPressed: _testWrite,
          ),
        ],
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
                        : (_rawDoc?['photoUrl'] != null && (_rawDoc!['photoUrl'] as String).isNotEmpty
                            ? ((_rawDoc!['photoUrl'] as String).startsWith('data:')
                                ? MemoryImage(base64Decode((_rawDoc!['photoUrl'] as String).split(',').last))
                                : NetworkImage(_rawDoc!['photoUrl'] as String))
                            : null),
                    child: _photoBase64 == null && (_rawDoc?['photoUrl'] == null || (_rawDoc!['photoUrl'] as String).isEmpty)
                        ? Text(
                            (_rawDoc?['displayName'] ?? 'U')[0].toUpperCase(),
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
                _infoRow('البريد', _rawDoc?['email'] as String? ?? ''),
                const Divider(color: Color(0xFF313D45), height: 1),
                _infoRow('الحالة', _rawDoc?['status'] as String? ?? '(فارغ)'),
                const Divider(color: Color(0xFF313D45), height: 1),
                Text('آخر ظهور: ${_rawDoc?['lastSeen'].runtimeType ?? 'null'}', style: const TextStyle(color: Color(0xFF8696A0), fontSize: 12)),
              ],
            ),
          ),
          if (_rawDoc != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2C33),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('تشخيص - مفاتيح المستند', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF00A884))),
                  const SizedBox(height: 8),
                  Text(_rawDoc!.keys.join(', '), style: const TextStyle(color: Color(0xFF8696A0), fontSize: 11)),
                ],
              ),
            ),
          ],
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
