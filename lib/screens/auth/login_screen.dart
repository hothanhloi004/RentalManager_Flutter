import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/firebase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _service = FirebaseService();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _rePassCtrl = TextEditingController();
  bool _loading = false;
  bool _rememberMe = false;
  bool _obscure = true;
  bool _isLoginMode = true;

  @override
  void initState() {
    super.initState();
    _loadRememberLogin();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _rePassCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRememberLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _rememberMe = prefs.getBool('remember_login') ?? false);
  }

  Future<void> _saveRememberLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_login', _rememberMe);
  }

  bool _isGmail(String email) => RegExp(r'^[a-z0-9._%+-]+@gmail\.com$').hasMatch(email.trim().toLowerCase());

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showMessage('Vui lòng điền đầy đủ thông tin');
      return;
    }
    if (!_isGmail(email)) {
      _showMessage('Chỉ hỗ trợ tài khoản Gmail (@gmail.com)');
      return;
    }
    if (!_isLoginMode) {
      if (password != _rePassCtrl.text.trim()) {
        _showMessage('Mật khẩu nhập lại không khớp');
        return;
      }
      if (password.length < 6) {
        _showMessage('Mật khẩu phải từ 6 ký tự trở lên');
        return;
      }
    }

    setState(() => _loading = true);
    try {
      await _saveRememberLogin();
      if (_isLoginMode) {
        await _service.signIn(email, password);
      } else {
        await _service.register(email, password);
      }
    } catch (e) {
      _showMessage(_isLoginMode ? 'Sai tài khoản hoặc mật khẩu' : 'Đăng ký thất bại: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showMessage('Vui lòng nhập Gmail trước');
      return;
    }
    if (!_isGmail(email)) {
      _showMessage('Chỉ hỗ trợ tài khoản Gmail (@gmail.com)');
      return;
    }
    try {
      await _service.sendPasswordReset(email);
      _showMessage('Đã gửi link đặt lại mật khẩu đến: $email');
    } catch (e) {
      _showMessage('Gửi thất bại: $e');
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _loading = true);
    try {
      await _saveRememberLogin();
      await _service.signInWithGoogle();
    } catch (e) {
      _showMessage('Không thể xác thực Google: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6366F1);
    const lightPurple = Color(0xFFF1EFFF);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      color: lightPurple,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.home_rounded, color: primaryColor, size: 28),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isLoginMode ? 'Đăng Nhập' : 'Đăng Ký',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _authField(
                    controller: _emailCtrl,
                    hintText: 'Email Gmail (ví dụ: ten@gmail...)',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  _authField(
                    controller: _passCtrl,
                    hintText: 'Mật khẩu',
                    obscureText: _obscure,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: const Color(0xFF64748B),
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  if (!_isLoginMode) ...[
                    const SizedBox(height: 14),
                    _authField(
                      controller: _rePassCtrl,
                      hintText: 'Nhập lại mật khẩu',
                      obscureText: _obscure,
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (v) => setState(() => _rememberMe = v ?? false),
                          activeColor: primaryColor,
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Ghi nhớ đăng nhập',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFC7D2FE),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _isLoginMode ? 'Đăng nhập' : 'Đăng ký',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  if (_isLoginMode) ...[
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: _forgotPassword,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Quên mật khẩu?',
                        style: TextStyle(color: primaryColor, fontSize: 12.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade200, height: 1)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'HOẶC',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade200, height: 1)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton(
                      onPressed: _loading ? null : _googleSignIn,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            'https://www.gstatic.com/images/branding/product/1x/googleg_48dp.png',
                            height: 18,
                            width: 18,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.g_mobiledata, size: 24, color: primaryColor),
                          ),
                          const SizedBox(width: 10),
                          const Flexible(
                            child: Text(
                              'Tiếp tục truy cập với Google',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12.5, color: primaryColor, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _isLoginMode ? 'Chưa có tài khoản? Đăng ký ngay' : 'Đã có tài khoản? Đăng nhập ngay',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _authField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
          suffixIcon: suffixIcon,
          suffixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 40),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.2),
          ),
        ),
      ),
    );
  }
}
