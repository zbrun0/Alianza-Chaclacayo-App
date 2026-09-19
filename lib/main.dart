import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_provider.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/navigation/presentation/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    publishableKey: AppConstants.supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: AlianzaChaclacayoApp(),
    ),
  );
}

class AlianzaChaclacayoApp extends ConsumerWidget {
  const AlianzaChaclacayoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Alianza Chaclacayo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authState.isLoading
          ? Scaffold(
              body: SizedBox.expand(
                child: Image.asset(
                  'assets/images/splash.png',
                  fit: BoxFit.cover,
                ),
              ),
            )
          : (authState.isAuthenticated
              ? const MainScaffold()
              : const LoginScreen()),
    );
  }
}
