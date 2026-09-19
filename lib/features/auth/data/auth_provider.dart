import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_model.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

class AuthState {
  final UserProfile? userProfile;
  final User? authUser;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.userProfile,
    this.authUser,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => authUser != null;

  AuthState copyWith({
    UserProfile? userProfile,
    User? authUser,
    bool? isLoading,
    String? errorMessage,
    bool clearProfile = false,
  }) {
    return AuthState(
      userProfile: clearProfile ? null : (userProfile ?? this.userProfile),
      authUser: clearProfile ? null : (authUser ?? this.authUser),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  SupabaseClient get _client => ref.read(supabaseClientProvider);

  @override
  AuthState build() {
    Future.microtask(() => _init());
    return AuthState(isLoading: true);
  }

  void _init() {
    final currentSession = _client.auth.currentSession;
    if (currentSession != null) {
      _fetchProfile(currentSession.user.id, currentSession.user);
    } else {
      state = AuthState(isLoading: false);
    }

    _client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _fetchProfile(session.user.id, session.user);
      } else {
        state = AuthState(isLoading: false);
      }
    });
  }

  Future<void> _fetchProfile(String userId, User authUser) async {
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
        );
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
      final res = await _client.rpc('check_dni_exists', params: {'dni_to_check': dni});
      return res == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
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
        message = 'Tu correo electrónico aún no ha sido verificado. Por favor, revisa tu bandeja de entrada para confirmar tu cuenta.';
      } else if (msgLower.contains('invalid login credentials') ||
          msgLower.contains('invalid_credentials') ||
          msgLower.contains('invalid_grant') ||
          msgLower.contains('invalid password') ||
          msgLower.contains('wrong password')) {
        message = '⚠️ Contraseña incorrecta o correo no válido. Por favor, verifica tus datos de acceso.';
      } else {
        message = 'Error al iniciar sesión: $message';
      }
      state = state.copyWith(isLoading: false, errorMessage: message);
      return false;
    } catch (e) {
      final errStr = e.toString();
      String message = 'Contraseña incorrecta o datos inválidos.';
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
    required String email,
    required String phone,
    required String birthDate,
    required String maritalStatus,
    required String assignedNetwork,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final exists = await checkDniExists(dni);
      if (exists) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'El DNI ingresado ya está registrado con otra cuenta.',
        );
        return false;
      }

      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'dni': dni,
          'phone': phone,
          'birth_date': birthDate.isEmpty ? '2000-01-01' : birthDate,
          'is_baptized': false,
          'marital_status': maritalStatus,
          'assigned_network': assignedNetwork == 'none' ? null : assignedNetwork,
        },
      );

      if (res.user != null) {
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
