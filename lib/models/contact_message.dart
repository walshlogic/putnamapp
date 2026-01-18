/// Model representing a contact message sent from the Contact Us screen
class ContactMessage {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String department; // SUPPORT, SALES, REQUEST, GENERAL
  final String messageTitle;
  final String messageBody;
  final bool pleaseContactMe;
  final String? userId;
  final String status; // NEW, READ, REPLIED, RESOLVED
  final DateTime createdAt;
  final DateTime updatedAt;

  ContactMessage({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.department,
    required this.messageTitle,
    required this.messageBody,
    this.pleaseContactMe = false,
    this.userId,
    this.status = 'NEW',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create ContactMessage from JSON
  factory ContactMessage.fromJson(Map<String, dynamic> json) {
    return ContactMessage(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      department: json['department'] as String,
      messageTitle: json['message_title'] as String,
      messageBody: json['message_body'] as String,
      pleaseContactMe: json['please_contact_me'] as bool? ?? false,
      userId: json['user_id'] as String?,
      status: json['status'] as String? ?? 'NEW',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert ContactMessage to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'department': department,
      'message_title': messageTitle,
      'message_body': messageBody,
      'please_contact_me': pleaseContactMe,
      'user_id': userId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  ContactMessage copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? department,
    String? messageTitle,
    String? messageBody,
    bool? pleaseContactMe,
    String? userId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContactMessage(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      messageTitle: messageTitle ?? this.messageTitle,
      messageBody: messageBody ?? this.messageBody,
      pleaseContactMe: pleaseContactMe ?? this.pleaseContactMe,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

