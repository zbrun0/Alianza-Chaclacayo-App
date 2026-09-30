import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/resend_email_service.dart';
import '../data/auth_provider.dart';
import '../../academia/presentation/academia_screen.dart' show abcCurriculum;

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
  bool _isBaptized = false;
  final Set<String> _selectedPastCourseCodes = {};
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

    final pastCoursesToSend = _isBaptized
        ? abcCurriculum
            .where((c) => _selectedPastCourseCodes.contains(c.code))
            .map((c) => {'code': c.code, 'title': c.title, 'level': c.level})
            .toList()
        : <Map<String, String>>[];

    final success = await ref.read(authStateProvider.notifier).signUp(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          dni: _dniController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          birthDate: _birthDateController.text.trim(),
          isBaptized: _isBaptized,
          maritalStatus: _maritalStatus,
          assignedNetwork: _assignedNetwork!,
          password: _passwordController.text,
          pastCourses: pastCoursesToSend,
        );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) {
          _success = true;
          final userEmail = _emailController.text.trim();
          if (userEmail.isNotEmpty && userEmail.contains('@')) {
            ResendEmailService.sendWelcomeEmail(
              to: userEmail,
              name: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim(),
              dni: _dniController.text.trim(),
              network: _networks.firstWhere(
                (n) => n['value'] == _assignedNetwork,
                orElse: () => {'label': 'General'},
              )['label']!,
            );
          }
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
    final hasEmail = _emailController.text.trim().isNotEmpty;
    final dni = _dniController.text.trim();

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
                Icons.check_circle_outline_rounded,
                size: 48,
                color: Color(0xFF15803D),
              ),
              const SizedBox(height: 12),
              Text(
                '¡Registro Completado con Éxito!',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF14532D),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                hasEmail
                    ? 'Tu cuenta ha sido creada. Puedes iniciar sesión directamente con tu DNI:'
                    : 'Tu cuenta ha sido creada exitosamente. Inicia sesión con tu DNI:',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF166534),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Text(
                  'DNI: $dni',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF14532D),
                  ),
                ),
              ),
              if (hasEmail) ...[
                const SizedBox(height: 10),
                Text(
                  'Correo asociado: ${_emailController.text.trim()}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF15803D),
                  ),
                ),
              ],
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
            'Ir a Iniciar Sesión',
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

          // Email (Opcional)
          _buildFieldLabel('Correo Electrónico (Opcional)'),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.inter(fontSize: 12),
            decoration: _inputDecoration('tu.correo@ejemplo.com (Opcional)'),
            validator: (val) {
              if (val != null && val.trim().isNotEmpty) {
                if (!val.contains('@') || !val.contains('.')) {
                  return 'Ingresa un correo electrónico válido';
                }
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
          const SizedBox(height: 14),

          // Bautismo e Historial de Cursos
          _buildBaptismAndCoursesSection(),
          const SizedBox(height: 14),

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
              'Iniciar Sesión con mi DNI →',
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

  Widget _buildBaptismAndCoursesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('¿Estás bautizado/a en agua? *'),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isBaptized = false;
                    _selectedPastCourseCodes.clear();
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !_isBaptized ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: !_isBaptized ? AppColors.primary : AppColors.outlineVariant,
                      width: !_isBaptized ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        !_isBaptized ? Icons.radio_button_checked : Icons.radio_button_off,
                        size: 16,
                        color: !_isBaptized ? Colors.white : AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'No',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: !_isBaptized ? Colors.white : AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isBaptized = true;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _isBaptized ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isBaptized ? AppColors.primary : AppColors.outlineVariant,
                      width: _isBaptized ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isBaptized ? Icons.radio_button_checked : Icons.radio_button_off,
                        size: 16,
                        color: _isBaptized ? Colors.white : AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sí',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _isBaptized ? Colors.white : AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Si NO está bautizado: Mensaje informativo sobre Vida Abundante
        if (!_isBaptized) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF1D4ED8), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Al no estar bautizado/a, no requieres ingresar cursos previos. Tu inicio formativo en la Academia ABC será con el curso Vida Abundante (Mi nueva Alianza con Dios).',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF1E40AF),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Si SÍ está bautizado: Formulario para ingresar historial de cursos
          _buildPastCoursesForm(),
        ],
      ],
    );
  }

  Widget _buildPastCoursesForm() {
    final levels = [
      {'key': 'inicial', 'name': 'Nivel Inicial', 'desc': 'Fundamentos de la fe cristiana'},
      {'key': 'basico', 'name': 'Nivel Básico', 'desc': 'Evangelismo, dones y discipulado'},
      {'key': 'intermedio', 'name': 'Nivel Intermedio', 'desc': 'Estudio bíblico y libros doctrinales'},
      {'key': 'avanzado', 'name': 'Nivel Avanzado', 'desc': 'Teología ETE y libros bíblicos'},
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Historial de Cursos Llevados',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (_selectedPastCourseCodes.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Text(
                    '${_selectedPastCourseCodes.length} marcados',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF166534),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Marca los cursos que ya has llevado y aprobado anteriormente en la iglesia. Si aún no has llevado ninguno, puedes dejarlo vacío.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.secondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),

          // Lista de grupos por nivel
          for (final lvl in levels) ...[
            _buildLevelCourseGroup(
              levelKey: lvl['key']!,
              levelName: lvl['name']!,
              levelDesc: lvl['desc']!,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelCourseGroup({
    required String levelKey,
    required String levelName,
    required String levelDesc,
  }) {
    final coursesInLevel = abcCurriculum.where((c) => c.level == levelKey).toList();
    final allSelectedInLevel = coursesInLevel.isNotEmpty &&
        coursesInLevel.every((c) => _selectedPastCourseCodes.contains(c.code));
    final someSelectedInLevel = coursesInLevel.any((c) => _selectedPastCourseCodes.contains(c.code));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: someSelectedInLevel ? AppColors.primary.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: levelKey == 'inicial',
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      levelName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: someSelectedInLevel ? AppColors.primary : AppColors.onSurface,
                      ),
                    ),
                    Text(
                      levelDesc,
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.secondary),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    if (allSelectedInLevel) {
                      for (final c in coursesInLevel) {
                        _selectedPastCourseCodes.remove(c.code);
                      }
                    } else {
                      for (final c in coursesInLevel) {
                        _selectedPastCourseCodes.add(c.code);
                      }
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: allSelectedInLevel ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: allSelectedInLevel ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Text(
                    allSelectedInLevel ? 'Todo el nivel ✓' : 'Marcar nivel',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: allSelectedInLevel ? const Color(0xFF166534) : AppColors.secondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          children: [
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 6),
            ...coursesInLevel.map((course) {
              final isChecked = _selectedPastCourseCodes.contains(course.code);
              final isVidaAbundante = course.code == 'A01';
              final displayName = isVidaAbundante
                  ? '${course.code}: ${course.title} (Vida Abundante)'
                  : '${course.code}: ${course.title}';

              return InkWell(
                onTap: () {
                  setState(() {
                    if (isChecked) {
                      _selectedPastCourseCodes.remove(course.code);
                    } else {
                      _selectedPastCourseCodes.add(course.code);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: isChecked,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedPastCourseCodes.add(course.code);
                              } else {
                                _selectedPastCourseCodes.remove(course.code);
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          displayName,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                            color: isChecked ? AppColors.primary : AppColors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
