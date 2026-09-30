import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/data/auth_provider.dart';

import '../../shared/providers/notifications_provider.dart';

class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback? onNotificationTap;

  const AppHeader({super.key, this.onNotificationTap});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.userProfile;
    final firstName = user != null ? user.firstName : 'Hermano/a';
    final hasAdminAccess = user?.hasAdminAccess ?? false;
    final unreadCount = ref.watch(notificationCountProvider);

    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: false,
      leading: hasAdminAccess
          ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: 'Panel Backoffice',
              ),
            )
          : null,
      titleSpacing: hasAdminAccess ? 0 : 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'IACYM Chaclacayo',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          Text(
            '¡Hola, $firstName!',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: AppColors.onPrimaryContainer,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              backgroundColor: const Color(0xFFC5875A),
              label: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            onPressed: onNotificationTap,
            tooltip: 'Notificaciones',
          ),
        ),
      ],
    );
  }
}
