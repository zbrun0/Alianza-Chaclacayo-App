import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/resend_email_service.dart';
import '../../auth/data/auth_provider.dart';

class DiezmosScreen extends ConsumerStatefulWidget {
  const DiezmosScreen({super.key});

  @override
  ConsumerState<DiezmosScreen> createState() => _DiezmosScreenState();
}

class _DiezmosScreenState extends ConsumerState<DiezmosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _picker = ImagePicker();
  XFile? _selectedImage;

  final _dniController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _operationDateController = TextEditingController();
  final _notesController = TextEditingController();

  final List<String> _months = const [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  late String _selectedMonth;
  late String _selectedYear;

  // Ordered logically without icons
  final List<Map<String, String>> _contributionTypes = const [
    {'id': 'diezmo', 'label': 'Diezmo'},
    {'id': 'misionera', 'label': 'Ofrenda Misionera'},
    {'id': 'protemplo', 'label': 'Ofrenda Pro-Templo'},
    {'id': 'amor', 'label': 'Ofrenda de Amor'},
    {'id': 'otro', 'label': 'Otro aporte especial'},
  ];

  final Set<String> _selectedFunds = {'diezmo'};

  bool _isSubmitting = false;
  List<Map<String, dynamic>> _myRecords = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = _months[now.month - 1];
    _selectedYear = now.year.toString();
    _operationDateController.text = DateFormat('yyyy-MM-dd').format(now);

    _tabController = TabController(length: 3, vsync: this);
    _initUserData();
    _fetchHistory();
  }

  void _initUserData() {
    final user = ref.read(authStateProvider).userProfile;
    if (user != null) {
      _dniController.text = user.dni;
      _fullNameController.text = user.name;
      _phoneController.text = user.phone;
    }
  }

  @override
  void dispose() {
    _dniController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _operationDateController.dispose();
    _notesController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    final user = ref.read(authStateProvider).userProfile;
    if (user == null) {
      if (mounted) setState(() => _loadingHistory = false);
      return;
    }

    try {
      final res = await Supabase.instance.client
          .from('tithing_receipts')
          .select('id, created_at, funds, period_month, file_urls, status, notes')
          .or('user_id.eq.${user.id},dni.eq.${user.dni}')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _myRecords = List<Map<String, dynamic>>.from(res);
          _loadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡$label copiado al portapapeles!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(source: source, imageQuality: 80);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedFunds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona al menos un tipo de aporte')),
      );
      return;
    }

    final amountStr = _amountController.text.trim();
    if (amountStr.isEmpty || (double.tryParse(amountStr) ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un monto válido')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final user = ref.read(authStateProvider).userProfile;
    final client = Supabase.instance.client;

    try {
      final List<String> fileUrls = [];

      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        final ext = _selectedImage!.name.split('.').last;
        final fileName = '${user?.id ?? "anon"}/${DateTime.now().millisecondsSinceEpoch}.$ext';

        await client.storage.from('tithing-receipts').uploadBinary(fileName, bytes);
        final publicUrl = client.storage.from('tithing-receipts').getPublicUrl(fileName);
        fileUrls.add(publicUrl);
      }

      final double amount = double.tryParse(amountStr) ?? 0;
      final notesFormatted = '[Monto: S/. ${amount.toStringAsFixed(2)} | Fecha: ${_operationDateController.text}] ${_notesController.text.trim()}'.trim();

      await client.from('tithing_receipts').insert({
        'user_id': user?.id,
        'dni': _dniController.text.trim().isNotEmpty ? _dniController.text.trim() : (user?.dni ?? '00000000'),
        'full_name': _fullNameController.text.trim().isNotEmpty ? _fullNameController.text.trim() : (user?.name ?? 'Miembro Congregacional'),
        'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : (user?.phone ?? ''),
        'funds': _selectedFunds.toList(),
        'period_month': '$_selectedMonth $_selectedYear',
        'file_urls': fileUrls,
        'status': 'pendiente',
        'notes': notesFormatted,
      });

      if (user != null && user.email.isNotEmpty) {
        final fundLabels = _selectedFunds
            .map((f) => _contributionTypes.firstWhere((t) => t['id'] == f, orElse: () => {'label': f})['label'] ?? f)
            .join(', ');

        ResendEmailService.sendTithingConfirmation(
          to: user.email,
          memberName: user.name,
          amount: amount.toStringAsFixed(2),
          type: fundLabels,
          bank: 'Transferencia Bancaria / Depósito',
        );
      }

      if (mounted) {
        setState(() {
          _selectedImage = null;
          _amountController.clear();
          _notesController.clear();
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Comprobante enviado con éxito! Se envió una constancia a tu correo.'),
            backgroundColor: AppColors.success,
          ),
        );
        _fetchHistory();
        _tabController.animateTo(2);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Header
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.secondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: const [
              Tab(text: 'Registrar Aporte'),
              Tab(text: 'Cuentas Bancarias'),
              Tab(text: 'Mi Historial'),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFormTab(),
              _buildAccountsTab(),
              _buildHistoryTab(),
            ],
          ),
        ),
      ],
    );
  }

  // TAB 1: FORMULARIO DE REGISTRO
  Widget _buildFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Confidencialidad
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.secondaryContainer),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tus aportes son tratados con absoluta reserva y confidencialidad por el equipo pastoral y tesorería.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.primary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Selección de Fondos / Tipos de Aporte (Ordenado y sin iconos)
          Text(
            'TIPO DE APORTE (SELECCIONA UNO O VARIOS)',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _contributionTypes.map((type) {
              final id = type['id']!;
              final label = type['label']!;
              final isSelected = _selectedFunds.contains(id);

              return FilterChip(
                selected: isSelected,
                showCheckmark: false,
                label: Text(label),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                labelStyle: GoogleFonts.inter(
                  color: isSelected ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedFunds.add(id);
                    } else if (_selectedFunds.length > 1) {
                      _selectedFunds.remove(id);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // Período (Mes y Año)
          Text(
            'PERÍODO CORRESPONDIENTE',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedMonth,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurface),
                  decoration: _inputDecoration('Mes'),
                  items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setState(() => _selectedMonth = v ?? _selectedMonth),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: TextFormField(
                  initialValue: _selectedYear,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(fontSize: 12),
                  decoration: _inputDecoration('Año'),
                  onChanged: (v) => _selectedYear = v,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Monto & Fecha Operación
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MONTO (S/.) *',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                      decoration: _inputDecoration('0.00').copyWith(prefixText: 'S/. '),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FECHA OPERACIÓN *',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _operationDateController,
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _operationDateController.text = DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      },
                      style: GoogleFonts.inter(fontSize: 12),
                      decoration: _inputDecoration('AAAA-MM-DD').copyWith(
                        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Subir Comprobante
          Text(
            'ADJUNTAR COMPROBANTE O CAPTURA',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined, size: 16),
                  label: const Text('Tomar Foto', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 16),
                  label: const Text('Galería', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),

          if (_selectedImage != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF15803D), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedImage!.name,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF14532D),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Color(0xFF15803D)),
                    onPressed: () => setState(() => _selectedImage = null),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Número de Operación / Nota
          Text(
            'NÚMERO DE OPERACIÓN / OBSERVACIONES (OPCIONAL)',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _notesController,
            style: GoogleFonts.inter(fontSize: 12),
            decoration: _inputDecoration('Ej. Operación #892341 - Banco BCP'),
          ),
          const SizedBox(height: 24),

          // Botón Enviar
          ElevatedButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Enviar Comprobante a Tesorería',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // TAB 2: CUENTAS BANCARIAS OFICIALES (Sin desbordamientos visuales)
  Widget _buildAccountsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CUENTAS BANCARIAS OFICIALES',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 12),

          // Tarjeta BCP (Diseño responsivo y limpio)
          _buildBankCard(
            title: 'BCP',
            subtitle: 'Banco de Crédito del Perú',
            accountNumber: '191 2215578 074',
            cci: '002 191 002215578074 59',
            titular: 'Iglesia Alianza Cristiana y Misionera Chaclacayo',
            badge: 'Diezmos y Ofrendas',
            note: 'Vía recomendada para Diezmos, Ofrendas Misioneras y Pro-Templo.',
            icon: Icons.account_balance,
          ),
          const SizedBox(height: 14),

          // Tarjeta Yape
          _buildBankCard(
            title: 'Yape',
            subtitle: 'Billetera Digital Oficial',
            accountNumber: '989 010 169',
            cci: '',
            titular: 'Alianza Chaclacayo',
            badge: 'Solo Ofrendas',
            note: '⚠️ Exclusivo para Ofrendas (no registrar diezmos por Yape).',
            icon: Icons.phone_android,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBankCard({
    required String title,
    required String subtitle,
    required String accountNumber,
    required String cci,
    required String titular,
    required String badge,
    required String note,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Número de Cuenta
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'N° de Cuenta / Celular:',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary),
                    ),
                    const SizedBox(height: 2),
                    SelectableText(
                      accountNumber,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18, color: AppColors.primary),
                onPressed: () => _copyToClipboard(accountNumber, 'Número'),
                tooltip: 'Copiar',
              ),
            ],
          ),

          if (cci.isNotEmpty) ...[
            const Divider(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Código Interbancario (CCI):',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary),
                      ),
                      const SizedBox(height: 2),
                      SelectableText(
                        cci,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18, color: AppColors.primary),
                  onPressed: () => _copyToClipboard(cci, 'CCI'),
                  tooltip: 'Copiar',
                ),
              ],
            ),
          ],

          const Divider(height: 14),
          Text(
            'Titular: $titular',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary),
          ),
          const SizedBox(height: 6),
          Text(
            note,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // TAB 3: MI HISTORIAL DE APORTES
  Widget _buildHistoryTab() {
    if (_loadingHistory) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_myRecords.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long_outlined, size: 52, color: AppColors.secondary),
              const SizedBox(height: 14),
              Text(
                'Aún no has registrado comprobantes',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tus aportes enviados a Tesorería aparecerán aquí con su estado de validación.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _myRecords.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final rec = _myRecords[index];
        final funds = (rec['funds'] as List<dynamic>?)?.map((e) => e.toString().toUpperCase()).join(', ') ?? 'DIEZMO';
        final period = rec['period_month'] ?? '';
        final status = (rec['status'] ?? 'pendiente').toString().toLowerCase();
        final notes = rec['notes'] ?? '';

        final isVerified = status == 'verificado';
        final isRejected = status == 'rechazado';

        Color statusBg = const Color(0xFFFEF3C7);
        Color statusFg = const Color(0xFFB45309);
        String statusLabel = 'En Revisión';

        if (isVerified) {
          statusBg = const Color(0xFFD1FAE5);
          statusFg = const Color(0xFF047857);
          statusLabel = 'Verificado';
        } else if (isRejected) {
          statusBg = const Color(0xFFFEE2E2);
          statusFg = const Color(0xFFB91C1C);
          statusLabel = 'Observado';
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    funds,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusFg,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                period,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  notes,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary.withValues(alpha: 0.6)),
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
}
