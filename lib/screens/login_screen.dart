import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController(text: '5');
  final _otpCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _code = '+966';

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;
    final auth = context.watch<AuthProvider>();
    final isNewUser = auth.isAuthenticated && auth.isNewUser;
    final showOtp = auth.otpSent && !auth.isAuthenticated;

    return Scaffold(
      backgroundColor: const Color(0xFF111B21),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isWide ? 48 : 24, vertical: 32),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: EdgeInsets.all(isWide ? 40 : 24),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2C33),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A884),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.chat, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isNewUser ? 'أنشئ حسابك' : showOtp ? 'تأكيد الرقم' : 'واتساب كلون',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFE9EDEF)),
                    ),
                    Text(
                      isNewUser ? 'أدخل اسمك الظاهر' : showOtp ? 'أدخل رمز التحقق المرسل' : 'أدخل رقم هاتفك',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF8696A0)),
                    ),
                    const SizedBox(height: 24),

                    if (isNewUser) ..._buildNameInput(auth)
                    else if (showOtp) ..._buildOtpInput(auth)
                    else ..._buildPhoneInput(auth),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPhoneInput(AuthProvider auth) {
    return [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF2A3942),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_code, style: const TextStyle(color: Color(0xFFE9EDEF), fontSize: 16)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: Color(0xFFE9EDEF), fontSize: 16),
              decoration: InputDecoration(
                hintText: '5XXXXXXXX',
                hintStyle: const TextStyle(color: Color(0xFF8696A0), fontSize: 16),
                hintTextDirection: TextDirection.ltr,
                filled: true,
                fillColor: const Color(0xFF2A3942),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              validator: (v) => v == null || v.length < 9 ? 'رقم غير صحيح' : null,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (auth.error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(auth.error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
        ),
      SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: auth.isLoading ? null : _sendOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A884),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: auth.isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('إرسال رمز التحقق', style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
      ),
    ];
  }

  List<Widget> _buildOtpInput(AuthProvider auth) {
    return [
      TextFormField(
        controller: _otpCtrl,
        keyboardType: TextInputType.number,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLength: 6,
        style: const TextStyle(color: Color(0xFFE9EDEF), fontSize: 24, letterSpacing: 8),
        decoration: InputDecoration(
          hintText: '000000',
          hintStyle: const TextStyle(color: Color(0xFF8696A0), fontSize: 24),
          filled: true,
          fillColor: const Color(0xFF2A3942),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          counter: const SizedBox(),
        ),
        validator: (v) => v == null || v.length < 6 ? 'أدخل الرمز كاملاً' : null,
      ),
      const SizedBox(height: 12),
      if (auth.error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(auth.error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
        ),
      SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: auth.isLoading ? null : _verifyOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A884),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: auth.isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('تأكيد', style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
      ),
      const SizedBox(height: 12),
      TextButton(
        onPressed: auth.isLoading ? null : _resendOtp,
        child: Text(
          'إعادة إرسال الرمز',
          style: TextStyle(color: auth.isLoading ? const Color(0xFF8696A0) : const Color(0xFF00A884)),
        ),
      ),
    ];
  }

  List<Widget> _buildNameInput(AuthProvider auth) {
    return [
      TextFormField(
        controller: _nameCtrl,
        textDirection: TextDirection.rtl,
        style: const TextStyle(color: Color(0xFFE9EDEF), fontSize: 16),
        decoration: InputDecoration(
          hintText: 'اسمك',
          hintStyle: const TextStyle(color: Color(0xFF8696A0)),
          filled: true,
          fillColor: const Color(0xFF2A3942),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        validator: (v) => v == null || v.isEmpty ? 'أدخل اسمك' : null,
      ),
      const SizedBox(height: 12),
      if (auth.error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(auth.error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
        ),
      SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: auth.isLoading ? null : _saveName,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A884),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: auth.isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('ابدأ المحادثة', style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
      ),
    ];
  }

  void _sendOtp() {
    if (!_formKey.currentState!.validate()) return;
    final fullPhone = '$_code${_phoneCtrl.text.trim()}';
    context.read<AuthProvider>().clearError();
    context.read<AuthProvider>().sendOtp(fullPhone);
  }

  void _verifyOtp() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthProvider>().verifyOtp(_otpCtrl.text.trim());
  }

  void _resendOtp() {
    final fullPhone = '$_code${_phoneCtrl.text.trim()}';
    context.read<AuthProvider>().sendOtp(fullPhone);
  }

  void _saveName() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthProvider>().createProfile(_nameCtrl.text.trim());
  }
}
