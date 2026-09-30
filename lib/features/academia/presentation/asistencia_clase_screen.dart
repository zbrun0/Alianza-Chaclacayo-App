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
  bool _attendanceOpen = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  String? _rescheduledDate;
  String? _rescheduledTime;
  String? _rescheduledReason;

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
      // 1. Fetch course info for attendance_open status and rescheduling
      final courseRes = await client
          .from('courses')
          .select('attendance_open, attendance_session_date, rescheduled_date, rescheduled_time, rescheduled_reason')
          .eq('id', widget.courseId)
          .maybeSingle();

      bool isAttOpen = false;
      String? resDate;
      String? resTime;
      String? resReason;
      if (courseRes != null) {
        isAttOpen = courseRes['attendance_open'] == true &&
            courseRes['attendance_session_date']?.toString() == dateStr;
        resDate = courseRes['rescheduled_date']?.toString();
        resTime = courseRes['rescheduled_time']?.toString();
        resReason = courseRes['rescheduled_reason']?.toString();
      }

      // 2. Fetch past recorded sessions for this course
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

      // 3. Fetch enrolled students
      final enrollRes = await client
          .from('enrollments')
          .select('student_id, profiles:student_id(id, first_name, last_name, dni, phone)')
          .eq('course_id', widget.courseId);

      // 4. Fetch attendance for selected date
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
          _attendanceOpen = isAttOpen;
          _rescheduledDate = resDate;
          _rescheduledTime = resTime;
          _rescheduledReason = resReason;
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

  Future<void> _showReprogramSessionDialog() async {
    DateTime newDate = _selectedDate;
    if (_rescheduledDate != null && _rescheduledDate!.isNotEmpty) {
      try {
        newDate = DateTime.parse(_rescheduledDate!);
      } catch (_) {}
    }

    TimeOfDay newTime = const TimeOfDay(hour: 9, minute: 45);
    if (_rescheduledTime != null && _rescheduledTime!.isNotEmpty) {
      final resMatch = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)?', caseSensitive: false).firstMatch(_rescheduledTime!);
      if (resMatch != null) {
        int h = int.tryParse(resMatch.group(1)!) ?? 9;
        final int m = int.tryParse(resMatch.group(2)!) ?? 0;
        final p = resMatch.group(3)?.toUpperCase();
        if (p == 'PM' && h < 12) h += 12;
        if (p == 'AM' && h == 12) h = 0;
        newTime = TimeOfDay(hour: h, minute: m);
      }
    }

    final reasonCtrl = TextEditingController(text: _rescheduledReason ?? '');
    bool isReprogrammed = _rescheduledDate != null && _rescheduledDate!.isNotEmpty;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.event_repeat, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Reprogramar Sesión', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configura una fecha u hora excepcional para una sesión (ej. feriado o evento eclesial).',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Habilitar Reprogramación', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  value: isReprogrammed,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) {
                    setDialogState(() => isReprogrammed = val);
                  },
                ),
                if (isReprogrammed) ...[
                  const SizedBox(height: 10),
                  Text('Fecha de la nueva sesión:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: newDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        locale: const Locale('es', 'PE'),
                      );
                      if (picked != null) {
                        setDialogState(() => newDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Text(DateFormat('dd/MM/yyyy', 'es_PE').format(newDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Hora de la nueva sesión:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(context: ctx, initialTime: newTime);
                      if (picked != null) {
                        setDialogState(() => newTime = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${(newTime.hourOfPeriod == 0 ? 12 : newTime.hourOfPeriod).toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')} ${newTime.period == DayPeriod.am ? 'AM' : 'PM'}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonCtrl,
                    decoration: InputDecoration(
                      labelText: 'Motivo (opcional)',
                      hintText: 'Ej. Feriado nacional, Conferencia, Aniversario',
                      labelStyle: const TextStyle(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                final client = Supabase.instance.client;
                final messenger = ScaffoldMessenger.of(context);
                final formattedTime = '${(newTime.hourOfPeriod == 0 ? 12 : newTime.hourOfPeriod).toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')} ${newTime.period == DayPeriod.am ? 'AM' : 'PM'}';
                final formattedDate = DateFormat('yyyy-MM-dd').format(newDate);

                await client.from('courses').update({
                  'rescheduled_date': isReprogrammed ? formattedDate : null,
                  'rescheduled_time': isReprogrammed ? formattedTime : null,
                  'rescheduled_reason': isReprogrammed && reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : null,
                }).eq('id', widget.courseId);

                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF16A34A),
                      content: Text(isReprogrammed ? 'Sesión reprogramada guardada exitosamente' : 'Reprogramación desactivada'),
                    ),
                  );
                  if (isReprogrammed) {
                    _selectedDate = newDate;
                  }
                  _loadCourseAttendance();
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleAttendanceOpen() async {
    final client = Supabase.instance.client;
    final dateStr = _formatDateYMD(_selectedDate);
    final nextState = !_attendanceOpen;

    try {
      await client.from('courses').update({
        'attendance_open': nextState,
        'attendance_session_date': nextState ? dateStr : null,
        'attendance_opened_at': nextState ? DateTime.now().toIso8601String() : null,
      }).eq('id', widget.courseId);

      setState(() => _attendanceOpen = nextState);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: nextState ? const Color(0xFF16A34A) : const Color(0xFF1E293B),
            content: Text(
              nextState
                  ? '¡Asistencia habilitada para los alumnos para la sesión $dateStr! Ya pueden marcar.'
                  : 'Asistencia cerrada para los alumnos.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cambiar estado de asistencia: $e'), backgroundColor: AppColors.error),
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

      // Recalculate attendance percentage based on total unique sessions in course
      final allAttRes = await client
          .from('academy_attendance')
          .select('student_id, session_date, status')
          .eq('course_id', widget.courseId);

      final totalSessions = (allAttRes as List)
          .map((a) => a['session_date'].toString())
          .toSet()
          .length;

      final studentMap = <String, List<String>>{};
      for (final r in allAttRes) {
        final stId = r['student_id']?.toString() ?? '';
        final stStatus = r['status']?.toString() ?? 'presente';
        studentMap.putIfAbsent(stId, () => []).add(stStatus);
      }

      for (final s in _students) {
        final stRecords = studentMap[s.id] ?? [];
        final presentOrJust = stRecords.where((st) => st == 'presente' || st == 'justificado').length;
        final pct = totalSessions > 0 ? (presentOrJust / totalSessions) * 100 : 0.0;

        await client
            .from('enrollments')
            .update({'attendance_percentage': double.parse(pct.toStringAsFixed(2))})
            .eq('course_id', widget.courseId)
            .eq('student_id', s.id);
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

    final user = ref.watch(authStateProvider).userProfile;
    final role = user?.role.toLowerCase() ?? '';
    final bool canReprogram = role == 'admin' || role == 'pastor' || role == 'coordinador';

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

                              // Date selector and Reprogramming row
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _selectedDate,
                                        firstDate: DateTime(2025),
                                        lastDate: DateTime.now().add(const Duration(days: 365)),
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
                                  if (canReprogram)
                                    OutlinedButton.icon(
                                      onPressed: _showReprogramSessionDialog,
                                      icon: const Icon(Icons.event_repeat, size: 16, color: Colors.white),
                                      label: const Text('Reprogramar Sesión', style: TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.bold)),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                                      ),
                                    ),
                                ],
                              ),

                              if (_rescheduledDate != null && _rescheduledDate!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.event_repeat, color: Color(0xFFDC2626), size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Sesión Reprogramada: ${_formatDateDisplay(_rescheduledDate!)}${_rescheduledTime != null && _rescheduledTime!.isNotEmpty ? " a las $_rescheduledTime" : ""}${_rescheduledReason != null && _rescheduledReason!.isNotEmpty ? " • Motivo: $_rescheduledReason" : ""}',
                                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF991B1B)),
                                            ),
                                            if (_formatDateYMD(_selectedDate) != _rescheduledDate) ...[
                                              const SizedBox(height: 4),
                                              InkWell(
                                                onTap: () {
                                                  try {
                                                    setState(() => _selectedDate = DateTime.parse(_rescheduledDate!));
                                                    _loadCourseAttendance();
                                                  } catch (_) {}
                                                },
                                                child: Text(
                                                  '👉 Toca aquí para ver/tomar asistencia de esta fecha',
                                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFB91C1C), decoration: TextDecoration.underline),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

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

                        // Switch de Habilitar Asistencia para Alumnos
                        Container(
                          margin: const EdgeInsets.only(top: 14),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: _attendanceOpen
                                ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                                : AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _attendanceOpen ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                              width: _attendanceOpen ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _attendanceOpen ? Icons.radio_button_checked : Icons.how_to_reg,
                                color: _attendanceOpen ? const Color(0xFF16A34A) : AppColors.secondary,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _attendanceOpen ? 'Auto-marcado de alumnos ACTIVO' : 'Auto-marcado de alumnos CERRADO',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _attendanceOpen ? const Color(0xFF15803D) : AppColors.primary,
                                      ),
                                    ),
                                    Text(
                                      _attendanceOpen
                                          ? 'Los alumnos pueden registrar su asistencia de hoy desde la app.'
                                          : 'Habilita si deseas que los alumnos marquen ellos mismos durante la clase.',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: _attendanceOpen ? const Color(0xFF166534) : AppColors.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _attendanceOpen,
                                activeThumbColor: const Color(0xFF16A34A),
                                onChanged: (_) => _toggleAttendanceOpen(),
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
