import 'package:intl/intl.dart';

/// Represents a traffic citation from Clerk of Court records
class TrafficCitation {
  TrafficCitation({
    required this.id,
    required this.citationDate,
    required this.caseNumber,
    required this.fullCaseNumber,
    required this.violationDescription,
    this.licensePlate,
    required this.lastName,
    required this.firstName,
    this.middleName,
    this.dateOfBirth,
    this.gender,
    this.licenseNumber,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.dispositionDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final DateTime citationDate;
  final String caseNumber;
  final String fullCaseNumber;
  final String violationDescription;
  final String? licensePlate;
  final String lastName;
  final String firstName;
  final String? middleName;
  final DateTime? dateOfBirth;
  final String? gender; // M, F, or null
  final String? licenseNumber;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final DateTime? dispositionDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Full name (last, first middle initial)
  String get fullName {
    final StringBuffer name = StringBuffer();
    name.write(lastName.toUpperCase());
    if (firstName.isNotEmpty) {
      name.write(', ${firstName.toUpperCase()}');
    }
    if (middleName != null && middleName!.isNotEmpty) {
      // Only show first letter of middle name
      final String middleInitial = middleName!.trim().substring(0, 1).toUpperCase();
      name.write(' $middleInitial');
    }
    return name.toString();
  }

  /// Violation description truncated to 30 characters
  String get violationDescriptionShort {
    if (violationDescription.length <= 30) {
      return violationDescription;
    }
    return '${violationDescription.substring(0, 27)}...';
  }

  /// Formatted citation date string
  String get citationDateString =>
      DateFormat('MM/dd/yyyy').format(citationDate);

  /// Formatted disposition date string (if available)
  String? get dispositionDateString =>
      dispositionDate != null
          ? DateFormat('MM/dd/yyyy').format(dispositionDate!)
          : null;

  /// Formatted date of birth string (if available)
  String? get dateOfBirthString =>
      dateOfBirth != null
          ? DateFormat('MM/dd/yyyy').format(dateOfBirth!)
          : null;

  /// Full address string
  String get fullAddress {
    final List<String> parts = <String>[];
    if (address != null && address!.isNotEmpty) {
      parts.add(address!.toUpperCase());
    }
    if (city != null && city!.isNotEmpty) {
      parts.add(city!.toUpperCase());
    }
    if (state != null && state!.isNotEmpty) {
      parts.add(state!);
    }
    if (zipCode != null && zipCode!.isNotEmpty) {
      parts.add(zipCode!);
    }
    return parts.join(', ');
  }

  /// Check if citation is within the last 30 days
  bool isRecent() {
    final DateTime cutoff = DateTime.now().subtract(const Duration(days: 30));
    return citationDate.isAfter(cutoff);
  }

  /// Check if citation is within the last 7 days
  bool isVeryRecent() {
    final DateTime cutoff = DateTime.now().subtract(const Duration(days: 7));
    return citationDate.isAfter(cutoff);
  }

  /// Parse from Supabase data
  factory TrafficCitation.fromJson(Map<String, dynamic> json) {
    return TrafficCitation(
      id: json['id'] as int,
      citationDate: DateTime.parse(json['citation_date'] as String),
      caseNumber: json['case_number'] as String,
      fullCaseNumber: json['full_case_number'] as String,
      violationDescription: json['violation_description'] as String,
      licensePlate: json['license_plate'] as String?,
      lastName: json['last_name'] as String,
      firstName: json['first_name'] as String,
      middleName: json['middle_name'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      gender: json['gender'] as String?,
      licenseNumber: json['license_number'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zip_code'] as String?,
      dispositionDate: json['disposition_date'] != null
          ? DateTime.parse(json['disposition_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'citation_date': citationDate.toIso8601String(),
      'case_number': caseNumber,
      'full_case_number': fullCaseNumber,
      'violation_description': violationDescription,
      'license_plate': licensePlate,
      'last_name': lastName,
      'first_name': firstName,
      'middle_name': middleName,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'license_number': licenseNumber,
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'disposition_date': dispositionDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

