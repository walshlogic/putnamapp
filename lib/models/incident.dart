import 'package:intl/intl.dart';

import 'incident_attachment.dart';
import 'incident_person.dart';

/// A public-safety event logged by an admin/elevated user.
class Incident {
  Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.occurredAt,
    required this.locationText,
    this.latitude,
    this.longitude,
    this.category,
    this.agencyIds = const <String>[],
    this.isActive = true,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.attachments = const <IncidentAttachment>[],
    this.persons = const <IncidentPerson>[],
  });

  final String id;
  final String title;
  final String description;

  /// Date-only — no time component. Stored as `date` in Postgres.
  final DateTime occurredAt;

  final String locationText;
  final double? latitude;
  final double? longitude;
  final String? category;

  /// Zero or more agency ids ('pcso', 'palatka_pd', etc.). Stored as text[].
  final List<String> agencyIds;

  final bool isActive;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Populated when the repository joins the attachments relation.
  final List<IncidentAttachment> attachments;

  /// Populated when the repository joins incident_persons.
  final List<IncidentPerson> persons;

  factory Incident.fromJson(Map<String, dynamic> json) {
    final List<IncidentAttachment> atts = json['incident_attachments'] != null
        ? (json['incident_attachments'] as List<dynamic>)
            .map((dynamic a) =>
                IncidentAttachment.fromJson(a as Map<String, dynamic>))
            .toList()
        : <IncidentAttachment>[];

    final List<IncidentPerson> ppl = json['incident_persons'] != null
        ? (json['incident_persons'] as List<dynamic>)
            .map((dynamic p) =>
                IncidentPerson.fromJson(p as Map<String, dynamic>))
            .toList()
        : <IncidentPerson>[];

    final List<String> agencies = json['agency_ids'] != null
        ? List<String>.from(json['agency_ids'] as List<dynamic>)
        : <String>[];

    return Incident(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      locationText: json['location_text'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      category: json['category'] as String?,
      agencyIds: agencies,
      isActive: json['is_active'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      attachments: atts..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      persons: ppl..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
    );
  }

  /// Map for INSERT/UPDATE on `public.incidents` itself. Persons + attachments
  /// are written separately via their own tables.
  /// `occurred_at` is sent as 'yyyy-MM-dd' so the Postgres `date` column gets
  /// the user-picked calendar day, not a timezone-shifted day.
  Map<String, dynamic> toJsonForWrite({required String createdByUid}) {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'occurred_at': DateFormat('yyyy-MM-dd').format(occurredAt),
      'location_text': locationText,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'agency_ids': agencyIds,
      'is_active': isActive,
      'created_by': createdByUid,
    };
  }

  Incident copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? occurredAt,
    String? locationText,
    double? latitude,
    double? longitude,
    String? category,
    List<String>? agencyIds,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<IncidentAttachment>? attachments,
    List<IncidentPerson>? persons,
  }) {
    return Incident(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      occurredAt: occurredAt ?? this.occurredAt,
      locationText: locationText ?? this.locationText,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      agencyIds: agencyIds ?? this.agencyIds,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachments: attachments ?? this.attachments,
      persons: persons ?? this.persons,
    );
  }
}

/// Common incident categories. Free-form text in the DB; this list is just
/// what the UI offers as quick picks.
class IncidentCategory {
  IncidentCategory._();

  static const String officerInvolvedShooting = 'officer_involved_shooting';
  static const String useOfForce = 'use_of_force';
  static const String trafficIncident = 'traffic_incident';
  static const String pursuit = 'pursuit';
  static const String communityEvent = 'community_event';
  static const String fire = 'fire';
  static const String weather = 'weather';
  static const String other = 'other';

  static const List<String> all = <String>[
    officerInvolvedShooting,
    useOfForce,
    trafficIncident,
    pursuit,
    communityEvent,
    fire,
    weather,
    other,
  ];

  static String label(String value) {
    switch (value) {
      case officerInvolvedShooting:
        return 'Officer-Involved Shooting';
      case useOfForce:
        return 'Use of Force';
      case trafficIncident:
        return 'Traffic Incident';
      case pursuit:
        return 'Pursuit';
      case communityEvent:
        return 'Community Event';
      case fire:
        return 'Fire';
      case weather:
        return 'Weather';
      case other:
        return 'Other';
      default:
        return value
            .split('_')
            .map((s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}')
            .join(' ');
    }
  }
}
