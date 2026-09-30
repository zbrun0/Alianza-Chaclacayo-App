import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../data/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _rememberMe = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref.read(authStateProvider.notifier).signIn(
          dniOrEmail: _identifierController.text.trim(),
          password: _passwordController.text,
        );

    if (mounted) {
      final err = ref.read(authStateProvider).errorMessage ??
          'DNI o contraseña incorrecta. Por favor, verifica tus datos de acceso.';
      setState(() {
        _isLoading = false;
        if (!success) {
          _errorMessage = err;
        }
      });
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    err,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo SVG (Diseño Oficial)
                      Center(
                        child: SvgPicture.asset(
                          'assets/images/logo.svg',
                          height: 80,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Inicia sesión para continuar',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Error message banner
                      if (_errorMessage != null || ref.watch(authStateProvider).errorMessage != null) ...[
                        Builder(
                          builder: (context) {
                            final err = _errorMessage ?? ref.watch(authStateProvider).errorMessage!;
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFCA5A5)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('⚠️ ', style: TextStyle(fontSize: 13)),
                                  Expanded(
                                    child: Text(
                                      err,
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF991B1B),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // DNI Field
                      Text(
                        'Número de DNI *',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: (_errorMessage != null || ref.watch(authStateProvider).errorMessage != null)
                              ? const Color(0xFFDC2626)
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _identifierController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) {
                          if (_errorMessage != null) setState(() => _errorMessage = null);
                        },
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Ingresa tu número de DNI',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.secondary.withValues(alpha: 0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.badge_outlined,
                            size: 20,
                            color: _errorMessage != null ? const Color(0xFFDC2626) : AppColors.secondary,
                          ),
                          filled: true,
                          fillColor: _errorMessage != null ? const Color(0xFFFEF2F2) : AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: _errorMessage != null ? const Color(0xFFDC2626) : AppColors.outlineVariant,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: _errorMessage != null ? const Color(0xFFDC2626) : AppColors.outlineVariant,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: _errorMessage != null ? const Color(0xFFDC2626) : AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Ingresa tu número de DNI';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      Text(
                        'Contraseña *',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _errorMessage != null ? const Color(0xFFDC2626) : AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) {
                          if (_errorMessage != null) setState(() => _errorMessage = null);
                        },
                        onFieldSubmitted: (_) => _handleLogin(),
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.secondary.withValues(alpha: 0.6),
                          ),
                          filled: true,
                          fillColor: _errorMessage != null ? const Color(0xFFFEF2F2) : AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            size: 20,
                            color: _errorMessage != null ? const Color(0xFFDC2626) : AppColors.secondary,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.secondary,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() => _showPassword = !_showPassword);
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: _errorMessage != null ? const Color(0xFFDC2626) : AppColors.outlineVariant,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: _errorMessage != null ? const Color(0xFFDC2626) : AppColors.outlineVariant,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: _errorMessage != null ? const Color(0xFFDC2626) : AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Ingresa tu contraseña';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Remember Me & Forgot Password Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (val) =>
                                      setState(() => _rememberMe = val ?? true),
                                  activeColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _rememberMe = !_rememberMe),
                                child: Text(
                                  'Recordarme',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: _showForgotPasswordDialog,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              '¿Olvidaste tu contraseña?',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.login, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Iniciar Sesión',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 20),

                      // Divider & Link to Register
                      const Divider(color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 12),
                      Text(
                        '¿Aún no tienes cuenta?',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                        ),
                        child: Text(
                          'Regístrate aquí como nuevo miembro →',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController(text: _identifierController.text.trim());
    final otpCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final step1FormKey = GlobalKey<FormState>();
    final step2FormKey = GlobalKey<FormState>();

    int currentStep = 1; // 1: Pedir correo, 2: Ingresar OTP + Nueva Clave, 3: Éxito
    bool loading = false;
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? dialogError;
    String? dialogSuccess;
    String sentEmail = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                currentStep == 3
                    ? Icons.check_circle
                    : (currentStep == 2 ? Icons.verified_user_outlined : Icons.lock_reset),
                color: currentStep == 3 ? const Color(0xFF16A34A) : AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  currentStep == 3
                      ? '¡Contraseña Actualizada!'
                      : (currentStep == 2 ? 'Verificación y Nueva Clave' : 'Recuperar Contraseña'),
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PASO 1: Ingresar correo
                  if (currentStep == 1) ...[
                    Text(
                      'Ingresa el correo electrónico de tu cuenta. Te enviaremos un código de seguridad de 6 dígitos para restablecer tu contraseña:',
                      style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.secondary),
                    ),
                    const SizedBox(height: 14),
                    if (dialogError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Text(
                          dialogError!,
                          style: GoogleFonts.inter(color: const Color(0xFF991B1B), fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                    Form(
                      key: step1FormKey,
                      child: TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Correo Electrónico *',
                          hintText: 'ejemplo@gmail.com',
                          prefixIcon: const Icon(Icons.email_outlined, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Ingresa tu correo electrónico';
                          if (!val.contains('@') || !val.contains('.')) return 'Ingresa un correo electrónico válido';
                          return null;
                        },
                      ),
                    ),
                  ],

                  // PASO 2: Ingresar código de 6 dígitos y nueva contraseña
                  if (currentStep == 2) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.mark_email_read_outlined, color: Color(0xFF1D4ED8), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Código enviado a:',
                                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1E40AF)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sentEmail,
                            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: loading
                                ? null
                                : () => setDialogState(() {
                                      currentStep = 1;
                                      dialogError = null;
                                    }),
                            child: Text(
                              '¿Correo incorrecto? Cambiar correo',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: const Color(0xFF2563EB),
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (dialogError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Text(
                          dialogError!,
                          style: GoogleFonts.inter(color: const Color(0xFF991B1B), fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                    Form(
                      key: step2FormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Código de Seguridad:',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondary),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: otpCtrl,
                            keyboardType: TextInputType.text,
                            textAlign: TextAlign.center,
                            maxLength: 8,
                            style: GoogleFonts.jetBrainsMono(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: 'Código recibido',
                              hintStyle: GoogleFonts.jetBrainsMono(fontSize: 18, letterSpacing: 2, color: Colors.grey.shade400),
                              prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Ingresa el código recibido en tu correo';
                              if (val.trim().length < 6 || val.trim().length > 8) return 'El código debe tener entre 6 y 8 dígitos';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Nueva Contraseña:',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondary),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: newPassCtrl,
                            obscureText: obscureNew,
                            style: GoogleFonts.inter(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Mínimo 6 caracteres',
                              prefixIcon: const Icon(Icons.lock_outline, size: 18),
                              suffixIcon: IconButton(
                                icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 18),
                                onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().length < 6) return 'La contraseña debe tener al menos 6 caracteres';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Confirmar Nueva Contraseña:',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondary),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: confirmPassCtrl,
                            obscureText: obscureConfirm,
                            style: GoogleFonts.inter(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Repite tu nueva contraseña',
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
                  ],

                  // PASO 3: Éxito
                  if (currentStep == 3) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 36),
                          const SizedBox(height: 8),
                          Text(
                            dialogSuccess ?? '¡Tu contraseña ha sido actualizada con éxito!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(color: const Color(0xFF166534), fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            if (currentStep == 1) ...[
              TextButton(
                onPressed: loading ? null : () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: loading
                    ? null
                    : () async {
                        if (!step1FormKey.currentState!.validate()) return;
                        setDialogState(() {
                          loading = true;
                          dialogError = null;
                        });

                        final emailToSend = emailCtrl.text.trim();
                        final client = ref.read(supabaseClientProvider);

                        try {
                          await client.auth.resetPasswordForEmail(emailToSend);

                          setDialogState(() {
                            loading = false;
                            sentEmail = emailToSend;
                            currentStep = 2;
                            dialogError = null;
                          });
                        } catch (e) {
                          setDialogState(() {
                            loading = false;
                            dialogError = 'Error al enviar código: $e';
                          });
                        }
                      },
                child: loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Enviar Código', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ] else if (currentStep == 2) ...[
              TextButton(
                onPressed: loading
                    ? null
                    : () => setDialogState(() {
                          currentStep = 1;
                          dialogError = null;
                        }),
                child: const Text('Volver'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: loading
                    ? null
                    : () async {
                        if (!step2FormKey.currentState!.validate()) return;
                        final authNotifier = ref.read(authStateProvider.notifier);
                        setDialogState(() {
                          loading = true;
                          dialogError = null;
                        });

                        final code = otpCtrl.text.trim();
                        final newPass = newPassCtrl.text.trim();

                        try {
                          await authNotifier.resetPasswordWithOtp(
                            email: sentEmail,
                            token: code,
                            newPassword: newPass,
                          );

                          // Autocompletar el correo en el formulario principal
                          _identifierController.text = sentEmail;
                          _passwordController.clear();

                          setDialogState(() {
                            loading = false;
                            currentStep = 3;
                            dialogSuccess = '¡Contraseña restablecida con éxito! Ya puedes iniciar sesión con tu nueva contraseña.';
                          });
                        } catch (e) {
                          setDialogState(() {
                            loading = false;
                            final msg = e.toString().toLowerCase();
                            if (msg.contains('token') || msg.contains('otp') || msg.contains('expired') || msg.contains('invalid')) {
                              dialogError = 'El código ingresado es incorrecto o ha expirado. Por favor verifica tu correo o solicita uno nuevo.';
                            } else {
                              dialogError = 'Error al actualizar contraseña: $e';
                            }
                          });
                        }
                      },
                child: loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Restablecer Contraseña', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ] else if (currentStep == 3) ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Iniciar Sesión', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
