# -*- coding: utf-8 -*-
from pathlib import Path

p = Path(__file__).resolve().parent.parent / "lib/screens/room/room_list_screen.dart"
t = p.read_text(encoding="utf-8")

t = t.replace(
    "import '../../utils/string_utils.dart';",
    "import '../../theme/app_theme.dart';\nimport '../../utils/string_utils.dart';",
)
t = t.replace("symbol: 'đ'", "symbol: '\\u0111'")
t = t.replace("const Color(0xFF6366F1)", "AppTheme.primary")
t = t.replace("backgroundColor: const Color(0xFFEFF2F6)", "backgroundColor: AppTheme.background")
t = t.replace(
    "hintText: 'Tìm địa chỉ phòng hoặc người thuê...'",
    "hintText: 'Tìm tên phòng hoặc người thuê...'",
)
t = t.replace("fontSize: 14)", "fontSize: 13)")
t = t.replace(
    "Text(r.roomName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF111827)))",
    "Text(r.roomName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: AppTheme.onSurface, letterSpacing: -0.3))",
)
t = t.replace(
    "Text('${currencyFmt.format(r.price)}/tháng', style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16))",
    "Text('${currencyFmt.format(r.price)}/tháng', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 17, letterSpacing: -0.2))",
)
t = t.replace(
    "Text(isRented ? tenant.fullName : 'Chưa có người thuê', style: TextStyle(fontWeight: isRented ? FontWeight.bold : FontWeight.normal, color: const Color(0xFF374151), fontSize: 14))",
    "Text(isRented ? tenant.fullName : 'Chưa có người thuê', style: TextStyle(fontWeight: isRented ? FontWeight.w600 : FontWeight.w500, color: isRented ? AppTheme.onSurface : AppTheme.onSurfaceVariant, fontSize: 14))",
)
t = t.replace(
    "Text('Từ: ${contract.startDate}', style: const TextStyle(color: Colors.grey, fontSize: 12))",
    "Text('Từ: ${_formatDate(contract.startDate)}', style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w500))",
)
t = t.replace(
    "Text('Ghi chú: ${r.note.isEmpty ? \"Không có dữ liệu\" : r.note}', style: const TextStyle(color: Colors.grey, fontSize: 12))",
    "Text('Ghi chú: ${r.note.isEmpty ? 'Không có' : r.note}', style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13, height: 1.3))",
)

# status badge block - replace isRented ternary with helper call - simpler patch for maintenance
old_badge = """                                              child: Text(
                                                isRented ? 'Đang thuê' : 'Trống',
                                                style: TextStyle(color: isRented ? const Color(0xFF166534) : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),"""

new_badge = """                                              child: Text(
                                                _statusLabel(r.status),
                                                style: TextStyle(color: _statusColor(r.status), fontSize: 11, fontWeight: FontWeight.w700),
                                              ),"""

if old_badge in t:
    t = t.replace(old_badge, new_badge)
    t = t.replace(
        "color: isRented ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),",
        "color: _statusBg(r.status),",
    )

# remove add circle button row part
t = t.replace(
    """                                        const Spacer(),
                                        IconButton(icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFCBD5E1), size: 24), onPressed: () {}),
""",
    "                                        const Spacer(),\n",
)

# add helper methods before _buildEmptyState
helpers = """
  String _statusLabel(String status) {
    if (status == 'BAO_TRI') return 'Bảo trì';
    if (status == 'TRONG' || status == 'empty' || status == 'AVAILABLE') return 'Trống';
    return 'Đang thuê';
  }

  Color _statusBg(String status) {
    if (status == 'BAO_TRI') return const Color(0xFFFEF3C7);
    if (status == 'TRONG' || status == 'empty' || status == 'AVAILABLE') return const Color(0xFFF3F4F6);
    return const Color(0xFFDCFCE7);
  }

  Color _statusColor(String status) {
    if (status == 'BAO_TRI') return const Color(0xFF92400E);
    if (status == 'TRONG' || status == 'empty' || status == 'AVAILABLE') return AppTheme.onSurfaceVariant;
    return const Color(0xFF166534);
  }

  String _formatDate(int ms) {
    if (ms <= 0) return '—';
    return DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(ms));
  }

"""

if "_statusLabel" not in t:
    t = t.replace("  Widget _buildEmptyState() {", helpers + "  Widget _buildEmptyState() {")

# fix const primaryColor in build - may conflict
t = t.replace("    const primaryColor = AppTheme.primary;\n", "    const primaryColor = AppTheme.primary;\n")

p.write_text(t, encoding="utf-8")
print("patched room list")
