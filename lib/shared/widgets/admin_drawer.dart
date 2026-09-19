import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/data/auth_provider.dart';

class AdminDrawer extends ConsumerWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.userProfile;

    // Strict security check: If user does not have admin access, do not render drawer
    if (user == null || !user.hasAdminAccess) {
      return const SizedBox.shrink();
    }

    final userName = user.name;
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    final roleTitle = user.roleTranslated;

    return Drawer(
      backgroundColor: AppColors.primary,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drawer Brand Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SvgPicture.asset(
                      'assets/images/logo.svg',
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.church, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alianza Chaclacayo',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'PANEL BACKOFFICE',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onPrimaryContainer,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white12, height: 1),

            // Authorized Navigation Links
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                children: [
                  if (user.isPastor) ...[
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.dashboard_outlined,
                      label: 'Dashboard General',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Accediendo a Dashboard General...')),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.groups_outlined,
                      label: 'Directorio de Miembros',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Accediendo a Directorio de Miembros...')),
                        );
                      },
                    ),
                  ],

                  if (user.isAcademyCoordinator || user.isPastor) ...[
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.school_outlined,
                      label: 'Gestión de Academia ABC',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Accediendo a Gestión de Academia...')),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.how_to_reg_outlined,
                      label: 'Reporte de Asistencias ABC',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Accediendo a Reporte de Asistencias...')),
                        );
                      },
                    ),
                  ],

                  if (user.isTreasuryAdmin || user.isPastor) ...[
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.payments_outlined,
                      label: 'Tesorería Reservada',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Accediendo a Bandeja de Tesorería...')),
                        );
                      },
                    ),
                  ],

                  if (user.isCultoAdmin || user.isPastor) ...[
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.church_outlined,
                      label: 'Conteo de Culto Dominical',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Accediendo a Conteo de Culto...')),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

            const Divider(color: Colors.white12, height: 1),

            // User Info Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryContainer,
                    child: Text(
                      userInitial,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          roleTitle,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.onPrimaryContainer,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
                    onPressed: () async {
                      await ref.read(authStateProvider.notifier).signOut();
                    },
                    tooltip: 'Cerrar sesión',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70, size: 22),
        title: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}
