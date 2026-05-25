# -*- coding: utf-8 -*-
from pathlib import Path

def u(*codes: int) -> str:
    return "".join(chr(c) for c in codes)

# All UI strings
S = {
    "title": u(0x48, 0xF3, 0x61, 0x20, 0x111, 0x01A1, 0x6E),
    "snack": u(0x110, 0xE3, 0x20, 0x74, 0x1EA1, 0x6F) + " {count} " + u(0x68, 0xF3, 0x61, 0x20, 0x111, 0x01A1, 0x6E, 0x20, 0x6D, 0x1EDB, 0x69, 0x20, 0x63, 0x68, 0x6F, 0x20, 0x74, 0x68, 0xE1, 0x6E, 0x67, 0x20) + "{month}",
    "bulk": u(0x54, 0x1EA1, 0x6F, 0x20, 0x68, 0xE0, 0x6E, 0x67, 0x20, 0x6C, 0x1EA1, 0x74),
    "meter": u(0x47, 0x68, 0x69, 0x20, 0x6C, 0x1EBB, 0x20, 0x2F, 0x20, 0x43, 0x68, 0x1ED1, 0x74),
    "hint": u(0x54, 0xEC, 0x6D, 0x20, 0x74, 0x68, 0x65, 0x6F, 0x20, 0x70, 0xF2, 0x6E, 0x67, 0x20, 0x68, 0x1EB7, 0x63, 0x20, 0x74, 0x68, 0xE1, 0x6E, 0x67, 0x2E, 0x2E, 0x2E),
    "all": u(0x54, 0x1EA5, 0x74, 0x20, 0x63, 0x1EA3),
    "pending": u(0x43, 0x68, 0x1B0, 0x61, 0x20, 0x63, 0x68, 0x1ED1, 0x74),
    "unpaid": u(0x43, 0x68, 0x1B0, 0x61, 0x20, 0x74, 0x72, 0x1EA3),
    "paid": u(0x110, 0xE3, 0x20, 0x74, 0x72, 0x1EA3),
    "empty": u(0x43, 0x68, 0x1B0, 0x61, 0x20, 0x63, 0xF3, 0x20, 0x68, 0xF3, 0x61, 0x20, 0x111, 0x01A1, 0x6E, 0x20, 0x6E, 0xE0, 0x6F),
    "room_unknown": u(0x50, 0x68, 0xF2, 0x6E, 0x67, 0x20, 0x3F),
    "success": u(0x54, 0x68, 0xE0, 0x6E, 0x68, 0x20, 0x63, 0xF4, 0x6E, 0x67),
    "not_collected": u(0x43, 0x68, 0x1B0, 0x61, 0x20, 0x74, 0x68, 0x75),
    "total": u(0x54, 0x1ED5, 0x6E, 0x67, 0x20, 0x63, 0x1ED9, 0x6E, 0x67),
    "due": u(0x48, 0x1EA1, 0x6E, 0x20, 0x74, 0x68, 0x75),
    "collected": u(0x110, 0xE3, 0x20, 0x74, 0x68, 0x75),
    "collect": u(0x54, 0x68, 0x75, 0x20, 0x74, 0x69, 0x1EC1, 0x6E),
    "detail": u(0x43, 0x68, 0x69, 0x20, 0x74, 0x69, 0x1EBF, 0x74),
    "dot": u(0xB7),  # middle dot
}

