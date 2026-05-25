class RelativeTime {
  RelativeTime._();

  static String format(DateTime? time) {
    if (time == null) return 'V\u1eeba xong';
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'V\u1eeba xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} ph\u00fat tr\u01b0\u1edbc';
    if (diff.inHours < 24) return '${diff.inHours} gi\u1edd tr\u01b0\u1edbc';
    if (diff.inDays < 7) return '${diff.inDays} ng\u00e0y tr\u01b0\u1edbc';
    return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}';
  }
}
