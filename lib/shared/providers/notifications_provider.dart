import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/data/auth_provider.dart';

class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String desc;
  final String? category;
  final String? time;
  final IconData icon;
  final Color iconColor;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.desc,
    this.category,
    this.time,
    required this.icon,
    required this.iconColor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'desc': desc,
      'category': category,
      'time': time,
      'icon': icon,
      'iconColor': iconColor,
    };
  }
}

class NotificationsState {
  final bool isLoading;
  final List<NotificationItem> items;

  const NotificationsState({
    this.isLoading = false,
    this.items = const [],
  });

  int get unreadCount => items.length;

  NotificationsState copyWith({
    bool? isLoading,
    List<NotificationItem>? items,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
    );
  }
}

class NotificationsNotifier extends Notifier<NotificationsState> {
  static const _storageKey = 'dismissed_notification_ids_v1';
  static const _storage = FlutterSecureStorage();
  Set<String> _dismissedIds = {};

  @override
  NotificationsState build() {
    Future.microtask(() => _init());
    return const NotificationsState(isLoading: true);
  }

  Future<void> _init() async {
    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        _dismissedIds = decoded.map((e) => e.toString()).toSet();
      }
    } catch (_) {}
    await fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true);
    final user = ref.read(authStateProvider).userProfile;
    final client = Supabase.instance.client;
    final List<NotificationItem> list = [];

    try {
      // 1. Fetch church announcements
      try {
        final annRes = await client
            .from('announcements')
            .select()
            .order('created_at', ascending: false)
            .limit(10);

        for (final a in (annRes as List)) {
          final id = 'ann_${a['id'] ?? a['title']}';
          if (_dismissedIds.contains(id)) continue;

          final title = a['title']?.toString() ?? 'Comunicado';
          final desc = a['description']?.toString() ?? a['content']?.toString() ?? '';
          final createdAt = a['created_at']?.toString();
          final category = a['category']?.toString() ?? 'General';

          list.add(NotificationItem(
            id: id,
            type: 'announcement',
            title: title,
            desc: desc,
            category: category,
            time: createdAt,
            icon: Icons.campaign,
            iconColor: AppColors.primary,
          ));
        }
      } catch (_) {}

      // 2. Fetch user-specific notifications if logged in
      if (user != null) {
        // Academy enrollments / course notices
        try {
          final enrRes = await client
              .from('enrollments')
              .select('*, courses(*)')
              .eq('student_id', user.id)
              .order('created_at', ascending: false)
              .limit(5);

          for (final e in (enrRes as List)) {
            final course = e['courses'] as Map<String, dynamic>?;
            if (course != null) {
              final isAppr = e['is_approved'] == true;
              final grade = e['final_grade'];
              final id = 'enr_${e['id']}_${isAppr ? "appr" : "enr"}_${grade ?? ""}';
              if (_dismissedIds.contains(id)) continue;

              if (isAppr) {
                list.add(NotificationItem(
                  id: id,
                  type: 'academy',
                  title: '¡Curso Aprobado! 🎉',
                  desc: 'Has completado formalmente "${course['code']}: ${course['title']}" con nota $grade.',
                  time: e['created_at'],
                  icon: Icons.verified,
                  iconColor: const Color(0xFF16A34A),
                ));
              } else {
                list.add(NotificationItem(
                  id: id,
                  type: 'academy',
                  title: 'Matrícula en ${course['code']}',
                  desc: 'Estás inscrito en "${course['title']}" (${course['schedule'] ?? 'Horario regular'}).',
                  time: e['created_at'],
                  icon: Icons.school,
                  iconColor: AppColors.primary,
                ));
              }
            }
          }
        } catch (_) {}

        // Tithes & offerings verification status
        try {
          final tithesRes = await client
              .from('tithes_offerings')
              .select()
              .eq('user_id', user.id)
              .order('created_at', ascending: false)
              .limit(5);

          for (final t in (tithesRes as List)) {
            final status = t['status']?.toString().toLowerCase();
            final amount = t['amount']?.toString() ?? '0.00';
            final type = t['type']?.toString() ?? 'Aporte';
            final id = 'tithe_${t['id']}_$status';
            if (_dismissedIds.contains(id)) continue;

            if (status == 'verificado' || status == 'aprobado') {
              list.add(NotificationItem(
                id: id,
                type: 'tithe',
                title: 'Aporte Confirmado por Tesorería',
                desc: 'Tu registro de $type por S/ $amount ha sido verificado con éxito.',
                time: t['created_at'],
                icon: Icons.check_circle,
                iconColor: const Color(0xFF16A34A),
              ));
            } else if (status == 'pendiente') {
              list.add(NotificationItem(
                id: id,
                type: 'tithe',
                title: 'Comprobante de $type en Revisión',
                desc: 'Tu comprobante por S/ $amount está en proceso de verificación.',
                time: t['created_at'],
                icon: Icons.hourglass_top,
                iconColor: const Color(0xFFD97706),
              ));
            }
          }
        } catch (_) {}
      }

      // 3. YouTube live / Sunday service info
      try {
        final settingRes = await client
            .from('church_settings')
            .select('key, value')
            .eq('key', 'youtube_live_url')
            .maybeSingle();

        if (settingRes != null && settingRes['value'] != null && settingRes['value'].toString().isNotEmpty) {
          final liveVal = settingRes['value'].toString();
          final id = 'live_${liveVal.hashCode}';
          if (!_dismissedIds.contains(id)) {
            list.add(NotificationItem(
              id: id,
              type: 'live',
              title: 'Culto y Transmisión en Vivo',
              desc: 'Conéctate a la transmisión dominical de la iglesia por YouTube.',
              time: DateTime.now().toIso8601String(),
              icon: Icons.live_tv,
              iconColor: const Color(0xFFDC2626),
            ));
          }
        }
      } catch (_) {}

      // Sort all notifications by time descending
      list.sort((a, b) {
        final tA = DateTime.tryParse(a.time ?? '') ?? DateTime(2020);
        final tB = DateTime.tryParse(b.time ?? '') ?? DateTime(2020);
        return tB.compareTo(tA);
      });

      state = state.copyWith(isLoading: false, items: list);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> dismissNotification(String id) async {
    _dismissedIds.add(id);
    await _saveDismissed();
    final updated = state.items.where((it) => it.id != id).toList();
    state = state.copyWith(items: updated);
  }

  Future<void> clearAll() async {
    for (final item in state.items) {
      _dismissedIds.add(item.id);
    }
    await _saveDismissed();
    state = state.copyWith(items: []);
  }

  Future<void> _saveDismissed() async {
    try {
      await _storage.write(key: _storageKey, value: jsonEncode(_dismissedIds.toList()));
    } catch (_) {}
  }
}

final notificationsProvider = NotifierProvider<NotificationsNotifier, NotificationsState>(() {
  return NotificationsNotifier();
});

final notificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).unreadCount;
});
