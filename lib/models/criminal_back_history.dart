import 'package:intl/intl.dart';

/// Represents a criminal back history record from Clerk of Court records
class CriminalBackHistory {
  CriminalBackHistory({
    required this.id,
    required this.caseNumber,
    required this.uniformCaseNumber,
    required this.defendantLastName,
    required this.defendantFirstName,
    this.defendantMiddleName,
    this.dateOfBirth,
    this.addressLine1,
    this.city,
    this.state,
    this.zipcode,
    this.clerkFileDate,
    this.prosDecisionDate,
    this.courtDecisionDate,
    this.statuteDescription,
    this.courtActionDescription,
    this.prosecutorActionDescription,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String caseNumber;
  final String uniformCaseNumber;
  final String defendantLastName;
  final String defendantFirstName;
  final String? defendantMiddleName;
  final DateTime? dateOfBirth;
  final String? addressLine1;
  final String? city;
  final String? state;
  final String? zipcode;
  final DateTime? clerkFileDate;
  final DateTime? prosDecisionDate;
  final DateTime? courtDecisionDate;
  final String? statuteDescription;
  final String? courtActionDescription;
  final String? prosecutorActionDescription;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Full name (last, first middle initial)
  String get fullName {
    final StringBuffer name = StringBuffer();
    name.write(defendantLastName.toUpperCase());
    if (defendantFirstName.isNotEmpty) {
      name.write(', ${defendantFirstName.toUpperCase()}');
    }
    if (defendantMiddleName != null && defendantMiddleName!.isNotEmpty) {
      // Only show first letter of middle name
      final String middleInitial = defendantMiddleName!.trim().substring(0, 1).toUpperCase();
      name.write(' $middleInitial');
    }
    return name.toString();
  }

  /// Statute description truncated to 40 characters
  String get statuteDescriptionShort {
    if (statuteDescription == null || statuteDescription!.isEmpty) {
      return 'N/A';
    }
    if (statuteDescription!.length <= 40) {
      return statuteDescription!;
    }
    return '${statuteDescription!.substring(0, 37)}...';
  }

  /// Formatted clerk file date string
  String? get clerkFileDateString =>
      clerkFileDate != null
          ? DateFormat('MM/dd/yyyy').format(clerkFileDate!)
          : null;

  /// Formatted court decision date string
  String? get courtDecisionDateString =>
      courtDecisionDate != null
          ? DateFormat('MM/dd/yyyy').format(courtDecisionDate!)
          : null;

  /// Formatted date of birth string
  String? get dateOfBirthString =>
      dateOfBirth != null
          ? DateFormat('MM/dd/yyyy').format(dateOfBirth!)
          : null;

  /// Full address string
  String get fullAddress {
    final List<String> parts = <String>[];
    if (addressLine1 != null && addressLine1!.isNotEmpty) {
      parts.add(addressLine1!.toUpperCase());
    }
    if (city != null && city!.isNotEmpty) {
      parts.add(city!.toUpperCase());
    }
    if (state != null && state!.isNotEmpty) {
      parts.add(state!);
    }
    if (zipcode != null && zipcode!.isNotEmpty) {
      parts.add(zipcode!);
    }
    return parts.join(', ');
  }

  /// Check if case is within the last 30 days
  bool isRecent() {
    if (clerkFileDate == null) {
      return false;
    }
    final DateTime cutoff = DateTime.now().subtract(const Duration(days: 30));
    return clerkFileDate!.isAfter(cutoff);
  }

  /// Parse from Supabase data
  factory CriminalBackHistory.fromJson(Map<String, dynamic> json) {
    return CriminalBackHistory(
      id: json['id'] as int,
      caseNumber: json['case_number'] as String,
      uniformCaseNumber: json['uniform_case_number'] as String,
      defendantLastName: json['defendant_last_name'] as String,
      defendantFirstName: json['defendant_first_name'] as String,
      defendantMiddleName: json['defendant_middle_name'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      addressLine1: json['address_line_1'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipcode: json['zipcode'] as String?,
      clerkFileDate: json['clerk_file_date'] != null
          ? DateTime.parse(json['clerk_file_date'] as String)
          : null,
      prosDecisionDate: json['pros_decision_date'] != null
          ? DateTime.parse(json['pros_decision_date'] as String)
          : null,
      courtDecisionDate: json['court_decision_date'] != null
          ? DateTime.parse(json['court_decision_date'] as String)
          : null,
      statuteDescription: json['statute_description'] as String?,
      courtActionDescription: json['court_action_description'] as String?,
      prosecutorActionDescription: json['prosecutor_action_description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'case_number': caseNumber,
      'uniform_case_number': uniformCaseNumber,
      'defendant_last_name': defendantLastName,
      'defendant_first_name': defendantFirstName,
      'defendant_middle_name': defendantMiddleName,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'address_line_1': addressLine1,
      'city': city,
      'state': state,
      'zipcode': zipcode,
      'clerk_file_date': clerkFileDate?.toIso8601String(),
      'pros_decision_date': prosDecisionDate?.toIso8601String(),
      'court_decision_date': courtDecisionDate?.toIso8601String(),
      'statute_description': statuteDescription,
      'court_action_description': courtActionDescription,
      'prosecutor_action_description': prosecutorActionDescription,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

