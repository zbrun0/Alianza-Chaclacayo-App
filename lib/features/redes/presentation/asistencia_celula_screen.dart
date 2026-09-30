import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_provider.dart';

enum AttendanceStatus { presencial, virtual, noAsistio }

class CellMemberAttendance {
  final String id;
  final String name;
  final bool isTemporary;
  AttendanceStatus status;

  CellMemberAttendance({
    required this.id,
    required this.name,
    this.isTemporary = false,
    this.status = AttendanceStatus.presencial,
  });

  bool get isPresent => status == AttendanceStatus.presencial || status == AttendanceStatus.virtual;
}

class AsistenciaCelulaScreen extends ConsumerStatefulWidget {
  final String cellId;
  final String cellName;

  const AsistenciaCelulaScreen({
    super.key,
    required this.cellId,
    required this.cellName,
  });

  @override
  ConsumerState<AsistenciaCelulaScreen> createState() => _AsistenciaCelulaScreenState();
}

class _AsistenciaCelulaScreenState extends ConsumerState<AsistenciaCelulaScreen> {
  bool _loading = true;
  bool _isSaving = false;
  bool _isSaved = false;

  Map<String, dynamic>? _cellInfo;
  List<CellMemberAttendance> _members = [];
  DateTime _sessionDate = DateTime.now();
  String _searchQuery = '';
  String? _existingReportId;

  @override
  void initState() {
    super.initState();
    _fetchCellAndMembers();
  }

