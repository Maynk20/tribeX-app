import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_item.dart';
import '../services/supabase_service.dart';

class NotificationsState extends ChangeNotifier {
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  RealtimeChannel? _notificationsChannel;
  String? _userId;

  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void initUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    if (_userId != null) {
      fetchNotifications();
      _subscribeRealtime();
    } else {
      _notifications.clear();
      _notificationsChannel?.unsubscribe();
      notifyListeners();
    }
  }

  Future<void> fetchNotifications() async {
    if (_userId == null) return;
    final client = SupabaseService.client;
    if (client == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final res = await client
          .from('notifications')
          .select()
          .eq('user_id', _userId!)
          .order('created_at', ascending: false);

      _notifications = (res as List<dynamic>)
          .map(
            (json) => NotificationItem.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      // ignore
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribeRealtime() {
    _notificationsChannel?.unsubscribe();
    if (_userId == null) return;
    final client = SupabaseService.client;
    if (client == null) return;

    _notificationsChannel = client
        .channel('public:notifications:$_userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId!,
          ),
          callback: (payload) {
            fetchNotifications();
          },
        )
        .subscribe();
  }

  Future<void> markAllAsRead() async {
    if (_userId == null) return;
    final client = SupabaseService.client;
    if (client == null) return;

    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();

    try {
      await client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', _userId!)
          .eq('is_read', false);
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    final client = SupabaseService.client;
    if (client == null) return;

    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      notifyListeners();

      try {
        await client
            .from('notifications')
            .update({'is_read': true})
            .eq('id', id);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _notificationsChannel?.unsubscribe();
    super.dispose();
  }
}
