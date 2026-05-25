import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/tenant_model.dart';
import '../../services/firebase_service.dart';
import '../../utils/price_input_formatter.dart';
import '../../widgets/tenant_photo_gallery.dart';
import 'add_edit_tenant_screen.dart';

class TenantDetailScreen extends StatefulWidget {
  final Tenant tenant;
  const TenantDetailScreen({super.key, required this.tenant});

  @override
  State<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  static const _primaryColor = Color(0xFF6366F1);
  static const _surfaceColor = Color(0xFFF3F4F6);
  static const _textColor = Color(0xFF1F2937);

  final _service = FirebaseService();
  late Tenant _currentTenant;

  @override
  void initState() {
    super.initState();
    _currentTenant = widget.tenant;
  }

  void _editTenant() {
    showDialog(
      context: context,
      builder: (ctx) => AddEditTenantScreen(tenant: _currentTenant),
    ).then((_) => _loadTenant());
  }

  Future<void> _loadTenant() async {
    try {
      final tenants = await _service.getTenants().first;
      final updated = tenants.where((t) => t.id == _currentTenant.id).firstOrNull;
      if (updated != null && mounted) {
        setState(() => _currentTenant = updated);
      }
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''), backgroundColor: Colors.red);
    }
  }

  Future<void> _callTenant() async {
    final phone = _currentTenant.phone.trim();
    if (phone.isEmpty) {
      _showSnack('Khách chưa có số điện thoại');
      return;
    }
    await _openUri(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _openZalo() async {
    final phone = _currentTenant.phone.replaceAll(RegExp(r'[^\d]'), '');
    if (phone.isEmpty) {
      _showSnack('Khách chưa có số điện thoại');
      return;
    }
    final zaloPhone = phone.startsWith('0') ? '84${phone.substring(1)}' : phone;
    await _openUri(Uri.parse('https://zalo.me/$zaloPhone'));
  }

  Future<void> _openUri(Uri uri) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) _showSnack('Không mở được liên kết');
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''), backgroundColor: Colors.red);
    }
  }

  void _showSnack(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      appBar: AppBar(
        title: const Text(
          'Xem chi tiết',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton.icon(
            onPressed: _editTenant,
            icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
            label: const Text('Sửa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          children: [
            _profileCard(),
            _infoCard(),
            TenantPhotoGallery(
              tenantId: _currentTenant.tenantKey,
              imageUrls: _currentTenant.imageUrls,
              onChanged: (urls) {
                if (!mounted) return;
                setState(() => _currentTenant = _currentTenant.copyWith(imageUrls: urls));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 12),
          Text(
            _currentTenant.fullName.isEmpty ? 'Người thuê' : _currentTenant.fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: _textColor),
          ),
          const SizedBox(height: 4),
          Text(
            _currentTenant.phone.isEmpty ? 'Chưa có số điện thoại' : _currentTenant.phone,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _quickActionButton(Icons.call_outlined, 'Gọi', _callTenant),
              const SizedBox(width: 10),
              _quickActionButton(Icons.chat_bubble_outline_rounded, 'Zalo', _openZalo),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin cá nhân',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _primaryColor),
          ),
          const SizedBox(height: 12),
          _detailRow(
            icon: Icons.badge_outlined,
            iconBg: const Color(0xFFF0EEFF),
            iconColor: _primaryColor,
            label: 'Số CCCD',
            value: _currentTenant.cccd.isEmpty ? '---' : _currentTenant.cccd,
          ),
          _divider(),
          _detailRow(
            icon: Icons.location_on_outlined,
            iconBg: const Color(0xFFCCFBF1),
            iconColor: const Color(0xFF0F766E),
            label: 'Địa chỉ quê quán',
            value: _currentTenant.address.isEmpty ? '---' : _currentTenant.address,
          ),
          _divider(),
          _detailRow(
            icon: Icons.savings_outlined,
            iconBg: const Color(0xFFFFF7ED),
            iconColor: const Color(0xFFF97316),
            label: 'Tiền cọc giữ chỗ',
            value: _money(_currentTenant.deposit),
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton(IconData icon, String label, VoidCallback onPressed) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFFEDEBFF),
        foregroundColor: _primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, color: _textColor, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.only(left: 48),
      child: Divider(height: 1, color: Color(0xFFE5E7EB)),
    );
  }

  String _money(double value) {
    final formatted = PriceInputFormatter.format(value);
    return formatted.isEmpty ? '0 đ' : '$formatted đ';
  }
}
