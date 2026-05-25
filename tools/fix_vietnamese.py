# -*- coding: utf-8 -*-
"""Sửa chuỗi tiếng Việt bị hỏ encoding trong lib/."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "lib"

# file -> list of (old_fragment, new_text) — old có thể là mojibake hoặc ?
REPLACEMENTS: dict[str, list[tuple[str, str]]] = {
    "screens/report/report_screen.dart": [
        ("subtitle: 'Th?ng k", "subtitle: 'Thống kê'"),
        ("title: 'B?o c?o doanh thu'", "title: 'Báo cáo doanh thu'"),
        ("'Doanh thu 6 th?ng g?n nh?t'", "'Doanh thu 6 tháng gần nhất'"),
        ("'T?nh tr?ng ph?ng'", "'Tình trạng phòng'"),
        ("'Kh?ng c? d? li?u'", "'Không có dữ liệu'"),
        ("'?ang thu?'", "'Đang thuê'"),
        ("'Tr?ng'", "'Trống'"),
    ],
    "services/firebase_service.dart": [
        ("'Ngu?i d", "'Người dùng đã hủy đăng nhập'"),
        ("// H? tr? c? 2 d?nh d?ng", "// Hỗ trợ cả 2 định dạng"),
        ("// C?p nh?t ch? s? di?n nu?c", "// Cập nhật chỉ số điện nước"),
        ("// 1. L?y t?t c? h?p", "// 1. Lấy tất cả hợp"),
        ("// 2. L?y c", "// 2. Lấy các"),
    ],
}

# Full file rewrites (UTF-8) for heavily corrupted screens
CONTRACT_LIST = r'''import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/contract_model.dart';
import '../../models/room_model.dart';
import '../../models/tenant_model.dart';
import '../../services/firebase_service.dart';
import 'add_contract_screen.dart';
import '../../utils/string_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class ContractListScreen extends StatefulWidget {
  const ContractListScreen({super.key});
  @override
  State<ContractListScreen> createState() => _ContractListScreenState();
}

class _ContractListScreenState extends State<ContractListScreen> {
  final _service = FirebaseService();
  String _currentFilter = 'ALL';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6366F1);
    final currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: '\u0111');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Row(
                children: [
                  const Text('H\u1ee3p \u0111\u1ed3ng', style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 24)),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddContractScreen())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 0,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('+ Th\u00eam h\u1ee3p \u0111\u1ed3ng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'T\u00ecm theo ph\u00f2ng ho\u1eb7c ng\u01b0\u1eddi thu\u00ea...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        fillColor: const Color(0xFFF1F3F9),
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _filterChip('T\u1ea5t c\u1ea3', 'ALL'),
                        _filterChip('\u0110ang hi\u1ec7u l\u1ef1c', 'active'),
                        _filterChip('\u0110\u00e3 k\u1ebft th\u00fac', 'ended'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Expanded(
              child: StreamBuilder<List<Contract>>(
                stream: _service.getContracts(),
                builder: (ctx, contractSnap) {
                  if (!contractSnap.hasData) return const Center(child: CircularProgressIndicator(color: primaryColor));
                  return StreamBuilder<List<Room>>(
                    stream: _service.getRooms(),
                    builder: (ctx, roomSnap) {
                      return StreamBuilder<List<Tenant>>(
                        stream: _service.getTenants(),
                        builder: (ctx, tenantSnap) {
                          var contracts = contractSnap.data ?? [];
                          final rooms = roomSnap.data ?? [];
                          final tenants = tenantSnap.data ?? [];
                          contracts.sort((a, b) => b.id.compareTo(a.id));
                          if (_currentFilter != 'ALL') {
                            if (_currentFilter == 'active') {
                              contracts = contracts.where((c) => c.isActive).toList();
                            } else if (_currentFilter == 'ended') {
                              contracts = contracts.where((c) => c.isEnded).toList();
                            } else {
                              contracts = contracts.where((c) => c.status == _currentFilter).toList();
                            }
                          }
                          if (_searchQuery.isNotEmpty) {
                            contracts = contracts.where((c) {
                              final room = rooms.where((r) => r.id == c.roomId).firstOrNull;
                              final tenant = tenants.where((t) => t.id == c.tenantId).firstOrNull;
                              return StringUtils.containsSearch(room?.roomName ?? '', _searchQuery) ||
                                  StringUtils.containsSearch(tenant?.fullName ?? '', _searchQuery);
                            }).toList();
                          }
                          if (contracts.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 8),
                                  const Text('Ch\u01b0a c\u00f3 h\u1ee3p \u0111\u1ed3ng n\u00e0o', style: TextStyle(color: Colors.grey, fontSize: 16)),
                                ],
                              ),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: contracts.length,
                            itemBuilder: (ctx, i) {
                              final c = contracts[i];
                              final room = rooms.where((r) => r.id == c.roomId).firstOrNull;
                              final tenant = tenants.where((t) => t.id == c.tenantId).firstOrNull;
                              final isLive = c.isActive;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                                  border: Border.all(color: const Color(0xFFF3F4F6)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(room?.roomName ?? 'Ph\u00f2ng ?', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF111827))),
                                          _statusBadge(isLive),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(tenant?.fullName ?? 'Kh\u00e1ch l\u1ebd', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text('Ti\u1ec1n c\u1ecdc: ${currencyFmt.format(c.deposit)}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          if (c.useWifi) _serviceTag('WiFi', Icons.wifi),
                                          if (c.useTrash) _serviceTag('R\u00e1c', Icons.delete_outline),
                                          _serviceTag('\u0110i\u1ec7n/N\u01b0\u1edbc', Icons.bolt),
                                        ],
                                      ),
                                      const Divider(height: 24, color: Color(0xFFF3F4F6)),
                                      Row(
                                        children: [
                                          OutlinedButton(
                                            onPressed: () async {
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text('K\u1ebft th\u00fac h\u1ee3p \u0111\u1ed3ng'),
                                                  content: const Text('B\u1ea1n c\u00f3 ch\u1eafc ch\u1eafn mu\u1ed1n k\u1ebft th\u00fac h\u1ee3p \u0111\u1ed3ng n\u00e0y? Ph\u00f2ng s\u1ebd được chuy\u1ec3n sang tr\u1ea1ng th\u00e1i tr\u1ed1ng.'),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hu\u1ef7', style: TextStyle(color: Colors.grey))),
                                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('\u0110\u1ed3ng \u00fd', style: TextStyle(color: Colors.red))),
                                                  ],
                                                ),
                                              );
                                              if (confirm == true) await _service.endContract(c.id);
                                            },
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Color(0xFFEF4444)),
                                              foregroundColor: const Color(0xFFEF4444),
                                              shape: const StadiumBorder(),
                                              minimumSize: const Size(0, 32),
                                            ),
                                            child: const Text('K\u1ebft th\u00fac', style: TextStyle(fontSize: 12)),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton(
                                            onPressed: () {
                                              var w = c.useWifi;
                                              var t = c.useTrash;
                                              var s = c.useServiceFee;
                                              showDialog(
                                                context: context,
                                                builder: (ctx) => StatefulBuilder(
                                                  builder: (ctx, setDlgState) => AlertDialog(
                                                    title: const Text('S\u1eeda d\u1ecbch v\u1ee5'),
                                                    content: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        CheckboxListTile(title: const Text('WiFi'), value: w, onChanged: (v) => setDlgState(() => w = v ?? false)),
                                                        CheckboxListTile(title: const Text('R\u00e1c'), value: t, onChanged: (v) => setDlgState(() => t = v ?? false)),
                                                        CheckboxListTile(title: const Text('Ph\u00ed d\u1ecbch v\u1ee5'), value: s, onChanged: (v) => setDlgState(() => s = v ?? false)),
                                                      ],
                                                    ),
                                                    actions: [
                                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hu\u1ef7', style: TextStyle(color: Colors.grey))),
                                                      TextButton(
                                                        onPressed: () {
                                                          _service.updateContractServices(c.id, w, t, s);
                                                          Navigator.pop(ctx);
                                                        },
                                                        child: const Text('L\u01b0u', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Text('S\u1eeda d\u1ecbch v\u1ee5', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            onPressed: () async {
                                              final phone = tenant?.phone;
                                              if (phone != null && phone.isNotEmpty) {
                                                final uri = Uri.parse('tel:$phone');
                                                if (await canLaunchUrl(uri)) await launchUrl(uri);
                                              }
                                            },
                                            icon: const Icon(Icons.phone_outlined, color: Colors.green, size: 20),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _currentFilter == value;
    const primaryColor = Color(0xFF6366F1);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _currentFilter = value),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFFE8E7FF),
        checkmarkColor: primaryColor,
        labelStyle: TextStyle(color: isSelected ? primaryColor : Colors.black87, fontSize: 13),
        shape: StadiumBorder(side: BorderSide(color: isSelected ? primaryColor : Colors.grey.shade200)),
      ),
    );
  }

  Widget _statusBadge(bool isLive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isLive ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isLive ? 'Hi\u1ec7u l\u1ef1c' : '\u0110\u00e3 k\u1ebft th\u00fac',
        style: TextStyle(color: isLive ? const Color(0xFF166534) : const Color(0xFF6B7280), fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Widget _serviceTag(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}
'''

ROOM_DETAIL_PATCHES = [
    ("symbol: '?'", "symbol: '\\u0111'"),
    ("'Xem chi ti?t'", "'Xem chi ti\u1ebft'"),
    ("'S?a'", "'S\u1eeda'"),
    ("'?ang c? ngu?i thu?'", "'\u0110ang c\u00f3 ng\u01b0\u1eddi thu\u00ea'"),
    ("'Chua c? ngu?i thu?'", "'Ch\u01b0a c\u00f3 ng\u01b0\u1eddi thu\u00ea'"),
    ("'Ph?ng di?n t?ch", "'Ph\u00f2ng di\u1ec7n t\u00edch"),
    ("'Tr?ng'", "'Tr\u1ed1ng'"),
    ("'B?o tr?'", "'B\u1ea3o tr\u00ec'"),
    ("'?ang thu?'", "'\u0110ang thu\u00ea'"),
    ("'+ T?o h?p d?ng cho ph?ng n?y'", "'+ T\u1ea1o h\u1ee3p \u0111\u1ed3ng cho ph\u00f2ng n\u00e0y'"),
]

REPORT_UTF8 = """import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/room_model.dart';
import '../../models/bill_model.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_sub_page_header.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _service = FirebaseService();
  bool _isLoading = true;
  List<Room> _rooms = [];
  List<Bill> _bills = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final rooms = await _service.getRooms().first;
    final bills = await _service.getBills().first;
    setState(() {
      _rooms = rooms;
      _bills = bills;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              child: Column(
                children: [
                  const GradientSubPageHeader(
                    subtitle: 'Th\u1ed1ng k\u00ea',
                    title: 'B\u00e1o c\u00e1o doanh thu',
                  ),
                  _chartCard('Doanh thu 6 th\u00e1ng g\u1ea7n nh\u1ea5t', _buildBarChart()),
                  _chartCard('T\u00ecnh tr\u1ea1ng ph\u00f2ng', _buildPieChart()),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _chartCard(String title, Widget chart) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
          const SizedBox(height: 24),
          SizedBox(height: 240, child: chart),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        maxY: 20,
        barGroups: [
          _group(0, 12),
          _group(1, 15),
          _group(2, 8),
          _group(3, 18),
          _group(4, 14),
          _group(5, 16),
        ],
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                const months = ['T1', 'T2', 'T3', 'T4', 'T5', 'T6'];
                return Text(months[v.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 12));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  BarChartGroupData _group(int x, double y) => BarChartGroupData(
        x: x,
        barRods: [
          BarChartRodData(
            toY: y,
            color: AppTheme.primary,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );

  Widget _buildPieChart() {
    final rented = _rooms.where((r) => r.isRented).length;
    final vacant = _rooms.length - rented;
    if (_rooms.isEmpty) {
      return const Center(child: Text('Kh\u00f4ng c\u00f3 d\u1eef li\u1ec7u'));
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            value: rented.toDouble(),
            title: '\u0110ang thu\u00ea',
            color: AppTheme.primary,
            radius: 60,
            titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          PieChartSectionData(
            value: vacant.toDouble(),
            title: 'Tr\u1ed1ng',
            color: const Color(0xFFE5E7EB),
            radius: 50,
            titleStyle: const TextStyle(color: Color(0xFF4B5563), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
"""


def fix_firebase(path: Path) -> None:
    text = path.read_text(encoding="utf-8", errors="replace")
    import re
    text = re.sub(
        r"throw Exception\('[^']*'\);",
        "throw Exception('Ng\u01b0\u1eddi d\u00f9ng \u0111\u00e3 h\u1ee7y \u0111\u0103ng nh\u1eadp');",
        text,
        count=1,
    )
    comments = [
        ("// H", "// H\u1ed7 tr\u1ee3 c\u1ea3 2 \u0111\u1ecbnh d\u1ea1ng: yyyy-MM (Android) v\u00e0 MM/yyyy (Flutter)"),
        ("// C", "// C\u1eadp nh\u1eadt ch\u1ec9 s\u1ed1 \u0111i\u1ec7n n\u01b0\u1edbc cu\u1ed1i c\u00f9ng v\u00e0o h\u1ee3p \u0111\u1ed3ng"),
        ("// 1. L", "// 1. L\u1ea5y t\u1ea5t c\u1ea3 h\u1ee3p \u0111\u1ed3ng \u0111ang hi\u1ec7u l\u1ef1c"),
        ("// 2. L", "// 2. L\u1ea5y c\u00e1c h\u00f3a \u0111\u01a1n \u0111\u00e3 t\u1ed3n t\u1ea1i trong th\u00e1ng n\u00e0y"),
    ]
    lines = text.splitlines()
    out = []
    for line in lines:
        if "throw Exception" in line and "googleUser" in "".join(out[-3:]):
            out.append("      if (googleUser == null) throw Exception('Ng\u01b0\u1eddi d\u00f9ng \u0111\u00e3 h\u1ee7y \u0111\u0103ng nh\u1eadp');")
            continue
        if line.strip().startswith("// H") and "tr" in line:
            out.append("    // H\u1ed7 tr\u1ee3 c\u1ea3 2 \u0111\u1ecbnh d\u1ea1ng: yyyy-MM (Android) v\u00e0 MM/yyyy (Flutter)")
            continue
        if "C?p nh?t ch" in line or "C\u1eadp" in line and "ch? s" in line:
            out.append("    // C\u1eadp nh\u1eadt ch\u1ec9 s\u1ed1 \u0111i\u1ec7n n\u01b0\u1edbc cu\u1ed1i c\u00f9ng v\u00e0o h\u1ee3p \u0111\u1ed3ng")
            continue
        if line.strip().startswith("// 1. L"):
            out.append("    // 1. L\u1ea5y t\u1ea5t c\u1ea3 h\u1ee3p \u0111\u1ed3ng \u0111ang hi\u1ec7u l\u1ef1c")
            continue
        if line.strip().startswith("// 2. L"):
            out.append("    // 2. L\u1ea5y c\u00e1c h\u00f3a \u0111\u01a1n \u0111\u00e3 t\u1ed3n t\u1ea1i trong th\u00e1ng n\u00e0y")
            continue
        out.append(line)
    path.write_text("\n".join(out) + ("\n" if text.endswith("\n") else ""), encoding="utf-8")
    print("firebase", path)


def main() -> None:
    (ROOT / "screens/contract/contract_list_screen.dart").write_text(CONTRACT_LIST, encoding="utf-8")
    print("wrote contract_list")

    (ROOT / "screens/report/report_screen.dart").write_text(REPORT_UTF8, encoding="utf-8")
    print("wrote report")

    room = ROOT / "screens/room/room_detail_screen.dart"
    rt = room.read_text(encoding="utf-8", errors="replace")
    for old, new in ROOM_DETAIL_PATCHES:
        if old in rt:
            rt = rt.replace(old, new)
    room.write_text(rt, encoding="utf-8")
    print("patched room_detail")

    fix_firebase(ROOT / "services/firebase_service.dart")

    for rel, pairs in REPLACEMENTS.items():
        p = ROOT / rel
        if not p.exists():
            continue
        t = p.read_text(encoding="utf-8", errors="replace")
        for old, new in pairs:
            if old in t:
                t = t.replace(old, new, 1)
        p.write_text(t, encoding="utf-8")

    for p in ROOT.rglob("*.dart"):
        t = p.read_text(encoding="utf-8", errors="replace")
        if "symbol: '?'" in t or "symbol: 'd'" in t:
            t2 = t.replace("symbol: '?'", "symbol: '\\u0111'").replace("symbol: 'd'", "symbol: '\\u0111'")
            if t2 != t:
                p.write_text(t2, encoding="utf-8")
                print("symbol fix", p)


if __name__ == "__main__":
    main()
