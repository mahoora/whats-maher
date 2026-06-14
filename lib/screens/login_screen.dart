import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _countryCode = '+966';
  bool _showOtp = false;
  bool _isEmailMode = false;
  bool _isSignUp = false;
  bool _obscurePass = true;

  final _countries = ['SA', 'AE', 'EG', 'KW', 'QA', 'BH', 'OM', 'IQ', 'YE', 'SY', 'JO', 'LB', 'PS', 'DZ', 'MA', 'TN', 'LY', 'SD'];
  final _codes = {'SA': '+966', 'AE': '+971', 'EG': '+20', 'KW': '+965', 'QA': '+974', 'BH': '+973', 'OM': '+968', 'IQ': '+964', 'YE': '+967', 'SY': '+963', 'JO': '+962', 'LB': '+961', 'PS': '+970', 'DZ': '+213', 'MA': '+212', 'TN': '+216', 'LY': '+218', 'SD': '+249'};
  final _names = {'SA': 'السعودية', 'AE': 'الإمارات', 'EG': 'مصر', 'KW': 'الكويت', 'QA': 'قطر', 'BH': 'البحرين', 'OM': 'عمان', 'IQ': 'العراق', 'YE': 'اليمن', 'SY': 'سوريا', 'JO': 'الأردن', 'LB': 'لبنان', 'PS': 'فلسطين', 'DZ': 'الجزائر', 'MA': 'المغرب', 'TN': 'تونس', 'LY': 'ليبيا', 'SD': 'السودان'};

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _isEmailMode = !_isEmailMode;
      _showOtp = false;
      _otpCtrl.clear();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;
    final auth = context.watch<AuthProvider>();
    final err = auth.error;

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
                      _isEmailMode
                          ? (_isSignUp ? 'إنشاء حساب' : 'تسجيل الدخول')
                          : (_showOtp ? 'تأكيد الرقم' : 'أدخل رقم هاتفك'),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFE9EDEF)),
                    ),
                    if (!_isEmailMode && !_showOtp)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('سيتم إرسال رمز تحقق عبر SMS', style: TextStyle(fontSize: 14, color: Color(0xFF8696A0))),
                      ),
                    if (!_isEmailMode && _showOtp)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('أدخل رمز التحقق المرسل إلى هاتفك', style: TextStyle(fontSize: 14, color: Color(0xFF8696A0))),
                      ),
                    const SizedBox(height: 24),

                    if (_isEmailMode) ...[
                      if (_isSignUp) TextFormField(
                        controller: _nameCtrl,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(color: Color(0xFFE9EDEF)),
                        decoration: InputDecoration(
                          labelText: 'الاسم',
                          labelStyle: const TextStyle(color: Color(0xFF8696A0)),
                          prefixIcon: const Icon(Icons.person, color: Color(0xFF8696A0), size: 20),
                          filled: true, fillColor: const Color(0xFF2A3942),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (v) => _isSignUp && (v == null || v.isEmpty) ? 'أدخل اسمك' : null,
                      ),
                      if (_isSignUp) const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailCtrl,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(color: Color(0xFFE9EDEF)),
                        decoration: InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          labelStyle: const TextStyle(color: Color(0xFF8696A0)),
                          prefixIcon: const Icon(Icons.email, color: Color(0xFF8696A0), size: 20),
                          filled: true, fillColor: const Color(0xFF2A3942),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v == null || v.isEmpty ? 'أدخل البريد' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passCtrl,
                        textDirection: TextDirection.ltr,
                        obscureText: _obscurePass,
                        style: const TextStyle(color: Color(0xFFE9EDEF)),
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          labelStyle: const TextStyle(color: Color(0xFF8696A0)),
                          prefixIcon: const Icon(Icons.lock, color: Color(0xFF8696A0), size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF8696A0)),
                            onPressed: () => setState(() => _obscurePass = !_obscurePass),
                          ),
                          filled: true, fillColor: const Color(0xFF2A3942),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'أدخل كلمة المرور' : null,
                      ),
                    ] else if (!_showOtp) ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A3942),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _countryCode,
                                dropdownColor: const Color(0xFF2A3942),
                                style: const TextStyle(color: Color(0xFFE9EDEF), fontSize: 14),
                                items: _countries.map((c) => DropdownMenuItem(value: _codes[c], child: Text('${_codes[c]}'))).toList(),
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
                              style: const TextStyle(color: Color(0xFFE9EDEF), fontSize: 16),
                              decoration: InputDecoration(
                                hintText: '5XXXXXXXX',
                                hintStyle: const TextStyle(color: Color(0xFF5C6B73)),
                                filled: true, fillColor: const Color(0xFF2A3942),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                              validator: (v) => v == null || v.trim().length < 9 ? 'رقم غير صحيح' : null,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _otpCtrl,
                        textDirection: TextDirection.ltr,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        style: const TextStyle(color: Color(0xFFE9EDEF), fontSize: 28, letterSpacing: 8),
                        decoration: InputDecoration(
                          hintText: '000000',
                          hintStyle: const TextStyle(color: Color(0xFF5C6B73), fontSize: 28, letterSpacing: 8),
                          counterText: '',
                          filled: true, fillColor: const Color(0xFF2A3942),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (v) => v == null || v.trim().length < 6 ? 'أدخل الرمز كاملاً' : null,
                      ),
                    ],

                    const SizedBox(height: 20),

                    if (err != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(err, style: const TextStyle(color: Colors.red, fontSize: 13)),
                        ),
                      ),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A884),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(_isEmailMode
                                ? (_isSignUp ? 'إنشاء حساب' : 'تسجيل الدخول')
                                : (_showOtp ? 'تأكيد' : 'إرسال الرمز'),
                                style: const TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Toggle between phone and email
                    TextButton(
                      onPressed: _switchMode,
                      child: Text(
                        _isEmailMode ? 'تسجيل برقم الهاتف' : 'تسجيل بالبريد الإلكتروني',
                        style: const TextStyle(color: Color(0xFF00A884), fontSize: 14),
                      ),
                    ),

                    if (_isEmailMode)
                      TextButton(
                        onPressed: () => setState(() => _isSignUp = !_isSignUp),
                        child: Text(
                          _isSignUp ? 'عندي حساب؟ سجل دخول' : 'ماعنديش حساب؟ إنشاء جديد',
                          style: const TextStyle(color: Color(0xFF00A884), fontSize: 14),
                        ),
                      ),

                    if (_showOtp) ...[
                      TextButton(
                        onPressed: () => setState(() { _showOtp = false; _otpCtrl.clear(); }),
                        child: const Text('تغيير رقم الهاتف', style: TextStyle(color: Color(0xFF00A884), fontSize: 14)),
                      ),
                      TextButton(
                        onPressed: auth.isLoading ? null : () {
                          final phone = '$_countryCode${_phoneCtrl.text.trim().replaceAll(' ', '')}';
                          context.read<AuthProvider>().sendPhoneOtp(phone);
                        },
                        child: Text('إعادة إرسال الرمز',
                          style: TextStyle(color: auth.isLoading ? const Color(0xFF5C6B73) : const Color(0xFF00A884), fontSize: 14)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();

    if (_isEmailMode) {
      final email = _emailCtrl.text.trim();
      final password = _passCtrl.text;
      if (_isSignUp) {
        auth.register(email, password, _nameCtrl.text.trim());
      } else {
        auth.login(email, password);
      }
    } else if (_showOtp) {
      auth.verifyOtp(_otpCtrl.text.trim());
    } else {
      final phone = '$_countryCode${_phoneCtrl.text.trim().replaceAll(' ', '')}';
      auth.sendPhoneOtp(phone);
      if (auth.error == null) setState(() => _showOtp = true);
    }
  }
}
