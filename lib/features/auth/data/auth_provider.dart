import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/push_notification_service.dart';
import 'user_model.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

class AuthState {
  final UserProfile? userProfile;
  final User? authUser;
  final bool isInitializing;
  final bool isLoading;
  final String? errorMessage;
  final bool isPasswordRecovery;

  AuthState({
    this.userProfile,
    this.authUser,
    this.isInitializing = false,
    this.isLoading = false,
    this.errorMessage,
    this.isPasswordRecovery = false,
  });

  bool get isAuthenticated => authUser != null;

  AuthState copyWith({
    UserProfile? userProfile,
    User? authUser,
    bool? isInitializing,
    bool? isLoading,
    String? errorMessage,
    bool? isPasswordRecovery,
    bool clearProfile = false,
  }) {
    return AuthState(
      userProfile: clearProfile ? null : (userProfile ?? this.userProfile),
      authUser: clearProfile ? null : (authUser ?? this.authUser),
      isInitializing: isInitializing ?? this.isInitializing,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isPasswordRecovery: isPasswordRecovery ?? this.isPasswordRecovery,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  SupabaseClient get _client => ref.read(supabaseClientProvider);

  @override
  AuthState build() {
    Future.microtask(() => _init());
    return AuthState(isInitializing: true, isLoading: false);
  }

  bool _isResettingPassword = false;

  void _init() async {
    final uri = Uri.base;
    final uriStr = uri.toString();
    final isRecoveryUri = uri.fragment.contains('type=recovery') ||
        uri.fragment.contains('reset_password') ||
        uri.queryParameters['type'] == 'recovery' ||
        uri.queryParameters.containsKey('reset_password') ||
        uriStr.contains('reset_password') ||
        uriStr.contains('type=recovery');

    _client.auth.onAuthStateChange.listen((data) {
      if (_isResettingPassword) return;
      final session = data.session;
      final isRecovery = isRecoveryUri;
      if (session != null) {
        _fetchProfile(session.user.id, session.user, isPasswordRecovery: isRecovery);
      } else {
        state = AuthState(isInitializing: false, isLoading: false);
      }
    });

    // 1. Check if the current URL contains an authentication or recovery error (e.g. otp_expired, access_denied)
    final hasQueryError = uri.queryParameters.containsKey('error') || uri.queryParameters.containsKey('error_code');
    final hasFragmentError = uri.fragment.contains('error=') || uri.fragment.contains('error_code=');

    if (hasQueryError || hasFragmentError) {
      final desc = uri.queryParameters['error_description'] ?? 'El enlace de recuperación es inválido o ha expirado.';
      // Critical security check: Force sign out and do not restore old localStorage sessions
      try {
        await _client.auth.signOut();
      } catch (_) {}

      final friendlyMsg = desc.contains('expired') || desc.contains('invalid')
          ? 'El enlace de recuperación ha expirado o ya fue utilizado. Por favor solicita uno nuevo desde la opción "¿Olvidaste tu contraseña?".'
          : 'Error de acceso: $desc';

      state = AuthState(
        isInitializing: false,
        isLoading: false,
        errorMessage: friendlyMsg,
      );
      return;
    }

    final currentSession = _client.auth.currentSession;
    if (currentSession != null) {
      _fetchProfile(currentSession.user.id, currentSession.user, isPasswordRecovery: isRecoveryUri);
    } else {
      state = AuthState(isInitializing: false, isLoading: false);
    }
  }

  void completePasswordRecovery() {
    state = state.copyWith(isPasswordRecovery: false);
  }

  Future<void> resetPasswordWithOtp({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    _isResettingPassword = true;
    try {
      await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.recovery,
      );
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      await _client.auth.signOut();
    } finally {
      _isResettingPassword = false;
      state = AuthState(isInitializing: false, isLoading: false);
    }
  }

  Future<void> _fetchProfile(String userId, User authUser, {bool isPasswordRecovery = false}) async {
    try {
      final res = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (res != null) {
        final profile = UserProfile.fromMap(res);
        state = AuthState(
          userProfile: profile,
          authUser: authUser,
          isLoading: false,
          isPasswordRecovery: isPasswordRecovery || state.isPasswordRecovery,
        );

        // Sync FCM device token and subscribe to network topic
        PushNotificationService.syncUserToken(userId);
        if (profile.assignedNetwork.isNotEmpty) {
          PushNotificationService.subscribeToNetwork(profile.assignedNetwork);
        }
      } else {
        final meta = authUser.userMetadata ?? {};
        final firstName = meta['first_name'] ?? authUser.email?.split('@')[0] ?? 'Miembro';
        final lastName = meta['last_name'] ?? '';
        final fallbackProfile = UserProfile(
          id: authUser.id,
          name: '$firstName $lastName'.trim(),
          firstName: firstName,
          lastName: lastName,
          dni: meta['dni'] ?? '00000000',
          email: authUser.email ?? '',
          phone: meta['phone'] ?? '',
          birthDate: meta['birth_date'] ?? '',
          isBaptized: meta['is_baptized'] ?? false,
          maritalStatus: meta['marital_status'] ?? 'Soltero/a',
          assignedNetwork: meta['assigned_network'] ?? 'dunamis',
          role: 'miembro',
          isApproved: false,
        );

        state = AuthState(
          userProfile: fallbackProfile,
          authUser: authUser,
          isLoading: false,
        );
      }
    } catch (e) {
      state = AuthState(
        authUser: authUser,
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> checkDniExists(String dni) async {
    try {
      final res = await _client.rpc('check_dni_exists', params: {'dni_to_check': dni.trim()});
      return res == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> signIn({required String dniOrEmail, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final input = dniOrEmail.trim();
      String emailToUse = input;

      if (!input.contains('@')) {
        // Look up registered email by DNI
        try {
          final res = await _client.rpc('get_email_by_dni', params: {'dni_input': input});
          if (res != null && res.toString().trim().isNotEmpty) {
            emailToUse = res.toString().trim();
          } else {
            // Direct query from profiles
            final profileRes = await _client
                .from('profiles')
                .select('email')
                .eq('dni', input)
                .maybeSingle();
            if (profileRes != null && (profileRes['email'] ?? '').toString().isNotEmpty) {
              emailToUse = profileRes['email'].toString();
            }
          }
        } catch (_) {}
      }

      final res = await _client.auth.signInWithPassword(
        email: emailToUse,
        password: password,
      );
      if (res.user != null) {
        await _fetchProfile(res.user!.id, res.user!);
        return true;
      }
      return false;
    } on AuthException catch (e) {
      String message = e.message;
      final msgLower = message.toLowerCase();
      if (msgLower.contains('email not confirmed') || msgLower.contains('email_not_confirmed')) {
        message = 'Tu correo electrónico aún no ha sido verificado. Por favor, revisa tu bandeja de entrada.';
      } else if (msgLower.contains('invalid login credentials') ||
          msgLower.contains('invalid_credentials') ||
          msgLower.contains('invalid_grant') ||
          msgLower.contains('invalid password') ||
          msgLower.contains('user not found') ||
          msgLower.contains('wrong password')) {
        message = '⚠️ DNI o contraseña incorrecta. Por favor, verifica tus datos de acceso.';
      } else {
        message = '⚠️ DNI o contraseña incorrecta. Por favor, verifica tus datos de acceso.';
      }
      state = state.copyWith(isLoading: false, errorMessage: message);
      return false;
    } catch (e) {
      final errStr = e.toString();
      String message = '⚠️ DNI o contraseña incorrecta. Por favor, verifica tus datos de acceso.';
      if (errStr.toLowerCase().contains('network') || errStr.toLowerCase().contains('socket')) {
        message = 'Error de conexión a internet. Verifica tu conexión.';
      }
      state = state.copyWith(isLoading: false, errorMessage: message);
      return false;
    }
  }

  Future<bool> signUp({
    required String firstName,
    required String lastName,
    required String dni,
    String? email,
    required String phone,
    required String birthDate,
    required bool isBaptized,
    required String maritalStatus,
    required String assignedNetwork,
    required String password,
    List<Map<String, String>> pastCourses = const [],
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final cleanDni = dni.trim();
      final exists = await checkDniExists(cleanDni);
      if (exists) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'El DNI ingresado ya está registrado con otra cuenta.',
        );
        return false;
      }

      final emailClean = (email != null && email.trim().isNotEmpty)
          ? email.trim()
          : '$cleanDni@alianzachaclacayo.pe';

      final res = await _client.auth.signUp(
        email: emailClean,
        password: password,
        data: {
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'dni': cleanDni,
          'phone': phone.trim(),
          'birth_date': birthDate.isEmpty ? '2000-01-01' : birthDate,
          'is_baptized': isBaptized,
          'marital_status': maritalStatus,
          'assigned_network': assignedNetwork == 'none' ? null : assignedNetwork,
          'custom_email': (email != null && email.trim().isNotEmpty) ? email.trim() : '',
          'past_courses': pastCourses,
        },
      );

      if (res.user != null) {
        if (pastCourses.isNotEmpty) {
          try {
            final toInsert = pastCourses.map((c) => {
              'student_id': res.user!.id,
              'subject_code': c['code'],
              'subject_title': c['title'],
              'cycle': 'Histórico',
              'approved_at': DateTime.now().toIso8601String(),
            }).toList();
            await _client.from('academy_approved_subjects').upsert(
              toInsert,
              onConflict: 'student_id,subject_code',
            );
          } catch (_) {}
        }
        state = state.copyWith(isLoading: false);
        return true;
      }
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    state = AuthState(isLoading: false);
  }
}

final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
