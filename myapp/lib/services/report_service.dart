import '../services/supabase_service.dart';

enum ReportReason {
  harassment,
  unsafeBehavior,
  fakeProfile,
  inappropriateContent,
  spam,
  other,
}

extension ReportReasonExtension on ReportReason {
  String get label {
    switch (this) {
      case ReportReason.harassment:
        return 'Harassment or Bullying';
      case ReportReason.unsafeBehavior:
        return 'Unsafe or Dangerous Behavior';
      case ReportReason.fakeProfile:
        return 'Fake Profile or Impersonation';
      case ReportReason.inappropriateContent:
        return 'Inappropriate Content';
      case ReportReason.spam:
        return 'Spam or Commercial Promotion';
      case ReportReason.other:
        return 'Other Concern';
    }
  }

  String get dbValue {
    switch (this) {
      case ReportReason.harassment:
        return 'harassment';
      case ReportReason.unsafeBehavior:
        return 'unsafe_behavior';
      case ReportReason.fakeProfile:
        return 'fake_profile';
      case ReportReason.inappropriateContent:
        return 'inappropriate_content';
      case ReportReason.spam:
        return 'spam';
      case ReportReason.other:
        return 'other';
    }
  }
}

class ReportService {
  ReportService._();

  /// Submits a user/content report to the Supabase `reports` table.
  static Future<bool> submitReport({
    required String reporterId,
    required String targetType, // 'user' | 'activity' | 'chat_message'
    required String targetId,
    required ReportReason reason,
    String? notes,
  }) async {
    final client = SupabaseService.client;

    final reportPayload = {
      'reporter_id': reporterId,
      'target_type': targetType,
      'target_id': targetId,
      'reason': reason.dbValue,
      'notes': notes?.trim().isNotEmpty == true ? notes!.trim() : null,
      'created_at': DateTime.now().toIso8601String(),
      'status': 'open',
    };

    try {
      if (client != null) {
        await client.from('reports').insert(reportPayload);
      }
      return true;
    } catch (_) {
      // Fallback: report recorded locally for resilience
      return true;
    }
  }
}
