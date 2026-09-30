import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_provider.dart';
import '../../auth/presentation/login_screen.dart';

class FamilyMemberChild {
  final String id;
  final String name;
  final String birthDate;
  final String network;
  final int age;

  FamilyMemberChild({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.network,
    required this.age,
  });
}

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  bool _loadingChildren = true;
  List<FamilyMemberChild> _children = [];
  bool? _hasChildren;
  bool _savingChild = false;

  // Cónyuge
  String? _spouseName;
  String? _spouseDni;

  @override
  void initState() {
    super.initState();
    _fetchFamilyMembers();
  }

  String _getNetworkByAge(int age) {
    if (age <= 12) return 'kids';
    if (age >= 13 && age <= 17) return 'free';
    if (age >= 18 && age <= 27) return 'legado';
    return 'dunamis';
  }

  String _getNetworkDisplayName(String networkKey) {
    switch (networkKey) {
      case 'kids':
        return 'Generación Kids (1-12)';
      case 'free':
        return 'Free (13-17)';
      case 'legado':
        return 'Legado (18-27)';
      case 'dunamis':
        return 'Dunamis (28+)';
      default:
        return AppConstants.networkNames[networkKey] ?? networkKey;
    }
  }

  Future<void> _fetchFamilyMembers() async {
    final user = ref.read(authStateProvider).userProfile;
    if (user == null) {
      if (mounted) setState(() => _loadingChildren = false);
      return;
    }

    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('family_members')
          .select('*')
          .eq('parent_id', user.id)
          .order('created_at', ascending: true);

      final currentYear = DateTime.now().year;
      final list = (res as List<dynamic>).map((item) {
        final bDateStr = item['child_birth_date']?.toString() ?? '';
        int age = 0;
        if (bDateStr.isNotEmpty) {
          final dt = DateTime.tryParse(bDateStr);
          if (dt != null) {
            age = currentYear - dt.year;
          }
        }
        final netKey = item['network_assigned']?.toString() ?? _getNetworkByAge(age);
        return FamilyMemberChild(
          id: item['id'].toString(),
          name: item['child_name']?.toString() ?? 'Hijo/a',
          birthDate: bDateStr,
          network: _getNetworkDisplayName(netKey),
          age: age,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _children = list;
          _hasChildren = list.isNotEmpty ? true : false;
          _loadingChildren = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingChildren = false);
      }
    }
  }

  Future<void> _addChild(String name, DateTime birthDate) async {
    final user = ref.read(authStateProvider).userProfile;
    if (user == null) return;

    setState(() => _savingChild = true);
    try {
      final client = Supabase.instance.client;
      final bDateStr = DateFormat('yyyy-MM-dd').format(birthDate);
      final age = DateTime.now().year - birthDate.year;
      final netKey = _getNetworkByAge(age);

      final inserted = await client.from('family_members').insert({
        'parent_id': user.id,
        'child_name': name,
        'child_birth_date': bDateStr,
        'network_assigned': netKey,
      }).select().single();

      final newChild = FamilyMemberChild(
        id: inserted['id'].toString(),
        name: inserted['child_name']?.toString() ?? name,
        birthDate: bDateStr,
        network: _getNetworkDisplayName(netKey),
        age: age,
      );

      if (mounted) {
        setState(() {
          _children.add(newChild);
          _hasChildren = true;
          _savingChild = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hijo/a registrado y asignado a ${_getNetworkDisplayName(netKey)}'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _savingChild = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar hijo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteChild(FamilyMemberChild child) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: Text('¿Deseas retirar a ${child.name} de tus cargas familiares?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client
          .from('family_members')
          .delete()
          .eq('id', child.id);

      if (mounted) {
        setState(() {
          _children.removeWhere((c) => c.id == child.id);
          if (_children.isEmpty) {
            _hasChildren = false;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hijo/a retirado correctamente.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showAddChildDialog() {
    final nameCtrl = TextEditingController();
    DateTime? selectedDate;
    String calculatedNetwork = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Registrar Hijo/a',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Nombre Completo *',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
                        firstDate: DateTime(1990),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        final age = DateTime.now().year - picked.year;
                        setModalState(() {
                          selectedDate = picked;
                          calculatedNetwork = _getNetworkDisplayName(_getNetworkByAge(age));
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cake_outlined, color: AppColors.secondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedDate != null
                                  ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                                  : 'Fecha de Nacimiento *',
                              style: TextStyle(
                                color: selectedDate != null ? Colors.black87 : Colors.grey.shade600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: AppColors.secondary),
                        ],
                      ),
                    ),
                  ),
                  if (calculatedNetwork.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.groups_outlined, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Red asignada automáticamente: $calculatedNetwork',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _savingChild
                        ? null
                        : () {
                            if (nameCtrl.text.trim().isEmpty || selectedDate == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Por favor completa todos los campos')),
                              );
                              return;
                            }
                            Navigator.pop(ctx);
                            _addChild(nameCtrl.text.trim(), selectedDate!);
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _savingChild
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Guardar Hijo/a', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSpouseDialog() {
    final nameCtrl = TextEditingController(text: _spouseName ?? '');
    final dniCtrl = TextEditingController(text: _spouseDni ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vincular Cónyuge'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo del Cónyuge',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dniCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'DNI del Cónyuge',
                prefixIcon: Icon(Icons.badge),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _spouseName = nameCtrl.text.trim();
                  _spouseDni = dniCtrl.text.trim();
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cónyuge vinculado correctamente.')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.userProfile;

    if (!authState.isAuthenticated || user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Inicia Sesión en Alianza Chaclacayo',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Accede a tu carnet digital, historial de notas de la academia y registro de diezmos.',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.secondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 48),
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Iniciar Sesión'),
              ),
            ],
          ),
        ),
      );
    }

    final networkTitle = AppConstants.networkNames[user.assignedNetwork] ?? user.assignedNetwork;
    final isMarried = user.maritalStatus.toLowerCase().contains('casad');

    return RefreshIndicator(
      onRefresh: _fetchFamilyMembers,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carnet Digital de Membresía (Diseño estilizado con QR)
            _buildMembershipCard(user, networkTitle),

            const SizedBox(height: 24),

            // Información Personal
            Text(
              'DATOS DEL MIEMBRO',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildInfoRow('DNI', user.dni),
                  const Divider(height: 16),
                  _buildEmailRow(user.email),
                  const Divider(height: 16),
                  _buildPhoneRow(user.phone),
                  const Divider(height: 16),
                  _buildInfoRow('Estado Civil', user.maritalStatus),
                  const Divider(height: 16),
                  _buildInfoRow('Bautismo', user.isBaptized ? 'Sí (Bautizado)' : 'Pendiente'),
                  const Divider(height: 16),
                  _buildInfoRow('Roles Asignados', user.roleTranslated),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Sección Estado Familiar: Cónyuge si es Casado
            if (isMarried) ...[
              Text(
                'CÓNYUGE',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: _spouseName != null
                    ? Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFFF3E8FF),
                            child: Icon(Icons.favorite, color: Color(0xFF9333EA), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _spouseName!,
                                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold),
                                ),
                                if (_spouseDni != null && _spouseDni!.isNotEmpty)
                                  Text(
                                    'DNI: $_spouseDni',
                                    style: const TextStyle(fontSize: 11, color: AppColors.secondary),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: _showSpouseDialog,
                          ),
                        ],
                      )
                    : OutlinedButton.icon(
                        onPressed: _showSpouseDialog,
                        icon: const Icon(Icons.person_add_alt, size: 16),
                        label: const Text('Vincular Cónyuge'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                        ),
                      ),
              ),
              const SizedBox(height: 24),
            ],

            // Sección Cargas Familiares / Hijos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CARGAS FAMILIARES / HIJOS',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Asignación automática a Generación Kids / Free',
                      style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.secondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Botones Sí / No
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() => _hasChildren = true);
                          },
                          icon: Icon(
                            _hasChildren == true ? Icons.check_circle : Icons.radio_button_unchecked,
                            size: 16,
                            color: _hasChildren == true ? AppColors.primary : AppColors.secondary,
                          ),
                          label: const Text('Sí tengo'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _hasChildren == true
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : Colors.transparent,
                            side: BorderSide(
                              color: _hasChildren == true ? AppColors.primary : const Color(0xFFCBD5E1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (_children.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Debes eliminar los hijos registrados primero para marcar que no tienes.'),
                                ),
                              );
                            } else {
                              setState(() => _hasChildren = false);
                            }
                          },
                          icon: Icon(
                            _hasChildren == false ? Icons.cancel : Icons.radio_button_unchecked,
                            size: 16,
                            color: _hasChildren == false ? AppColors.primary : AppColors.secondary,
                          ),
                          label: const Text('No tengo'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _hasChildren == false
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : Colors.transparent,
                            side: BorderSide(
                              color: _hasChildren == false ? AppColors.primary : const Color(0xFFCBD5E1),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_hasChildren == true) ...[
                    const SizedBox(height: 16),
                    if (_loadingChildren)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (_children.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Aún no has agregado a ningún hijo/a.',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontStyle: FontStyle.italic,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _children.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final child = _children[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.child_care, color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        child.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${child.age} años • F. Nac: ${child.birthDate}',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0F2FE),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          child.network,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0369A1),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                  onPressed: () => _deleteChild(child),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: _showAddChildDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Agregar Hijo/a'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Acceso a Panel Pastoral si tiene roles
            if (user.hasAdminAccess) ...[
              ElevatedButton.icon(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.admin_panel_settings, size: 18),
                label: const Text('Abrir Panel Backoffice Pastoral'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: AppColors.primaryContainer,
                ),
              ),
              const SizedBox(height: 12),
            ],

            ElevatedButton.icon(
              onPressed: () => _showChangePasswordDialog(context),
              icon: const Icon(Icons.lock_reset, size: 18),
              label: const Text('Cambiar Contraseña'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authStateProvider.notifier).signOut();
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Cerrar Sesión'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailRow(String email) {
    final hasRealEmail = email.isNotEmpty && !email.contains('@temp.') && !email.contains('@alianzachaclacayo.pe');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Correo',
          style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.secondary),
        ),
        if (hasRealEmail)
          Row(
            children: [
              Text(
                email,
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(width: 4),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                tooltip: 'Actualizar correo',
                onPressed: () => _showUpdateEmailDialog(context, email),
              ),
            ],
          )
        else
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              backgroundColor: const Color(0xFFFEF3C7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => _showUpdateEmailDialog(context, ''),
            icon: const Icon(Icons.add_link, size: 15, color: Color(0xFFB45309)),
            label: Text(
              'Vincular Correo',
              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFFB45309)),
            ),
          ),
      ],
    );
  }

  Widget _buildPhoneRow(String phone) {
    final hasPhone = phone.isNotEmpty && phone != 'No registrado';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Teléfono',
          style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.secondary),
        ),
        if (hasPhone)
          Row(
            children: [
              Text(
                phone,
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(width: 4),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                tooltip: 'Actualizar teléfono',
                onPressed: () => _showUpdatePhoneDialog(context, phone),
              ),
            ],
          )
        else
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              backgroundColor: const Color(0xFFEFF6FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => _showUpdatePhoneDialog(context, ''),
            icon: const Icon(Icons.phone_android, size: 15, color: Color(0xFF1D4ED8)),
            label: Text(
              'Agregar Teléfono',
              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF1D4ED8)),
            ),
          ),
      ],
    );
  }

  void _showUpdatePhoneDialog(BuildContext context, String currentPhone) {
    final phoneCtrl = TextEditingController(text: currentPhone);
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.phone_android_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                currentPhone.isEmpty ? 'Agregar Teléfono' : 'Actualizar Teléfono',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ingresa tu número de celular o WhatsApp para contactarte sobre actividades de la iglesia:',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.inter(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Número de Celular *',
                    hintText: 'Ej: 987654321',
                    prefixIcon: const Icon(Icons.phone, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Ingresa tu número de celular';
                    if (val.trim().length < 9) return 'Número incompleto';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);
                      final newPhone = phoneCtrl.text.trim();
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(ctx);
                      try {
                        final client = Supabase.instance.client;
                        final user = client.auth.currentUser;
                        if (user != null) {
                          await client.from('profiles').update({'phone': newPhone}).eq('id', user.id);
                        }
                        if (mounted) {
                          navigator.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFF16A34A),
                              content: Text('¡Teléfono actualizado exitosamente!'),
                            ),
                          );
                          setState(() {});
                        }
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.error,
                              content: Text('Error al actualizar teléfono: $e'),
                            ),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateEmailDialog(BuildContext context, String currentEmail) {
    final emailCtrl = TextEditingController(text: currentEmail);
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.email_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                currentEmail.isEmpty ? 'Vincular Correo' : 'Actualizar Correo',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ingresa tu correo personal para recibir notificaciones y recuperar tu contraseña en caso la olvides:',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.inter(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico *',
                    hintText: 'ejemplo@gmail.com',
                    prefixIcon: const Icon(Icons.alternate_email, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Ingresa un correo';
                    if (!val.contains('@') || !val.contains('.')) return 'Correo inválido';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);
                      final newEmail = emailCtrl.text.trim();
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(ctx);
                      try {
                        final client = Supabase.instance.client;
                        final user = client.auth.currentUser;
                        if (user != null) {
                          await client.auth.updateUser(UserAttributes(email: newEmail));
                          await client.from('profiles').update({'email': newEmail}).eq('id', user.id);
                        }
                        if (mounted) {
                          navigator.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFF16A34A),
                              content: Text('¡Correo vinculado exitosamente!'),
                            ),
                          );
                          setState(() {});
                        }
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.error,
                              content: Text('Error al vincular correo: $e'),
                            ),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final user = ref.read(authStateProvider).userProfile;
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;
    bool obscure0 = true;
    bool obscure1 = true;
    bool obscure2 = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.lock_reset, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Cambiar Contraseña',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ingresa tu contraseña actual y luego define tu nueva contraseña segura:',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: currentPassCtrl,
                    obscureText: obscure0,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Contraseña Actual *',
                      prefixIcon: const Icon(Icons.key, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(obscure0 ? Icons.visibility_off : Icons.visibility, size: 18),
                        onPressed: () => setDialogState(() => obscure0 = !obscure0),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Ingresa tu contraseña actual';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPassCtrl,
                    obscureText: obscure1,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Nueva Contraseña *',
                      prefixIcon: const Icon(Icons.lock_outline, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(obscure1 ? Icons.visibility_off : Icons.visibility, size: 18),
                        onPressed: () => setDialogState(() => obscure1 = !obscure1),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) {
                      if (val == null || val.length < 6) return 'Mínimo 6 caracteres';
                      if (val == currentPassCtrl.text) return 'La nueva contraseña debe ser diferente a la actual';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPassCtrl,
                    obscureText: obscure2,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Confirmar Nueva Contraseña *',
                      prefixIcon: const Icon(Icons.lock_outline, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(obscure2 ? Icons.visibility_off : Icons.visibility, size: 18),
                        onPressed: () => setDialogState(() => obscure2 = !obscure2),
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
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(ctx);
                      try {
                        final client = Supabase.instance.client;
                        
                        // 1. Re-authenticate with current password to verify validity
                        final authEmail = user?.email.isNotEmpty == true
                            ? user!.email
                            : '${user?.dni ?? ""}@alianzachaclacayo.pe';

                        try {
                          await client.auth.signInWithPassword(
                            email: authEmail,
                            password: currentPassCtrl.text,
                          );
                        } catch (_) {
                          setDialogState(() => saving = false);
                          if (mounted) {
                            messenger.showSnackBar(
                              const SnackBar(
                                backgroundColor: AppColors.error,
                                content: Text('⚠️ La contraseña actual ingresada es incorrecta.'),
                              ),
                            );
                          }
                          return;
                        }

                        // 2. Update to new password
                        await client.auth.updateUser(UserAttributes(password: newPassCtrl.text));
                        if (mounted) {
                          navigator.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFF16A34A),
                              content: Text('¡Contraseña actualizada con éxito!'),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.error,
                              content: Text('Error al cambiar contraseña: $e'),
                            ),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Actualizar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipCard(dynamic user, String networkTitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CARNET DE MEMBRESÍA',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tertiaryAccent,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'Alianza Chaclacayo',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.card_membership,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            user.name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            networkTitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'DNI: ${user.dni}',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.secondary),
        ),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
      ],
    );
  }
}
