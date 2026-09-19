import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;

  void _onDestinationSelected(int index) {
    setState(() => _currentIndex = index);
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

    final screens = [
      HomeScreen(onTabChange: _onDestinationSelected),
      const AcademiaScreen(),
      const RedesScreen(),
      const OracionScreen(),
      const DiezmosScreen(),
      const PerfilScreen(),
    ];

    return Scaffold(
      appBar: AppHeader(
        onNotificationTap: _showNotifications,
      ),
      drawer: hasAdminAccess ? const AdminDrawer() : null,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'ABC',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Redes',
          ),
          NavigationDestination(
            icon: Icon(Icons.wb_twilight_outlined),
            selectedIcon: Icon(Icons.wb_twilight),
            label: 'Oración',
          ),
          NavigationDestination(
            icon: Icon(Icons.volunteer_activism_outlined),
            selectedIcon: Icon(Icons.volunteer_activism),
            label: 'Diezmos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
