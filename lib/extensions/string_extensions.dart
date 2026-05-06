extension StringExtensions on String {
  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Check if string is valid URL
  bool isValidUrl() {
    try {
      Uri.parse(this);
      return startsWith('http://') || startsWith('https://');
    } catch (e) {
      return false;
    }
  }

  /// Truncate string to specific length
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }

  /// Remove spaces
  String removeSpaces() => replaceAll(' ', '');

  /// Check if numeric
  bool isNumeric() => num.tryParse(this) != null;

  /// Check if the URL is a blocked domain
  bool isBlockedDomain() {
    final lower = toLowerCase();
    const blocked = [
      'spam', 'ads', 'popup', 'malware', 'tracking',
      'doubleclick', 'googlesyndication', 'ad.doubleclick',
    ];
    return blocked.any((domain) => lower.contains(domain));
  }
}

extension DateTimeExtensions on DateTime {
  /// Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} سنة';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} شهر';
    if (diff.inDays > 7) return '${(diff.inDays / 7).floor()} أسبوع';
    if (diff.inDays > 0) return '${diff.inDays} يوم';
    if (diff.inHours > 0) return '${diff.inHours} ساعة';
    if (diff.inMinutes > 0) return '${diff.inMinutes} دقيقة';
    return 'الآن';
  }
}

extension DoubleExtensions on double {
  /// Format rating
  String get asRating => toStringAsFixed(1);
}

extension ListExtensions<T> on List<T> {
  /// Get a safe sublist
  List<T> safeSublist(int start, [int? end]) {
    if (isEmpty) return [];
    final safeStart = start.clamp(0, length);
    final safeEnd = (end ?? length).clamp(safeStart, length);
    return sublist(safeStart, safeEnd);
  }
}
