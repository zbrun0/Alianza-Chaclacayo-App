import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../data/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dniController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _passwordController = TextEditingController();

  String _maritalStatus = 'Soltero/a';
  String? _assignedNetwork;
  bool _showPassword = false;
  bool _isLoading = false;
  bool _success = false;
  String? _errorMessage;

  final List<Map<String, String>> _networks = const [
    {'value': 'none', 'label': 'No tengo red'},
    {'value': 'kids', 'label': 'GENERACIÓN KIDS (1-12)'},
    {'value': 'free', 'label': 'FREE (13-17)'},
    {'value': 'legado', 'label': 'LEGADO (18-27)'},
    {'value': 'dunamis', 'label': 'DUNAMIS (28-45)'},
    {'value': 'mujeres', 'label': 'MUJERES DE FE'},
    {'value': 'varones', 'label': 'VARONES VALIENTES'},
    {'value': 'matrimonios', 'label': 'MATRIMONIOS UNIDOS'},
    {'value': 'maravillosos', 'label': 'AÑOS MARAVILLOSOS'},
  ];

  final List<String> _maritalOptions = const [
    'Soltero/a',
    'Casado/a',
    'Divorciado/a',
    'Viudo/a',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dniController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_assignedNetwork == null) {
      setState(() {
        _errorMessage = 'Por favor seleccione la red a la que pertenece.';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref.read(authStateProvider.notifier).signUp(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          dni: _dniController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          birthDate: _birthDateController.text.trim(),
          maritalStatus: _maritalStatus,
          assignedNetwork: _assignedNetwork!,
          password: _passwordController.text,
        );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) {
          _success = true;
        } else {
          _errorMessage = ref.read(authStateProvider).errorMessage ??
              'Error al registrar la cuenta.';
        }
      });
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 12,
        color: AppColors.secondary.withValues(alpha: 0.6),
      ),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: _success ? _buildSuccessCard() : _buildForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.mark_email_read_outlined,
                size: 48,
                color: Color(0xFF15803D),
              ),
              const SizedBox(height: 12),
              Text(
                '¡Registro Completado con Éxito!',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF14532D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hemos enviado un enlace de confirmación a tu correo electrónico:\n',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF166534),
                ),
              ),
              Text(
                _emailController.text.trim(),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF14532D),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Por favor, verifica tu bandeja de entrada y confirma tu cuenta antes de iniciar sesión.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF15803D),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF15803D),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Volver al Iniciar Sesión',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Icon
          Center(
            child: Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person_add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Registro de Miembro',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Text(
            'Iglesia Alianza Cristiana y Misionera de Chaclacayo',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 18),

          // Error Banner
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Text('⚠️ ', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF991B1B),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // First Name & Last Name
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Nombres *'),
                    TextFormField(
                      controller: _firstNameController,
                      style: GoogleFonts.inter(fontSize: 12),
                      decoration: _inputDecoration('Ej. Juan Marcos'),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Requerido' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Apellidos *'),
                    TextFormField(
                      controller: _lastNameController,
                      style: GoogleFonts.inter(fontSize: 12),
                      decoration: _inputDecoration('Ej. Pérez Gómez'),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Requerido' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // DNI & Phone
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('DNI *'),
                    TextFormField(
                      controller: _dniController,
                      keyboardType: TextInputType.number,
                      maxLength: 12,
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                      style: GoogleFonts.inter(fontSize: 12),
                      decoration: _inputDecoration('Ej. 45892103'),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Requerido';
                        if (val.trim().length < 8) return 'Mín 8 dígitos';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Teléfono / WhatsApp *'),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.inter(fontSize: 12),
                      decoration: _inputDecoration('Ej. 987654321'),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Requerido' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Email
          _buildFieldLabel('Correo Electrónico *'),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.inter(fontSize: 12),
            decoration: _inputDecoration('tu.correo@ejemplo.com'),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Requerido';
              if (!val.contains('@') || !val.contains('.')) {
                return 'Correo inválido';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Birth Date & Marital Status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Fecha Nacimiento *'),
                    InkWell(
                      onTap: _selectBirthDate,
                      child: IgnorePointer(
                        child: TextFormField(
                          controller: _birthDateController,
                          style: GoogleFonts.inter(fontSize: 12),
                          decoration: _inputDecoration('AAAA-MM-DD').copyWith(
                            suffixIcon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: AppColors.secondary,
                            ),
                          ),
                          validator: (val) =>
                              val == null || val.trim().isEmpty ? 'Requerido' : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Estado Civil *'),
                    DropdownButtonFormField<String>(
                      initialValue: _maritalStatus,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onSurface,
                      ),
                      decoration: _inputDecoration(''),
                      items: _maritalOptions.map((opt) {
                        return DropdownMenuItem(value: opt, child: Text(opt));
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _maritalStatus = val ?? 'Soltero/a'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Network Selection & Password
          _buildFieldLabel('Red a la que perteneces *'),
          DropdownButtonFormField<String>(
            initialValue: _assignedNetwork,
            hint: Text(
              'Seleccione su red...',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.secondary.withValues(alpha: 0.6),
              ),
            ),
            isExpanded: true,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.onSurface,
            ),
            decoration: _inputDecoration(''),
            items: _networks.map((net) {
              return DropdownMenuItem(
                value: net['value'],
                child: Text(net['label']!, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) => setState(() => _assignedNetwork = val),
            validator: (val) =>
                val == null ? 'Por favor seleccione una red' : null,
          ),
          const SizedBox(height: 12),

          // Password
          _buildFieldLabel('Contraseña *'),
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            style: GoogleFonts.inter(fontSize: 12),
            decoration: _inputDecoration('Mínimo 6 caracteres').copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: AppColors.secondary,
                ),
                onPressed: () =>
                    setState(() => _showPassword = !_showPassword),
              ),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Requerido';
              if (val.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Submit Button
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.how_to_reg, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Registrarse',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),

          // Divider & Login link
          const Divider(color: Color(0xFFE5E7EB)),
          const SizedBox(height: 8),
          Text(
            '¿Ya tienes una cuenta registrada?',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.secondary,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 2),
            ),
            child: Text(
              'Iniciar Sesión con mi correo →',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
