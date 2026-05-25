import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/setting_model.dart';
import 'services/firebase_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/setting/pin_lock_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAiI9-QdPGTdINvL7mGdTBoyH95MqQaNUk",
      authDomain: "rentalmanager-4803a.firebaseapp.com",
      projectId: "rentalmanager-4803a",
      storageBucket: "rentalmanager-4803a.firebasestorage.app",
      messagingSenderId: "854957572297",
      appId: "1:854957572297:android:76aa9a1b4b9eb89f144d18",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rental Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checkedRemember = false;

  @override
  void initState() {
    super.initState();
    _applyRememberLogin();
  }

  Future<void> _applyRememberLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('remember_login') ?? false;
    if (!remember && FirebaseAuth.instance.currentUser != null) {
      await FirebaseAuth.instance.signOut();
    }
    if (mounted) setState(() => _checkedRemember = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_checkedRemember) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) return const PinGate();
          return const LoginScreen();
        },
    );
  }
}

class PinGate extends StatefulWidget {
  const PinGate({super.key});

  @override
  State<PinGate> createState() => _PinGateState();
}

class _PinGateState extends State<PinGate> {
  final _service = FirebaseService();
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return const HomeScreen();

    return FutureBuilder<Setting>(
      future: _service.getSettings(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 52, color: Color(0xFFEF4444)),
                      const SizedBox(height: 14),
                      const Text(
                        'Không tải được cài đặt bảo mật',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString().replaceFirst('Exception: ', ''),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Thử lại'),
                      ),
                      TextButton(
                        onPressed: () => _service.signOut(),
                        child: const Text('Đăng xuất'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final setting = snapshot.data!;
        final pin = setting.pinCode ?? '';
        if (!setting.pinEnabled || pin.isEmpty) return const HomeScreen();
        return PinLockScreen(
          correctPin: pin,
          lockKey: _service.currentUser?.uid ?? 'local',
          onUnlocked: () => setState(() => _unlocked = true),
          onLogout: () => _service.signOut(),
        );
      },
    );
  }
}
