import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'room/room_list_screen.dart';
import 'tenant/tenant_list_screen.dart';
import 'bill/bill_list_screen.dart';
import 'contract/contract_list_screen.dart';

/// Thứ tự tab giống Android `bottom_menu.xml`: Tổng quan, Phòng, Khách, Hợp đồng, Hoá đơn.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _screens = [
    DashboardScreen(),
    RoomListScreen(),
    TenantListScreen(),
    ContractListScreen(),
    BillListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        height: 64,
        elevation: 0,
        backgroundColor: const Color(0xFFFFF7FF),
        indicatorColor: const Color(0xFFBFF7F4),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFF0F172A)),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF0F172A)),
            label: 'Phòng',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: Color(0xFF0F172A)),
            label: 'Khách',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description, color: Color(0xFF0F172A)),
            label: 'Hợp đồng',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: Color(0xFF0F172A)),
            label: 'H\u00f3a \u0111\u01a1n',
          ),
        ],
      ),
    );
  }
}
