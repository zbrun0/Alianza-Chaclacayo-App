import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

class AdminMembersScreen extends ConsumerStatefulWidget {
  final String? initialFilter;
  const AdminMembersScreen({super.key, this.initialFilter});

  @override
  ConsumerState<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends ConsumerState<AdminMembersScreen> {
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;
  String _searchTerm = '';
  late String _statusFilter;

  static const List<Map<String, String>> rolesList = [
    {'id': 'admin', 'label': 'Administrador (Soporte Técnico)'},
    {'id': 'pastor', 'label': 'Pastor Principal'},
    {'id': 'coordinador_red', 'label': 'Coordinador de Red'},
    {'id': 'lider_red', 'label': 'Líder de Red'},
    {'id': 'lider_grupo', 'label': 'Líder de Célula / Grupo Pequeño'},
    {'id': 'maestro', 'label': 'Maestro'},
    {'id': 'coordinador_academia', 'label': 'Coordinador de Academia'},
    {'id': 'admin_tesoreria', 'label': 'Encargado de Tesorería'},
    {'id': 'encargado_anuncios', 'label': 'Encargado de Anuncios'},
    {'id': 'encargado_oracion', 'label': 'Encargado de Oración'},
    {'id': 'conteo_culto', 'label': 'Encargado Conteo Culto'},
    {'id': 'miembro', 'label': 'Miembro'},
  ];

  static String formatMemberRoles(String roleStr) {
    const map = {
      'admin': 'Admin (Soporte)',
      'pastor': 'Pastor Principal',
      'coordinador_red': 'Coordinador de Red',
      'lider_red': 'Líder de Red',
      'lider_grupo': 'Líder de Célula',
      'maestro': 'Maestro',
      'instructor_temporal': 'Maestro',
      'instructor_abc': 'Maestro',
      'coordinador_academia': 'Coord. Academia',
      'admin_tesoreria': 'Tesorería',
      'encargado_anuncios': 'Anuncios',
      'encargado_oracion': 'Oración',
      'apoyo_abc': 'Apoyo Academia',
      'conteo_culto': 'Conteo Culto',
      'miembro': 'Miembro',
    };
    final roles = roleStr.split(',').map((r) => r.trim().toLowerCase()).where((r) => r.isNotEmpty).toList();
    if (roles.isEmpty) return 'Miembro';
    final labels = roles.map((r) => map[r] ?? r).toSet().toList();
    return labels.join(', ');
  }

  static const List<Map<String, String>> networksList = [
    {'id': 'kids', 'label': 'Generación Kids'},
    {'id': 'next', 'label': 'NEXT (Pre-adolescentes)'},
    {'id': 'free', 'label': 'Free (Adolescentes)'},
    {'id': 'legado', 'label': 'Legado (Jóvenes)'},
    {'id': 'dunamis', 'label': 'Dunamis (Jóvenes Adultos)'},
    {'id': 'maravillosos', 'label': 'Años Maravillosos'},
    {'id': 'mujeres', 'label': 'Red de Mujeres'},
    {'id': 'varones', 'label': 'Red de Varones'},
    {'id': 'matrimonios', 'label': 'Red de Matrimonios'},
  ];

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialFilter ?? 'all';
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() => _loading = true);
    final client = Supabase.instance.client;

