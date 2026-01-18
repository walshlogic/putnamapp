/// Represents a sex offender record from the registry
class SexOffender {
  SexOffender({
    this.id,
    required this.name,
    required this.address,
    required this.city,
    this.imageUrl,
    this.birthDate,
    this.status,
  });

  final String? id; // Optional ID for navigation
  final String name;
  final String address;
  final String city;
  final String? imageUrl;
  final DateTime? birthDate;
  final String? status;

  /// Calculate age from birth date
  String get age {
    if (birthDate == null) return 'N/A';
    final int years = DateTime.now().difference(birthDate!).inDays ~/ 365;
    return years.toString();
  }
}

