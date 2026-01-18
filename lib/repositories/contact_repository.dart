import 'package:supabase_flutter/supabase_flutter.dart';

import '../exceptions/app_exceptions.dart';
import '../models/contact_message.dart';

/// Abstract repository for contact message operations
abstract class ContactRepository {
  /// Submit a new contact message
  Future<ContactMessage> submitMessage({
    required String name,
    String? email,
    String? phone,
    required String department,
    required String messageTitle,
    required String messageBody,
    bool pleaseContactMe = false,
  });
}

/// Supabase implementation of ContactRepository
class SupabaseContactRepository implements ContactRepository {
  SupabaseContactRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<ContactMessage> submitMessage({
    required String name,
    String? email,
    String? phone,
    required String department,
    required String messageTitle,
    required String messageBody,
    bool pleaseContactMe = false,
  }) async {
    try {
      // Validate that at least one contact method is provided
      if (email == null || email.isEmpty) {
        if (phone == null || phone.isEmpty) {
          throw const DatabaseException('Either email or phone must be provided');
        }
      }

      // Validate department
      if (!['SUPPORT', 'SALES', 'REQUEST', 'GENERAL'].contains(department)) {
        throw const DatabaseException('Invalid department');
      }

      // Use the RPC function to submit the message
      // This allows anonymous users to submit messages
      final response = await _client.rpc(
        'submit_contact_message',
        params: {
          'p_name': name,
          'p_email': email,
          'p_phone': phone,
          'p_department': department,
          'p_message_title': messageTitle,
          'p_message_body': messageBody,
          'p_please_contact_me': pleaseContactMe,
        },
      ).timeout(const Duration(seconds: 10));

      if (response == null) {
        throw const DatabaseException('Failed to submit message');
      }

      // Fetch the created message to return full details
      final messageId = response.toString();
      final responseData = await _client
          .from('contact_messages')
          .select()
          .eq('id', messageId)
          .single()
          .timeout(const Duration(seconds: 10));

      return ContactMessage.fromJson(responseData);
    } catch (e) {
      if (e is PostgrestException) {
        throw DatabaseException('Failed to submit message: ${e.message}', e);
      }
      if (e is DatabaseException) {
        rethrow;
      }
      throw DatabaseException('Failed to submit message: $e');
    }
  }
}