  Future<void> _fetchCellAndMembers() async {
    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;

      // 1. Fetch cell details
      final cellRes = await client
          .from('cell_groups')
          .select('*, leader:leader_id(first_name, last_name, phone)')
          .eq('id', widget.cellId)
          .maybeSingle();

      _cellInfo = cellRes;

      // 2. Fetch existing report for today if any
      final dateStr = DateFormat('yyyy-MM-dd').format(_sessionDate);
      final existingRes = await client
          .from('group_attendance')
          .select('id, attendance_details')
          .eq('cell_id', widget.cellId)
          .eq('session_date', dateStr)
          .maybeSingle();

      final savedStatusMap = <String, AttendanceStatus>{};
      if (existingRes != null) {
        _existingReportId = existingRes['id']?.toString();
        final details = existingRes['attendance_details'];
        if (details is List) {
          for (final item in details) {
            final id = item['id']?.toString();
            final st = item['status']?.toString();
            if (id != null && st != null) {
              if (st == 'presencial') {
                savedStatusMap[id] = AttendanceStatus.presencial;
              } else if (st == 'virtual') {
                savedStatusMap[id] = AttendanceStatus.virtual;
              } else {
                savedStatusMap[id] = AttendanceStatus.noAsistio;
              }
            }
          }
        }
      }

      // 3. Fetch regular members
      final profilesRes = await client
          .from('profiles')
          .select('id, first_name, last_name')
          .eq('cell_id', widget.cellId);

      // 4. Fetch temporary / visitor members
      final tempRes = await client
          .from('temporary_members')
          .select('id, first_name, last_name')
          .eq('cell_id', widget.cellId);

      final leaderId = cellRes?['leader_id'];
      final List<CellMemberAttendance> list = [];

      for (final p in profilesRes) {
        if (p['id'] == leaderId) continue;
        final pId = p['id'].toString();
        final name = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();
        list.add(CellMemberAttendance(
          id: pId,
          name: name.isNotEmpty ? name : 'Miembro',
          isTemporary: false,
          status: savedStatusMap[pId] ?? AttendanceStatus.presencial,
        ));
      }

      for (final t in tempRes) {
        final tId = t['id'].toString();
        final name = '${t['first_name'] ?? ''} ${t['last_name'] ?? ''}'.trim();
        list.add(CellMemberAttendance(
          id: tId,
          name: name.isNotEmpty ? '$name (Visita)' : 'Visita',
          isTemporary: true,
          status: savedStatusMap[tId] ?? AttendanceStatus.presencial,
        ));
      }

      list.sort((a, b) => a.name.compareTo(b.name));

      if (mounted) {
        setState(() {
          _members = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showAddVisitorDialog() {
    final nameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Registrar Visita o Amigo Nuevo',
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombres *',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lastNameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Apellidos (Opcional)',
                prefixIcon: Icon(Icons.badge_outlined),
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
            onPressed: () async {
              final first = nameCtrl.text.trim();
              final last = lastNameCtrl.text.trim();
              if (first.isEmpty) return;

              Navigator.pop(ctx);
              try {
                final client = Supabase.instance.client;
                final inserted = await client.from('temporary_members').insert({
                  'cell_id': widget.cellId,
                  'first_name': first,
                  'last_name': last,
                }).select().single();

                final newMember = CellMemberAttendance(
                  id: inserted['id'].toString(),
                  name: '$first $last (Visita)'.trim(),
                  isTemporary: true,
                  status: AttendanceStatus.presencial,
                );

                setState(() {
                  _members.add(newMember);
                  _members.sort((a, b) => a.name.compareTo(b.name));
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Visita $first registrada en la célula')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al registrar visita: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAttendance() async {
    final user = ref.read(authStateProvider).userProfile;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para registrar asistencia')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final client = Supabase.instance.client;
      final dateStr = DateFormat('yyyy-MM-dd').format(_sessionDate);
      final presentCount = _members.where((m) => m.isPresent).length;

      final details = _members.map((m) {
        String st = 'presencial';
        if (m.status == AttendanceStatus.virtual) st = 'virtual';
        if (m.status == AttendanceStatus.noAsistio) st = 'no_asistio';
        return {
          'id': m.id,
          'name': m.name,
          'status': st,
          'is_temporary': m.isTemporary,
        };
      }).toList();

      final payload = {
        'cell_id': widget.cellId,
        'network': _cellInfo?['network'] ?? user.assignedNetwork,
        'session_date': dateStr,
        'present_count': presentCount,
        'total_assigned': _members.length,
        'recorded_by': user.id,
        'attendance_type': 'semanal',
        'attendance_details': details,
      };

      if (_existingReportId != null) {
        await client
            .from('group_attendance')
            .update(payload)
            .eq('id', _existingReportId!);
      } else {
        final inserted = await client
            .from('group_attendance')
            .insert(payload)
            .select('id')
            .maybeSingle();
        if (inserted != null) {
          _existingReportId = inserted['id'].toString();
        }
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isSaved = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Reporte de Célula enviado exitosamente a Pastoral!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar reporte: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = _members.where((m) => m.isPresent).length;
    final totalCount = _members.length;

    final filteredMembers = _searchQuery.isEmpty
        ? _members
        : _members.where((m) => m.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Asistencia de Célula',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.cellName,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt),
            tooltip: 'Registrar Visita Nueva',
            onPressed: _showAddVisitorDialog,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Info & Date Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: AppColors.surfaceContainerLowest,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _sessionDate,
                                  firstDate: DateTime.now().subtract(const Duration(days: 60)),
                                  lastDate: DateTime.now().add(const Duration(days: 7)),
                                );
                                if (picked != null) {
                                  setState(() => _sessionDate = picked);
                                  _fetchCellAndMembers();
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('dd/MM/yyyy').format(_sessionDate),
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.secondary),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Live Pill Counter
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.groups, size: 18, color: Color(0xFF166534)),
                                const SizedBox(width: 6),
                                Text(
                                  '$presentCount / $totalCount Asistentes',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF166534),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Search Bar
                      TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Buscar miembro o visita...',
                          hintStyle: const TextStyle(fontSize: 12.5),
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Members List
                Expanded(
                  child: filteredMembers.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _searchQuery.isEmpty
                                  ? 'No hay miembros asignados a esta célula.\nPuedes registrar visitas usando el botón superior.'
                                  : 'No se encontraron miembros para "$_searchQuery".',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.secondary),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredMembers.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final member = filteredMembers[index];

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: member.isPresent ? const Color(0xFFCBD5E1) : const Color(0xFFF1F5F9),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: member.isTemporary
                                            ? const Color(0xFFFEF3C7)
                                            : AppColors.primary.withValues(alpha: 0.1),
                                        child: Text(
                                          member.name.isNotEmpty ? member.name[0].toUpperCase() : 'M',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: member.isTemporary
                                                ? const Color(0xFFD97706)
                                                : AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          member.name,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Status Toggle Buttons (Presencial / Virtual / Falta)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatusBtn(
                                          label: 'Presencial',
                                          icon: Icons.person,
                                          isSelected: member.status == AttendanceStatus.presencial,
                                          activeColor: const Color(0xFF16A34A),
                                          onTap: () => setState(() => member.status = AttendanceStatus.presencial),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: _buildStatusBtn(
                                          label: 'Virtual',
                                          icon: Icons.devices,
                                          isSelected: member.status == AttendanceStatus.virtual,
                                          activeColor: const Color(0xFF2563EB),
                                          onTap: () => setState(() => member.status = AttendanceStatus.virtual),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: _buildStatusBtn(
                                          label: 'Falta',
                                          icon: Icons.close,
                                          isSelected: member.status == AttendanceStatus.noAsistio,
                                          activeColor: const Color(0xFF64748B),
                                          onTap: () => setState(() => member.status = AttendanceStatus.noAsistio),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // Bottom Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _submitAttendance,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        _isSaved ? '¡Reporte Enviado a Pastoral!' : 'Enviar Reporte de Célula',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSaved ? const Color(0xFF059669) : AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusBtn({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : AppColors.secondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
