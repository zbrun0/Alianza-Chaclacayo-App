import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_provider.dart';

class StudentAttendanceItem {
  final String id;
  final String name;
  final String dni;
  final String phone;
  String status; // 'presente', 'ausente', 'justificado'

  StudentAttendanceItem({
    required this.id,
    required this.name,
    required this.dni,
    required this.phone,
    required this.status,
  });
}

class AsistenciaClaseScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String courseTitle;
  final String schedule;
  final String level;

  const AsistenciaClaseScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.schedule,
    required this.level,
  });

  @override
  ConsumerState<AsistenciaClaseScreen> createState() => _AsistenciaClaseScreenState();
}

class _AsistenciaClaseScreenState extends ConsumerState<AsistenciaClaseScreen> {
  DateTime _selectedDate = DateTime.now();
  List<String> _pastSessions = [];
  List<StudentAttendanceItem> _students = [];
  bool _loading = true;
  bool _isSaving = false;
  bool _isEditMode = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCourseAttendance();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDateYMD(DateTime dt) {
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  String _formatDateDisplay(String ymd) {
    try {
      final parsed = DateTime.parse(ymd);
      return DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {
      return ymd;
    }
  }

  Future<void> _loadCourseAttendance() async {
    setState(() => _loading = true);
    final client = Supabase.instance.client;
    final dateStr = _formatDateYMD(_selectedDate);

    try {
      // 1. Fetch past recorded sessions for this course
      final pastRes = await client
          .from('academy_attendance')
          .select('session_date')
          .eq('course_id', widget.courseId);

      final uniqueDates = <String>{};
      for (final r in pastRes) {
        if (r['session_date'] != null) {
          uniqueDates.add(r['session_date'].toString());
        }
      }
      _pastSessions = uniqueDates.toList()..sort((a, b) => b.compareTo(a));

      // 2. Fetch enrolled students
      final enrollRes = await client
          .from('enrollments')
          .select('student_id, profiles:student_id(id, first_name, last_name, dni, phone)')
          .eq('course_id', widget.courseId);

      // 3. Fetch attendance for selected date
      final savedAttendanceRes = await client
          .from('academy_attendance')
          .select('student_id, status')
          .eq('course_id', widget.courseId)
          .eq('session_date', dateStr);

      final savedMap = <String, String>{};
      if (savedAttendanceRes.isNotEmpty) {
        _isEditMode = true;
        for (final r in savedAttendanceRes) {
          savedMap[r['student_id']?.toString() ?? ''] = r['status']?.toString() ?? 'presente';
        }
      } else {
        _isEditMode = false;
      }

      final list = <StudentAttendanceItem>[];
      for (final e in enrollRes) {
        final profile = e['profiles'];
        if (profile != null) {
          final id = profile['id']?.toString() ?? '';
          final name = '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim();
          final dni = profile['dni']?.toString() ?? 'No registrado';
          final phone = profile['phone']?.toString() ?? '';
          final status = savedMap[id] ?? 'presente';

          list.add(StudentAttendanceItem(
            id: id,
            name: name.isNotEmpty ? name : 'Alumno',
            dni: dni,
            phone: phone,
            status: status,
          ));
        }
      }

      list.sort((a, b) => a.name.compareTo(b.name));

      if (mounted) {
        setState(() {
          _students = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar alumnos: $e')),
        );
      }
    }
  }

  Future<void> _saveAttendance() async {
    final user = ref.read(authStateProvider).userProfile;
    if (user == null) return;
    if (_students.isEmpty) return;

    setState(() => _isSaving = true);
    final client = Supabase.instance.client;
    final dateStr = _formatDateYMD(_selectedDate);

    try {
      // If edit mode, delete existing for this date
      if (_isEditMode) {
        await client
            .from('academy_attendance')
            .delete()
            .eq('course_id', widget.courseId)
            .eq('session_date', dateStr);
      }

      // Insert new records
      final records = _students.map((s) => {
        'course_id': widget.courseId,
        'student_id': s.id,
        'session_date': dateStr,
        'status': s.status,
        'recorded_by': user.id,
      }).toList();

      await client.from('academy_attendance').insert(records);

      // Recalculate attendance percentage for all enrolled students in this course
      final allAttRes = await client
          .from('academy_attendance')
          .select('student_id, status')
          .eq('course_id', widget.courseId);

      final studentMap = <String, List<String>>{};
      for (final r in allAttRes) {
        final stId = r['student_id']?.toString() ?? '';
        final stStatus = r['status']?.toString() ?? 'presente';
        studentMap.putIfAbsent(stId, () => []).add(stStatus);
      }

      for (final entry in studentMap.entries) {
        final total = entry.value.length;
        final presentOrJust = entry.value.where((s) => s == 'presente' || s == 'justificado').length;
        final pct = total > 0 ? (presentOrJust / total) * 100 : 100.0;

        await client
            .from('enrollments')
            .update({'attendance_percentage': double.parse(pct.toStringAsFixed(2))})
            .eq('course_id', widget.courseId)
            .eq('student_id', entry.key);
      }

      if (mounted) {
        setState(() {
          _isEditMode = true;
          _isSaving = false;
        });
        if (!_pastSessions.contains(dateStr)) {
          _pastSessions.insert(0, dateStr);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16A34A),
            content: Text(
              _isEditMode
                  ? '¡Asistencia actualizada correctamente en el sistema!'
                  : '¡Asistencia guardada correctamente!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Error al guardar asistencia: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _students.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.dni.contains(_searchQuery);
    }).toList();

    final presentCount = _students.where((s) => s.status == 'presente').length;
    final absentCount = _students.where((s) => s.status == 'ausente').length;
    final justCount = _students.where((s) => s.status == 'justificado').length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Pase de Lista - Academia',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Course Header Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryContainer],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.courseTitle,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Nivel ${widget.level.toUpperCase()} • ${widget.schedule}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Date selector button
                              GestureDetector(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate,
                                    firstDate: DateTime(2025),
                                    lastDate: DateTime.now().add(const Duration(days: 7)),
                                  );
                                  if (picked != null && picked != _selectedDate) {
                                    setState(() => _selectedDate = picked);
                                    _loadCourseAttendance();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.calendar_month, color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Fecha: ${_formatDateDisplay(_formatDateYMD(_selectedDate))}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Alumnos: ${_students.length}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  if (_isEditMode)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFBBF24),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Modo Edición',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF78350F),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Past Sessions History Chips
                        if (_pastSessions.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.history, size: 16, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      'SESIONES REGISTRADAS ANTERIORMENTE',
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.6,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: _pastSessions.map((dateStr) {
                                    final isSelected = dateStr == _formatDateYMD(_selectedDate);
                                    return ChoiceChip(
                                      label: Text(
                                        _formatDateDisplay(dateStr),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? Colors.white : AppColors.primary,
                                        ),
                                      ),
                                      selected: isSelected,
                                      selectedColor: AppColors.primary,
                                      backgroundColor: AppColors.surface,
                                      onSelected: (val) {
                                        if (val) {
                                          setState(() => _selectedDate = DateTime.parse(dateStr));
                                          _loadCourseAttendance();
                                        }
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Search Bar
                        TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            hintText: 'Buscar alumno por nombre o DNI...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: AppColors.surfaceContainerLowest,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Students List with 3-state buttons
                        if (filtered.isEmpty) ...[
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                _students.isEmpty
                                    ? 'No hay alumnos inscritos en este curso.'
                                    : 'No se encontraron alumnos con ese criterio.',
                                style: GoogleFonts.inter(fontSize: 13, color: AppColors.secondary),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ] else ...[
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final st = filtered[index];
                              return _buildStudentCard(st);
                            },
                          ),
                        ],

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),

                // Bottom Summary & Save Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Presentes: $presentCount',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                            Text(
                              'Ausentes: $absentCount',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                            Text(
                              'Justificados: $justCount',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveAttendance,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Icon(_isEditMode ? Icons.edit : Icons.save, size: 18),
                          label: Text(
                            _isSaving
                                ? 'Guardando Asistencias...'
                                : (_isEditMode ? 'Editar Asistencia de Clase' : 'Guardar Asistencia de Clase'),
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStudentCard(StudentAttendanceItem student) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.15),
                child: Text(
                  student.name.isNotEmpty ? student.name[0].toUpperCase() : 'A',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'DNI: ${student.dni}',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3 Attendance Buttons
          Row(
            children: [
              Expanded(
                child: _buildStatusButton(
                  title: 'Asistió',
                  icon: Icons.check_circle_outline,
                  isSelected: student.status == 'presente',
                  activeColor: const Color(0xFF16A34A),
                  onTap: () => setState(() => student.status = 'presente'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildStatusButton(
                  title: 'No Asistió',
                  icon: Icons.highlight_off,
                  isSelected: student.status == 'ausente',
                  activeColor: AppColors.error,
                  onTap: () => setState(() => student.status = 'ausente'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildStatusButton(
                  title: 'Justificado',
                  icon: Icons.info_outline,
                  isSelected: student.status == 'justificado',
                  activeColor: const Color(0xFFD97706),
                  onTap: () => setState(() => student.status = 'justificado'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppColors.secondary,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
