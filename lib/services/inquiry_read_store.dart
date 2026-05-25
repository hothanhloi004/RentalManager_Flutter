import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Giống Android `rental_manager_notifications` / `read_inquiry_ids`.
class InquiryReadStore extends ChangeNotifier {
  InquiryReadStore._();
  static final InquiryReadStore instance = InquiryReadStore._();

  static const _prefsName = 'rental_manager_notifications';
  static const _keyReadIds = 'read_inquiry_ids';

  Set<String> _readIds = {};
  bool _loaded = false;

  Set<String> get readIds => Set.unmodifiable(_readIds);

  bool isRead(String id) => _readIds.contains(id);

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _readIds = (prefs.getStringList(_keyReadIds) ?? []).toSet();
    _loaded = true;
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    await ensureLoaded();
    if (!_readIds.add(id)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyReadIds, _readIds.toList());
    notifyListeners();
  }

  Future<void> clearReadIds() async {
    _readIds = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyReadIds);
    notifyListeners();
  }

  int countUnread(Iterable<String> allIds) {
    if (!_loaded) return 0;
    var n = 0;
    for (final id in allIds) {
      if (!_readIds.contains(id)) n++;
    }
    return n;
  }
}