dart = f'''import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/bill_model.dart';
import '../../models/contract_model.dart';
import '../../models/room_model.dart';
import '../../services/firebase_service.dart';
import 'add_bill_screen.dart';
import 'bill_detail_dialog.dart';
import '../../utils/string_utils.dart';

class BillListScreen extends StatefulWidget {{
  const BillListScreen({{super.key}});

  @override
  State<BillListScreen> createState() => _BillListScreenState();
}}

class _BillListScreenState extends State<BillListScreen> {{
  final _service = FirebaseService();
  String _currentFilter = 'ALL';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {{
    const primaryColor = Color(0xFF6366F1);
    final currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: '\\u0111');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '{S["title"]}',
                    style: const TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {{
                            final settings = await _service.getSettings();
                            final monthStr = DateFormat('MM/yyyy').format(DateTime.now());
                            final count = await _service.bulkCreateBills(monthStr, settings);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '{S["snack"].format(count="$count", month="$monthStr")}',
                                ),
                              ),
                            );
                          }},
                          icon: const Icon(Icons.auto_awesome_motion_rounded, size: 18),
                          label: const Text('{S["bulk"]}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                            minimumSize: const Size(0, 44),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddBillScreen()),
                          ),
                          icon: const Icon(Icons.edit_note_rounded, size: 20),
                          label: const Text('{S["meter"]}'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            foregroundColor: const Color(0xFF4B5563),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            minimumSize: const Size(0, 44),
                          ),
                        ),
                      ),
                    ],
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
                        hintText: '{S["hint"]}',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        fillColor: const Color(0xFFF1F3F9),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _filterChip('{S["all"]}', 'ALL'),
                        _filterChip('{S["pending"]}', 'PENDING'),
                        _filterChip('{S["unpaid"]}', 'unpaid'),
                        _filterChip('{S["paid"]}', 'paid'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Expanded(
              child: StreamBuilder<List<Bill>>(
                stream: _service.getBills(),
                builder: (ctx, billSnap) {{
                  if (!billSnap.hasData) {{
                    return const Center(child: CircularProgressIndicator(color: primaryColor));
                  }}
                  return StreamBuilder<List<Contract>>(
                    stream: _service.getContracts(),
                    builder: (ctx, contractSnap) {{
                      return StreamBuilder<List<Room>>(
                        stream: _service.getRooms(),
                        builder: (ctx, roomSnap) {{
                          var bills = billSnap.data ?? [];
                          final contracts = contractSnap.data ?? [];
                          final rooms = roomSnap.data ?? [];
                          bills.sort((a, b) => b.id.compareTo(a.id));
                          if (_currentFilter != 'ALL') {{
                            if (_currentFilter == 'PENDING') {{
                              bills = bills.where((b) => !b.meterUpdated).toList();
                            }} else if (_currentFilter == 'paid') {{
                              bills = bills.where((b) => b.isPaid).toList();
                            }} else if (_currentFilter == 'unpaid') {{
                              bills = bills.where((b) => b.isUnpaid).toList();
                            }} else {{
                              bills = bills.where((b) => b.paymentStatus == _currentFilter).toList();
                            }}
                          }}
                          if (_searchQuery.isNotEmpty) {{
                            bills = bills.where((b) {{
                              final contract = contracts.where((c) => c.id == b.contractId).firstOrNull;
                              final room = rooms.where((r) => r.id == contract?.roomId).firstOrNull;
                              return StringUtils.containsSearch(room?.roomName ?? '', _searchQuery) ||
                                  b.month.contains(_searchQuery);
                            }}).toList();
                          }}
                          if (bills.isEmpty) {{
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_outlined, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 8),
                                  Text('{S["empty"]}', style: const TextStyle(color: Colors.grey, fontSize: 16)),
                                ],
                              ),
                            );
                          }}
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: bills.length,
                            itemBuilder: (ctx, i) {{
                              final b = bills[i];
                              final contract = contracts.where((c) => c.id == b.contractId).firstOrNull;
                              final room = rooms.where((r) => r.id == contract?.roomId).firstOrNull;
                              final isPaid = b.isPaid;
                              final roomLabel = room?.roomName ?? '{S["room_unknown"]}';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '$roomLabel {S["dot"]} ${{b.month}}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                                color: Color(0xFF111827),
                                              ),
                                            ),
                                          ),
                                          _statusBadge(
                                            isPaid ? '{S["success"]}' : '{S["not_collected"]}',
                                            isPaid ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '{S["total"]}: ${{currencyFmt.format(b.totalAmount)}}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            '{S["due"]}: ${{DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(b.dueDate))}}',
                                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24, color: Color(0xFFF3F4F6)),
                                      Row(
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {{}},
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isPaid ? Colors.grey.shade100 : const Color(0xFFDCFCE7),
                                              foregroundColor: isPaid ? Colors.grey : const Color(0xFF166534),
                                              elevation: 0,
                                              minimumSize: const Size(0, 36),
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              shape: const StadiumBorder(),
                                            ),
                                            child: Text(
                                              isPaid ? '{S["collected"]}' : '{S["collect"]}',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton(
                                            onPressed: () => showDialog(
                                              context: context,
                                              builder: (_) => BillDetailDialog(bill: b),
                                            ),
                                            child: Text(
                                              '{S["detail"]}',
                                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                                            ),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            onPressed: () {{}},
                                            icon: const Icon(Icons.share_outlined, color: Colors.grey, size: 20),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }},
                          );
                        }},
                      );
                    }},
                  );
                }},
              ),
            ),
          ],
        ),
      ),
    );
  }}

  Widget _filterChip(String label, String value) {{
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
        labelStyle: TextStyle(
          color: isSelected ? primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
        shape: StadiumBorder(side: BorderSide(color: isSelected ? primaryColor : Colors.grey.shade200)),
      ),
    );
  }}

  Widget _statusBadge(String label, Color color) {{
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }}
}}
'''

out = Path(__file__).resolve().parent.parent / "lib" / "screens" / "bill" / "bill_list_screen.dart"
out.write_text(dart, encoding="utf-8")
print("wrote", out)
