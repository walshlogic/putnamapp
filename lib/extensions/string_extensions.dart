/// Extension methods for String
extension StringX on String {
  /// Convert to uppercase, returns empty string if already empty
  String toUpperCaseOrEmpty() => isEmpty ? '' : toUpperCase();

  /// Return 'N/A' if string is empty, otherwise return the string
  String orNA() => isEmpty ? 'N/A' : this;

  /// Return 'N/A' uppercased if string is empty, otherwise return uppercase string
  String toUpperCaseOrNA() => isEmpty ? 'N/A' : toUpperCase();

  /// Check if string is not null and not empty
  bool get isNotNullOrEmpty => isNotEmpty;

  /// Truncate string to a specific length with ellipsis
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }
}

/// Extension methods for nullable String
extension NullableStringX on String? {
  /// Return true if string is null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Return 'N/A' if null or empty, otherwise return the string
  String orNA() => this?.isEmpty ?? true ? 'N/A' : this!;

  /// Return default value if null or empty
  String orDefault(String defaultValue) =>
      this?.isEmpty ?? true ? defaultValue : this!;
}