    try {
      final res = await client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _members = List<Map<String, dynamic>>.from(res);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error al cargar miembros: $e')),
        );
      }
    }
  }

  Future<void> _updateMemberApproval(String memberId, bool isApproved) async {
    final client = Supabase.instance.client;
    try {
      await client
          .from('profiles')
          .update({'is_approved': isApproved})
          .eq('id', memberId);

      setState(() {
        final idx = _members.indexWhere((m) => m['id'] == memberId);
        if (idx != -1) {
          _members[idx]['is_approved'] = isApproved;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: isApproved ? const Color(0xFF16A34A) : AppColors.error,
            content: Text(isApproved ? '¡Miembro autorizado con éxito!' : 'Autorización revocada.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _updateMemberRole(String memberId, String newRole, [String? newNetwork]) async {
    final client = Supabase.instance.client;
    try {
      final updateData = <String, dynamic>{'role': newRole};
      if (newNetwork != null && newNetwork.isNotEmpty) {
        updateData['assigned_network'] = newNetwork;
      }
      await client
          .from('profiles')
          .update(updateData)
          .eq('id', memberId);

      setState(() {
        final idx = _members.indexWhere((m) => m['id'] == memberId);
        if (idx != -1) {
          _members[idx]['role'] = newRole;
          if (newNetwork != null && newNetwork.isNotEmpty) {
            _members[idx]['assigned_network'] = newNetwork;
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF16A34A),
            content: Text('¡Rol y red ministerial actualizados con éxito!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error al actualizar rol: $e')),
        );
      }
    }
  }

  Future<void> _updateMemberNetwork(String memberId, String newNetwork) async {
    final client = Supabase.instance.client;
    try {
      await client
          .from('profiles')
          .update({'assigned_network': newNetwork})
          .eq('id', memberId);

      setState(() {
        final idx = _members.indexWhere((m) => m['id'] == memberId);
        if (idx != -1) {
          _members[idx]['assigned_network'] = newNetwork;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF16A34A),
            content: Text('¡Red asignada actualizada exitosamente!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _toggleBaptism(String memberId, bool current) async {
    final client = Supabase.instance.client;
    try {
      await client
          .from('profiles')
          .update({'is_baptized': !current})
          .eq('id', memberId);

      setState(() {
        final idx = _members.indexWhere((m) => m['id'] == memberId);
        if (idx != -1) {
          _members[idx]['is_baptized'] = !current;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16A34A),
            content: Text(!current ? 'Marcado como Bautizado' : 'Marcado como No Bautizado'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _showMemberAcademicHistoryModal(Map<String, dynamic> member) async {
    final memberId = member['id'];
    final fullName = '${member['first_name'] ?? ''} ${member['last_name'] ?? ''}'.trim();
    final dni = member['dni'] ?? 'S/DNI';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FutureBuilder<List<dynamic>>(
          future: Future.wait([
            Supabase.instance.client
                .from('enrollments')
                .select('*, courses(*, profiles:teacher_id(first_name, last_name))')
                .eq('student_id', memberId),
            Supabase.instance.client
                .from('academy_approved_subjects')
                .select()
                .eq('student_id', memberId),
          ]),
          builder: (context, snapshot) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.history_edu, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Historial de Cursos ABC',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              '$fullName (DNI: $dni)',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Expanded(child: Center(child: CircularProgressIndicator()))
                  else if (snapshot.hasError)
                    Expanded(
                      child: Center(
                        child: Text(
                          'Error al cargar historial: ${snapshot.error}',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.error),
                        ),
                      ),
                    )
                  else () {
                    final enrollments = List<Map<String, dynamic>>.from(snapshot.data?[0] ?? []);
                    final approved = List<Map<String, dynamic>>.from(snapshot.data?[1] ?? []);

                    if (enrollments.isEmpty && approved.isEmpty) {
                      return Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.school_outlined, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                'No tiene cursos registrados en la academia',
                                style: GoogleFonts.inter(fontSize: 13, color: AppColors.secondary),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Expanded(
                      child: ListView(
                        children: [
                          // Stats summary row
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '${enrollments.length}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      Text('Matriculados', style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '${approved.length}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF16A34A),
                                        ),
                                      ),
                                      Text('Aprobados', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF16A34A))),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'MATRÍCULAS Y CURSOS',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...enrollments.map((enr) {
                            final course = enr['courses'] as Map<String, dynamic>? ?? {};
                            final title = course['title'] ?? 'Curso';
                            final code = course['code'] ?? '';
                            final cycle = course['cycle'] ?? '';
                            final grade = enr['final_grade'];
                            final att = enr['attendance_percentage'] ?? 100;
                            final isAppr = enr['is_approved'] == true;
                            final isCourseActive = course['is_active'] ?? true;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isAppr
                                          ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                                          : AppColors.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isAppr ? Icons.check_circle : (isCourseActive ? Icons.play_circle_outline : Icons.cancel_outlined),
                                      color: isAppr ? const Color(0xFF16A34A) : AppColors.primary,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$code: $title',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        if (cycle.isNotEmpty)
                                          Text('Ciclo: $cycle', style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              'Asistencia: $att%',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: att >= 80 ? const Color(0xFF16A34A) : AppColors.error,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Nota: ${grade != null ? grade.toString() : "Pendiente"}',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: grade != null && grade >= 14
                                                    ? const Color(0xFF16A34A)
                                                    : (grade != null ? AppColors.error : Colors.grey[700]),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isAppr
                                          ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                                          : (isCourseActive ? const Color(0xFF0284C7).withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.12)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isAppr ? 'APROBADO' : (isCourseActive ? 'EN CURSO' : 'FINALIZADO'),
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: isAppr
                                            ? const Color(0xFF16A34A)
                                            : (isCourseActive ? const Color(0xFF0284C7) : Colors.grey[700]),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRoleDialog(Map<String, dynamic> member) {
    final rawRole = (member['role'] ?? 'miembro').toString();
    final initialRoles = rawRole
        .split(',')
        .map((r) => r.trim().toLowerCase())
        .where((r) => r.isNotEmpty)
        .toSet();
    if (initialRoles.isEmpty) {
      initialRoles.add('miembro');
    }

    final selectedRoles = Set<String>.from(initialRoles);
    String selectedNetwork = member['assigned_network'] ?? 'dunamis';
    if (!networksList.any((n) => n['id'] == selectedNetwork)) {
      selectedNetwork = networksList.first['id']!;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isLeadingNetwork = selectedRoles.contains('coordinador_red') ||
              selectedRoles.contains('lider_red') ||
              selectedRoles.contains('lider_grupo');

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.badge_outlined, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Asignar Roles Ministeriales',
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
                    // Botón directo para ver historial de cursos del hermano
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showMemberAcademicHistoryModal(member);
                        },
                        icon: const Icon(Icons.history_edu, size: 16),
                        label: Text(
                          'Ver Historial de Cursos (${member['first_name'] ?? 'Miembro'})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    Text(
                      'Puedes seleccionar uno o varios roles simultáneamente para este usuario:',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary),
                    ),
                    const SizedBox(height: 12),
                    ...rolesList.map((r) {
                      final roleId = r['id']!;
                      final isSelected = selectedRoles.contains(roleId);
                      final isAdmin = roleId == 'admin';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isAdmin ? const Color(0xFFFEF2F2) : AppColors.primaryContainer.withValues(alpha: 0.1))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CheckboxListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          activeColor: isAdmin ? const Color(0xFFDC2626) : AppColors.primary,
                          title: Text(
                            r['label']!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isAdmin && isSelected ? const Color(0xFFDC2626) : Colors.black87,
                            ),
                          ),
                          subtitle: isAdmin
                              ? Text(
                                  'Acceso total a todos los módulos y backoffice',
                                  style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFFDC2626)),
                                )
                              : null,
                          value: isSelected,
                          onChanged: (checked) {
                            setDialogState(() {
                              if (checked == true) {
                                selectedRoles.add(roleId);
                                if (roleId != 'miembro') {
                                  selectedRoles.remove('miembro');
                                } else {
                                  selectedRoles.clear();
                                  selectedRoles.add('miembro');
                                }
                              } else {
                                selectedRoles.remove(roleId);
                                if (selectedRoles.isEmpty) {
                                  selectedRoles.add('miembro');
                                }
                              }
                            });
                          },
                        ),
                      );
                    }),

                    if (isLeadingNetwork) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.hub_outlined, size: 16, color: Color(0xFF16A34A)),
                                const SizedBox(width: 6),
                                Text(
                                  'RED MINISTERIAL A DIRIGIR *',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF166534)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Selecciona la red ministerial que el hermano va a coordinar o dirigir:',
                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF14532D)),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: selectedNetwork,
                              isExpanded: true,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                fillColor: Colors.white,
                                filled: true,
                              ),
                              items: networksList.map((n) {
                                return DropdownMenuItem<String>(
                                  value: n['id'],
                                  child: Text(n['label']!, style: const TextStyle(fontSize: 12.5)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => selectedNetwork = val);
                                }
                              },
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
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final finalRoles = selectedRoles.isEmpty ? 'miembro' : selectedRoles.join(',');
                  Navigator.pop(ctx);
                  _updateMemberRole(member['id'], finalRoles, isLeadingNetwork ? selectedNetwork : null);
                },
                child: const Text('Guardar Roles', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showNetworkDialog(Map<String, dynamic> member) {
    String currentNet = member['assigned_network'] ?? 'dunamis';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Asignar Red Ministerial',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: networksList.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final n = networksList[index];
              final isSelected = n['id'] == currentNet;
              return ListTile(
                title: Text(n['label']!, style: GoogleFonts.inter(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  _updateMemberNetwork(member['id'], n['id']!);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingMembers = _members.where((m) => m['is_approved'] != true).toList();
    final leaderMembers = _members.where((m) {
      final roles = (m['role'] ?? '').toString().toLowerCase();
      return roles.contains('lider_grupo') || roles.contains('lider_red') || roles.contains('coordinador_red');
    }).toList();
    final coordMembers = _members.where((m) {
      final roles = (m['role'] ?? '').toString().toLowerCase();
      return roles.contains('coordinador_academia') || roles.contains('coordinador_red');
    }).toList();
    final teacherMembers = _members.where((m) {
      final roles = (m['role'] ?? '').toString().toLowerCase();
      return roles.contains('maestro') || roles.contains('instructor_abc') || roles.contains('instructor_temporal');
    }).toList();
    final pastorMembers = _members.where((m) {
      final roles = (m['role'] ?? '').toString().toLowerCase();
      return roles.contains('pastor') || roles.contains('admin');
    }).toList();

    final filtered = _members.where((m) {
      final name = '${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'.toLowerCase();
      final dni = (m['dni'] ?? '').toString();
      final matchQuery = name.contains(_searchTerm.toLowerCase()) || dni.contains(_searchTerm);
      if (!matchQuery) return false;

      final roles = (m['role'] ?? '').toString().toLowerCase();

      if (_statusFilter == 'pending') return m['is_approved'] != true;
      if (_statusFilter == 'approved') return m['is_approved'] == true;
      if (_statusFilter == 'lideres') {
        return roles.contains('lider_grupo') || roles.contains('lider_red') || roles.contains('coordinador_red');
      }
      if (_statusFilter == 'coordinadores') {
        return roles.contains('coordinador_academia') || roles.contains('coordinador_red');
      }
      if (_statusFilter == 'maestros') {
        return roles.contains('maestro') || roles.contains('instructor_abc') || roles.contains('instructor_temporal');
      }
      if (_statusFilter == 'pastores') {
        return roles.contains('pastor') || roles.contains('admin');
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Directorio de Miembros',
          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Recargar miembros',
            onPressed: _loading ? null : _fetchMembers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter & Search Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombres o DNI...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onChanged: (val) => setState(() => _searchTerm = val),
                ),
                const SizedBox(height: 12),

                // Status & Role Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'Todos (${_members.length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip('lideres', 'Líderes (${leaderMembers.length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip('coordinadores', 'Coordinadores (${coordMembers.length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip('maestros', 'Maestros (${teacherMembers.length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip('pastores', 'Pastores/Admin (${pastorMembers.length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip('pending', 'Pendientes (${pendingMembers.length})', isAlert: pendingMembers.isNotEmpty),
                      const SizedBox(width: 8),
                      _buildFilterChip('approved', 'Autorizados (${_members.length - pendingMembers.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Members List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No se encontraron miembros con ese criterio.',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.secondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final member = filtered[index];
                          final isApproved = member['is_approved'] == true;
                          final isBaptized = member['is_baptized'] == true;
                          final fullName = '${member['first_name'] ?? ''} ${member['last_name'] ?? ''}'.trim();
                          final dni = member['dni'] ?? 'S/DNI';
                          final phone = member['phone'] ?? '';
                          final email = member['email'] ?? '';
                          final role = member['role'] ?? 'miembro';
                          final network = member['assigned_network'] ?? 'dunamis';

                          final formattedRole = formatMemberRoles(role);
                          final netObj = networksList.firstWhere((n) => n['id'] == network, orElse: () => {'label': network});

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: !isApproved ? const Color(0xFFFBBF24) : const Color(0xFFE2E8F0),
                                width: !isApproved ? 1.5 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryContainer.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Row: Name + Approval Badge
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        fullName,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isApproved
                                            ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                                            : const Color(0xFFD97706).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isApproved ? 'AUTORIZADO' : 'PENDIENTE',
                                        style: GoogleFonts.inter(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: isApproved ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // DNI & Contacts
                                Text('DNI: $dni • Tel: ${phone.isNotEmpty ? phone : "No registrado"}', style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.secondary)),
                                if (email.isNotEmpty)
                                  Text('Email: $email', style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary)),

                                const SizedBox(height: 10),

                                // Tags Row (Rol, Historial, Red, Bautizado)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    ActionChip(
                                      avatar: const Icon(Icons.shield_outlined, size: 14, color: AppColors.primary),
                                      label: Text('Rol: $formattedRole', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      onPressed: () => _showRoleDialog(member),
                                    ),
                                    ActionChip(
                                      avatar: const Icon(Icons.history_edu, size: 14, color: Color(0xFF7C3AED)),
                                      label: const Text('Historial Cursos', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                                      backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                                      onPressed: () => _showMemberAcademicHistoryModal(member),
                                    ),
                                    ActionChip(
                                      avatar: const Icon(Icons.groups, size: 14, color: Color(0xFF047857)),
                                      label: Text('Red: ${netObj['label']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      onPressed: () => _showNetworkDialog(member),
                                    ),
                                    ActionChip(
                                      avatar: Icon(isBaptized ? Icons.water_drop : Icons.water_drop_outlined, size: 14, color: const Color(0xFF0284C7)),
                                      label: Text(isBaptized ? 'Bautizado: Sí' : 'Bautizado: No', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      onPressed: () => _toggleBaptism(member['id'], isBaptized),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Actions Bar
                                Row(
                                  children: [
                                    if (!isApproved)
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _updateMemberApproval(member['id'], true),
                                          icon: const Icon(Icons.check, size: 16),
                                          label: const Text('Autorizar Miembro'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF16A34A),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                        ),
                                      )
                                    else
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _updateMemberApproval(member['id'], false),
                                          icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                                          label: const Text('Revocar Acceso', style: TextStyle(color: AppColors.error)),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: AppColors.error),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                        ),
                                      ),
                                    if (phone.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      IconButton.filledTonal(
                                        icon: const Icon(Icons.chat, color: Color(0xFF15803D), size: 18),
                                        tooltip: 'Escribir por WhatsApp',
                                        onPressed: () {
                                          final cleanPhone = phone.startsWith('+') ? phone : '+51$phone';
                                          launchUrl(
                                            Uri.parse('https://api.whatsapp.com/send?phone=$cleanPhone&text=Hola%20$fullName,%20te%20saludamos%20de%20la%20iglesia%20Alianza%20Chaclacayo.'),
                                            mode: LaunchMode.externalApplication,
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label, {bool isAlert = false}) {
    final isSelected = _statusFilter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _statusFilter = filterKey);
      },
      selectedColor: isAlert ? const Color(0xFFFEF3C7) : AppColors.primary,
      backgroundColor: isAlert ? const Color(0xFFFEF3C7).withValues(alpha: 0.5) : AppColors.surfaceContainerLow,
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected
            ? (isAlert ? const Color(0xFF92400E) : Colors.white)
            : (isAlert ? const Color(0xFF92400E) : AppColors.secondary),
      ),
    );
  }
}
