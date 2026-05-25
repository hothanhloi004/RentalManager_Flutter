import 'package:flutter/material.dart';

/// Mở màn phụ từ Dashboard (có nút quay lại trên AppBar / header).
Future<T?> pushSubPage<T>(BuildContext context, Widget page) {
  return Navigator.push<T>(
    context,
    MaterialPageRoute(builder: (_) => page),
  );
}
