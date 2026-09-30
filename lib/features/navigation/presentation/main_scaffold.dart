import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/admin_drawer.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/notifications_sheet.dart';
import '../../academia/presentation/academia_screen.dart';
import '../../auth/data/auth_provider.dart';
import '../../diezmos/presentation/diezmos_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../oracion/presentation/oracion_screen.dart';
import '../../perfil/presentation/perfil_screen.dart';
import '../../redes/presentation/redes_screen.dart';

class _TabItem {
  final String id;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
  final bool isAdminOnly;

  const _TabItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
    this.isAdminOnly = false,
  });
}

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;
  bool _recoveryDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPasswordRecovery();
    });
  }

  void _checkPasswordRecovery() {
    final authState = ref.read(authStateProvider);
    if (authState.isPasswordRecovery && !_recoveryDialogShown && mounted) {
      _recoveryDialogShown = true;
      _showSetNewPasswordDialog();
    }
  }

  void _showSetNewPasswordDialog() {
    final formKey = GlobalKey<FormState>();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSaving = false;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.lock_reset, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Establecer Nueva Contraseña',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Has ingresado mediante el enlace de recuperación. Ingresa tu nueva contraseña para acceder en el futuro:',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary),
                  ),
                  const SizedBox(height: 14),
                  if (errorText != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Text(
                        errorText!,
                        style: GoogleFonts.inter(color: const Color(0xFF991B1B), fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  TextFormField(
                    controller: newPassCtrl,
                    obscureText: obscureNew,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Nueva Contraseña *',
                      prefixIcon: const Icon(Icons.lock_outline, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 18),
                        onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) {
                      if (val == null || val.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPassCtrl,
                    obscureText: obscureConfirm,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Confirmar Contraseña *',
                      prefixIcon: const Icon(Icons.lock_outline, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 18),
                        onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) {
                      if (val != newPassCtrl.text) return 'Las contraseñas no coinciden';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() {
                        isSaving = true;
                        errorText = null;
                      });

                      try {
                        final client = ref.read(supabaseClientProvider);
                        await client.auth.updateUser(
                          UserAttributes(password: newPassCtrl.text),
                        );
                        ref.read(authStateProvider.notifier).completePasswordRecovery();

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFF16A34A),
                              content: Text('¡Contraseña actualizada con éxito!'),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          isSaving = false;
                          errorText = 'Error al actualizar contraseña: $e';
                        });
                      }
                    },
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Guardar Contraseña', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _onDestinationSelected(dynamic target, List<_TabItem> visibleTabs) {
    if (target is int) {
      if (target >= 0 && target < visibleTabs.length) {
        setState(() => _currentIndex = target);
      }
    } else if (target is String) {
      final idx = visibleTabs.indexWhere((t) => t.id == target);
      if (idx != -1) {
        setState(() => _currentIndex = idx);
      }
    }
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const NotificationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.userProfile;
    final hasAdminAccess = user?.hasAdminAccess ?? false;
    final hasRedesAccess = user?.hasRedesAccess ?? false;

    final allTabs = [
      _TabItem(
        id: 'inicio',
        label: 'Inicio',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        screen: HomeScreen(
          onTabChange: (target) {
            final tabs = [
              _TabItem(id: 'inicio', label: 'Inicio', icon: Icons.home_outlined, selectedIcon: Icons.home, screen: const SizedBox()),
              _TabItem(id: 'abc', label: 'ABC', icon: Icons.school_outlined, selectedIcon: Icons.school, screen: const SizedBox()),
              if (hasRedesAccess)
                _TabItem(id: 'redes', label: 'Redes', icon: Icons.groups_outlined, selectedIcon: Icons.groups, screen: const SizedBox(), isAdminOnly: true),
              _TabItem(id: 'oracion', label: 'Oración', icon: Icons.wb_twilight_outlined, selectedIcon: Icons.wb_twilight, screen: const SizedBox()),
              if (hasAdminAccess)
                _TabItem(id: 'diezmos', label: 'Diezmos', icon: Icons.volunteer_activism_outlined, selectedIcon: Icons.volunteer_activism, screen: const SizedBox(), isAdminOnly: true),
              _TabItem(id: 'perfil', label: 'Perfil', icon: Icons.person_outline, selectedIcon: Icons.person, screen: const SizedBox()),
            ];
            _onDestinationSelected(target, tabs);
          },
        ),
      ),
      _TabItem(
        id: 'abc',
        label: 'ABC',
        icon: Icons.school_outlined,
        selectedIcon: Icons.school,
        screen: const AcademiaScreen(),
      ),
      _TabItem(
        id: 'redes',
        label: 'Redes',
        icon: Icons.groups_outlined,
        selectedIcon: Icons.groups,
        screen: const RedesScreen(),
        isAdminOnly: true,
      ),
      _TabItem(
        id: 'oracion',
        label: 'Oración',
        icon: Icons.wb_twilight_outlined,
        selectedIcon: Icons.wb_twilight,
        screen: const OracionScreen(),
      ),
      _TabItem(
        id: 'diezmos',
        label: 'Diezmos',
        icon: Icons.volunteer_activism_outlined,
        selectedIcon: Icons.volunteer_activism,
        screen: const DiezmosScreen(),
        isAdminOnly: true,
      ),
      _TabItem(
        id: 'perfil',
        label: 'Perfil',
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        screen: const PerfilScreen(),
      ),
    ];

    final visibleTabs = allTabs.where((t) {
      if (t.id == 'redes') return hasRedesAccess;
      return !t.isAdminOnly || hasAdminAccess;
    }).toList();
    if (_currentIndex >= visibleTabs.length) {
      _currentIndex = 0;
    }

    final screens = visibleTabs.map((t) => t.screen).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth >= 768;

        if (isLargeScreen) {
          // PC / Desktop / Tablet Layout
          return Scaffold(
            appBar: AppHeader(
              onNotificationTap: _showNotifications,
            ),
            drawer: hasAdminAccess
                ? AdminDrawer(onSelectTab: (idx) => _onDestinationSelected(idx, visibleTabs))
                : null,
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (idx) => _onDestinationSelected(idx, visibleTabs),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: AppColors.surfaceContainerLowest,
                  indicatorColor: AppColors.primary,
                  indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  selectedIconTheme: const IconThemeData(color: Colors.white, size: 24),
                  unselectedIconTheme: const IconThemeData(color: AppColors.secondary, size: 22),
                  selectedLabelTextStyle: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  unselectedLabelTextStyle: GoogleFonts.inter(
                    color: AppColors.secondary,
                    fontSize: 11,
                  ),
                  minWidth: 84,
                  destinations: visibleTabs
                      .map((t) => NavigationRailDestination(
                            icon: Icon(t.icon, color: AppColors.secondary),
                            selectedIcon: Icon(t.selectedIcon, color: Colors.white),
                            label: Text(t.label),
                          ))
                      .toList(),
                ),
                const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: IndexedStack(
                        index: _currentIndex,
                        children: screens,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile / Android Layout
        return Scaffold(
          appBar: AppHeader(
            onNotificationTap: _showNotifications,
          ),
          drawer: hasAdminAccess
              ? AdminDrawer(onSelectTab: (idx) => _onDestinationSelected(idx, visibleTabs))
              : null,
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (idx) => _onDestinationSelected(idx, visibleTabs),
            backgroundColor: AppColors.surfaceContainerLowest,
            indicatorColor: AppColors.primary,
            indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            destinations: visibleTabs
                .map((t) => NavigationDestination(
                      icon: Icon(t.icon, color: AppColors.secondary),
                      selectedIcon: Icon(t.selectedIcon, color: Colors.white),
                      label: t.label,
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}
