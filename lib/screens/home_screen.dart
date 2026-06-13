import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/firebase_service.dart';
import '../models/chat_model.dart';
import '../widgets/chat_list_widget.dart';
import 'chat_screen.dart';
import 'select_contact_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} د';
    if (diff.inDays < 1) return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 768;
    final chatProv = context.watch<ChatProvider>();
    final showChat = chatProv.selectedChatId != null;

    return Scaffold(
      backgroundColor: const Color(0xFF111B21),
      body: SafeArea(
        child: isWide ? _buildWideLayout() : _buildNarrowLayout(showChat),
      ),
    );
  }

  Widget _buildWideLayout() {
    final chatProv = context.watch<ChatProvider>();
    return Row(
      children: [
        SizedBox(width: 400, child: _buildMainView()),
        const VerticalDivider(width: 1, color: Color(0xFF313D45)),
        Expanded(
          child: chatProv.selectedChatId == null
              ? _buildWelcomePanel()
              : ChatScreen(
                  chatId: chatProv.selectedChatId!,
                  chatName: chatProv.selectedChatName!,
                  avatar: chatProv.selectedAvatar!,
                ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(bool showChat) {
    if (showChat) {
      final chatProv = context.watch<ChatProvider>();
      return ChatScreen(
        chatId: chatProv.selectedChatId!,
        chatName: chatProv.selectedChatName!,
        avatar: chatProv.selectedAvatar!,
        onBack: () => context.read<ChatProvider>().clearSelection(),
      );
    }
    return _buildMainView();
  }

  Widget _buildMainView() {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF111B21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF202C33),
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF00A884),
              child: Text(
                (auth.appUser?.displayName ?? 'U')[0].toUpperCase(),
                style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            const Text('WhatsApp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFE9EDEF))),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.camera_alt, color: Color(0xFFE9EDEF), size: 22), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search, color: Color(0xFFE9EDEF), size: 22), onPressed: () {}),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFFE9EDEF), size: 22),
            color: const Color(0xFF2A3942),
            onSelected: (v) async {
              if (v == 'logout') await auth.logout();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'new_group', child: Text('مجموعة جديدة', style: TextStyle(color: Color(0xFFE9EDEF)))),
              const PopupMenuItem(value: 'settings', child: Text('الإعدادات', style: TextStyle(color: Color(0xFFE9EDEF)))),
              const PopupMenuItem(value: 'logout', child: Text('تسجيل الخروج', style: TextStyle(color: Color(0xFFE9EDEF)))),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFF00A884),
          labelColor: const Color(0xFF00A884),
          unselectedLabelColor: const Color(0xFF8696A0),
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.groups, size: 22)),
            Tab(text: 'الدردشات'),
            Tab(text: 'الحالات'),
            Tab(text: 'المكالمات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildCommunitiesTab(),
          _buildChatsTab(),
          _buildStatusTab(),
          _buildCallsTab(),
        ],
      ),
      floatingActionButton: _tabCtrl.index == 1
          ? FloatingActionButton(
              mini: true,
              backgroundColor: const Color(0xFF00A884),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SelectContactScreen())),
              child: const Icon(Icons.chat, color: Colors.white, size: 24),
            )
          : _tabCtrl.index == 2
              ? FloatingActionButton(
                  mini: true,
                  backgroundColor: const Color(0xFF00A884),
                  onPressed: () {},
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
                )
              : null,
    );
  }

  Widget _buildChatsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: const Color(0xFF111B21),
          child: TextField(
            textDirection: ui.TextDirection.rtl,
            style: const TextStyle(color: Color(0xFFE9EDEF), fontSize: 14),
            decoration: InputDecoration(
              hintText: 'ابحث أو ابدأ محادثة جديدة',
              hintStyle: const TextStyle(color: Color(0xFF8696A0)),
              hintTextDirection: ui.TextDirection.rtl,
              prefixIcon: const Icon(Icons.search, color: Color(0xFF8696A0), size: 20),
              filled: true,
              fillColor: const Color(0xFF202C33),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseService.firestore
                .collection('chats')
                .orderBy('lastMessageAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Color(0xFF8696A0)),
                      const SizedBox(height: 8),
                      Text('خطأ: ${snapshot.error}', style: const TextStyle(color: Color(0xFF8696A0), fontSize: 13)),
                    ],
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF00A884)));
              }
              final chats = snapshot.data?.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return ChatModel.fromMap(data, doc.id);
              }).toList() ?? [];

              if (chats.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF202C33),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(Icons.chat_bubble_outline, size: 40, color: Color(0xFF8696A0)),
                      ),
                      const SizedBox(height: 16),
                      const Text('لا توجد محادثات', style: TextStyle(color: Color(0xFF8696A0), fontSize: 16)),
                      const SizedBox(height: 4),
                      const Text('ابدأ محادثة جديدة بالضغط على الزر أدناه', style: TextStyle(color: Color(0xFF313D45), fontSize: 13)),
                    ],
                  ),
                );
              }

              return ChatListWidget(
                chats: chats,
                selectedId: context.watch<ChatProvider>().selectedChatId,
                onChatTap: (id, name, avatar) {
                  context.read<ChatProvider>().selectChat(id, name, avatar);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTab() {
    return Container(
      color: const Color(0xFF111B21),
      child: ListView(
        padding: const EdgeInsets.only(top: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFF313D45),
                      child: Icon(Icons.person, size: 28, color: const Color(0xFF8696A0)),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 20, height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00A884),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('حالتي', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFFE9EDEF))),
                      const SizedBox(height: 2),
                      Text('اضغط لإضافة حالة', style: const TextStyle(fontSize: 13, color: Color(0xFF8696A0))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('التحديثات الأخيرة', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF00A884))),
          ),
          ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF313D45),
              child: const Icon(Icons.person, size: 24, color: Color(0xFF8696A0)),
            ),
            title: Text('أحمد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFFE9EDEF))),
            subtitle: Text('منذ 5 دقائق', style: const TextStyle(fontSize: 13, color: Color(0xFF8696A0))),
            onTap: () {},
          ),
          ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF313D45),
              child: const Icon(Icons.person, size: 24, color: Color(0xFF8696A0)),
            ),
            title: Text('سارة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFFE9EDEF))),
            subtitle: Text('منذ ساعة', style: const TextStyle(fontSize: 13, color: Color(0xFF8696A0))),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCallsTab() {
    return Container(
      color: const Color(0xFF111B21),
      child: ListView(
        padding: const EdgeInsets.only(top: 8),
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF00A884),
              child: const Icon(Icons.phone, size: 22, color: Colors.white),
            ),
            title: Text('رابط مكالمة جديد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFFE9EDEF))),
            subtitle: Text('إنشاء رابط مكالمة للمشاركة', style: const TextStyle(fontSize: 13, color: Color(0xFF8696A0))),
            onTap: () {},
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('الأحدث', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF00A884))),
          ),
          ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF313D45),
              child: const Icon(Icons.person, size: 24, color: Color(0xFF8696A0)),
            ),
            title: Text('أحمد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFFE9EDEF))),
            subtitle: Row(
              children: [
                Icon(Icons.call_made, size: 14, color: const Color(0xFF00A884)),
                const SizedBox(width: 4),
                Text('13 يونيو، 14:30', style: const TextStyle(fontSize: 13, color: Color(0xFF8696A0))),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.phone, color: Color(0xFF00A884)),
              onPressed: () {},
            ),
            onTap: () {},
          ),
          ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF313D45),
              child: const Icon(Icons.person, size: 24, color: Color(0xFF8696A0)),
            ),
            title: Text('سارة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFFE9EDEF))),
            subtitle: Row(
              children: [
                Icon(Icons.call_received, size: 14, color: const Color(0xFF8696A0)),
                const SizedBox(width: 4),
                Text('12 يونيو، 09:15', style: const TextStyle(fontSize: 13, color: Color(0xFF8696A0))),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.phone, color: Color(0xFF00A884)),
              onPressed: () {},
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCommunitiesTab() {
    return Container(
      color: const Color(0xFF111B21),
      child: ListView(
        padding: const EdgeInsets.only(top: 8),
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF202C33),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A884).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.groups, size: 32, color: Color(0xFF00A884)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('المجتمعات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE9EDEF))),
                      const SizedBox(height: 4),
                      Text('نظّم مجموعاتك في مجتمعات', style: TextStyle(fontSize: 13, color: const Color(0xFF8696A0))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF313D45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add, size: 24, color: Color(0xFF00A884)),
            ),
            title: Text('إنشاء مجتمع جديد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFFE9EDEF))),
            subtitle: Text('أضف مجموعاتك في مكان واحد', style: const TextStyle(fontSize: 13, color: Color(0xFF8696A0))),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePanel() {
    return Container(
      color: const Color(0xFF222E35),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF202C33),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(Icons.chat, size: 60, color: Color(0xFF8696A0)),
            ),
            const SizedBox(height: 24),
            const Text('WhatsApp Clone', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: Color(0xFFE9EDEF))),
            const SizedBox(height: 8),
            const Text('اختر محادثة لبدء المراسلة', style: TextStyle(fontSize: 14, color: Color(0xFF8696A0))),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: const Color(0xFF182229),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF313D45)),
              ),
              child: const Text(
                'اضغط على محادثة من القائمة اليسرى لبدء المراسلة\nأو استخدم زر الدردشة لبدء محادثة جديدة',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8696A0), fontSize: 13, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
