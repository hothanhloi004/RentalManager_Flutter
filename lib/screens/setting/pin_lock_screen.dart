import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinLockScreen extends StatefulWidget {
  final String correctPin;
  final String lockKey;
  final VoidCallback onUnlocked;
  final VoidCallback onLogout;

  const PinLockScreen({
    super.key,
    required this.correctPin,
    required this.lockKey,
    required this.onUnlocked,
    required this.onLogout,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  static const _maxAttempts = 5;
  static const _lockDuration = Duration(seconds: 30);

  String _input = '';
  int _failCount = 0;
  int _remainingSeconds = 0;
  DateTime? _lockedUntil;
  String? _message;
  Timer? _timer;

  String get _failKey => 'pin_fail_count_${widget.lockKey}';
  String get _lockKey => 'pin_locked_until_${widget.lockKey}';
  bool get _isLocked => _lockedUntil != null && DateTime.now().isBefore(_lockedUntil!);

  @override
  void initState() {
    super.initState();
    _restoreLockState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _restoreLockState() async {
    final prefs = await SharedPreferences.getInstance();
    final lockedUntilMs = prefs.getInt(_lockKey);
    final failCount = prefs.getInt(_failKey) ?? 0;
    final lockedUntil = lockedUntilMs == null ? null : DateTime.fromMillisecondsSinceEpoch(lockedUntilMs);

    if (!mounted) return;
    setState(() {
      _failCount = failCount.clamp(0, _maxAttempts - 1).toInt();
      if (lockedUntil != null && DateTime.now().isBefore(lockedUntil)) {
        _lockedUntil = lockedUntil;
        _message = 'Nhập sai quá nhiều. Thử lại sau ${_secondsLeft()} giây.';
      }
    });
    if (_isLocked) {
      _startCountdown();
    } else if (lockedUntil != null) {
      await prefs.remove(_lockKey);
    }
  }

  Future<void> _clearLockState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_failKey);
    await prefs.remove(_lockKey);
  }

  int _secondsLeft() {
    final lockedUntil = _lockedUntil;
    if (lockedUntil == null) return 0;
    final seconds = lockedUntil.difference(DateTime.now()).inSeconds;
    return seconds < 0 ? 0 : seconds + 1;
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      if (!_isLocked) {
        _timer?.cancel();
        setState(() {
          _lockedUntil = null;
          _remainingSeconds = 0;
          _message = 'Bạn có thể nhập lại mã PIN.';
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_lockKey);
        return;
      }

      setState(() {
        _remainingSeconds = _secondsLeft();
        _message = 'Nhập sai quá nhiều. Thử lại sau $_remainingSeconds giây.';
      });
    });
    setState(() {
      _remainingSeconds = _secondsLeft();
      _message = 'Nhập sai quá nhiều. Thử lại sau $_remainingSeconds giây.';
    });
  }

  Future<void> _lockTemporarily() async {
    final prefs = await SharedPreferences.getInstance();
    final lockedUntil = DateTime.now().add(_lockDuration);
    await prefs.setInt(_lockKey, lockedUntil.millisecondsSinceEpoch);
    await prefs.setInt(_failKey, 0);

    setState(() {
      _input = '';
      _failCount = 0;
      _lockedUntil = lockedUntil;
      _remainingSeconds = _secondsLeft();
      _message = 'Sai PIN quá $_maxAttempts lần. Bị khóa $_remainingSeconds giây.';
    });
    _startCountdown();
  }

  Future<void> _onKeyTap(String key) async {
    if (_isLocked) {
      setState(() => _message = 'Nhập sai quá nhiều. Thử lại sau ${_secondsLeft()} giây.');
      return;
    }
    if (_input.length >= 6) return;

    setState(() {
      _input += key;
      _message = null;
    });

    if (_input.length != 6) return;

    if (_input == widget.correctPin) {
      await _clearLockState();
      widget.onUnlocked();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final nextFailCount = _failCount + 1;
    if (nextFailCount >= _maxAttempts) {
      await _lockTemporarily();
      return;
    }

    await prefs.setInt(_failKey, nextFailCount);
    setState(() {
      _input = '';
      _failCount = nextFailCount;
      _message = 'PIN không đúng. Còn ${_maxAttempts - _failCount} lần thử.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final locked = _isLocked;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 640;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 18 : 24),
                  child: Column(
                    children: [
                      SizedBox(height: compact ? 16 : 44),
                      Container(
                        padding: EdgeInsets.all(compact ? 16 : 20),
                        decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(30)),
                        child: Icon(
                          locked ? Icons.lock_clock_rounded : Icons.security_rounded,
                          size: compact ? 48 : 60,
                          color: const Color(0xFF5764F1),
                        ),
                      ),
                      SizedBox(height: compact ? 20 : 32),
                      const Text(
                        'XÁC THỰC MÃ PIN',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937), letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        locked ? 'Mã PIN đang bị khóa tạm thời' : 'Vui lòng nhập mã PIN để vào ứng dụng',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                      SizedBox(height: compact ? 24 : 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          6,
                          (i) => Container(
                            margin: EdgeInsets.all(compact ? 8 : 10),
                            width: compact ? 12 : 14,
                            height: compact ? 12 : 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _input.length > i ? const Color(0xFF5764F1) : const Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 36,
                        child: Text(
                          _message ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: locked ? const Color(0xFFF97316) : const Color(0xFFEF4444),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 8 : 24),
                      _buildNumpad(locked, compact: compact),
                      TextButton(
                        onPressed: widget.onLogout,
                        child: const Text('Đăng xuất', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(height: compact ? 16 : 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNumpad(bool locked, {required bool compact}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 56 : 40),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: compact ? 1.55 : 1.2),
        itemCount: 12,
        itemBuilder: (ctx, i) {
          if (i == 9) return const SizedBox.shrink();
          if (i == 11) {
            return IconButton(
              onPressed: locked
                  ? null
                  : () => setState(() => _input = _input.isNotEmpty ? _input.substring(0, _input.length - 1) : ''),
              icon: Icon(Icons.backspace_outlined, color: locked ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)),
            );
          }
          final val = (i == 10) ? '0' : (i + 1).toString();
          return InkWell(
            onTap: locked ? null : () => _onKeyTap(val),
            borderRadius: BorderRadius.circular(50),
            child: Center(
              child: Text(
                val,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: locked ? const Color(0xFFCBD5E1) : const Color(0xFF1F2937),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
