import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_provider.dart';
import '../../../core/services/resend_email_service.dart';
import '../data/certificate_generator.dart';
import 'asistencia_clase_screen.dart';

class CurriculumSubject {
  final String code;
  final String title;
  final String level;
  final List<String> prerequisites;
  final String duration;

  const CurriculumSubject({
    required this.code,
    required this.title,
    required this.level,
    required this.prerequisites,
    required this.duration,
  });
}

const List<CurriculumSubject> abcCurriculum = [
  // --- NIVEL INICIAL ---
  CurriculumSubject(code: 'A01', title: 'Vida Abundante', level: 'inicial', prerequisites: [], duration: '4 meses'),
  CurriculumSubject(code: 'A02', title: 'Comprometidos con Cristo y su iglesia', level: 'inicial', prerequisites: ['A01'], duration: '2 meses'),
  CurriculumSubject(code: 'A03', title: 'Comunión profunda', level: 'inicial', prerequisites: ['A02'], duration: '2 meses'),

  // --- NIVEL BÁSICO --- (Requiere Inicial culminado. B03 GP2 requiere B02 GP1; los demás son abiertos en básico)
  CurriculumSubject(code: 'B01', title: 'Evangelismo personal', level: 'basico', prerequisites: ['A03'], duration: '2 meses'),
  CurriculumSubject(code: 'B02', title: 'Discipulado de GP 1', level: 'basico', prerequisites: ['A03'], duration: '2 meses'),
  CurriculumSubject(code: 'B03', title: 'Discipulado de GP 2', level: 'basico', prerequisites: ['B02'], duration: '2 meses'),
  CurriculumSubject(code: 'B04', title: 'Descubriendo mis dones espirituales', level: 'basico', prerequisites: ['A03'], duration: '2 meses'),
  CurriculumSubject(code: 'B05', title: 'Panorama bíblico', level: 'basico', prerequisites: ['A03'], duration: '2 meses'),

  // --- NIVEL INTERMEDIO --- (Requiere Básico culminado. Secuenciales: C05 requiere C04; C09 requiere C08)
  CurriculumSubject(code: 'C01', title: '¿Cómo estudiar la biblia?', level: 'intermedio', prerequisites: ['B01'], duration: '2 meses'),
  CurriculumSubject(code: 'C02', title: 'Sectas', level: 'intermedio', prerequisites: ['B01'], duration: '2 meses'),
  CurriculumSubject(code: 'C03', title: 'Espíritu Santo', level: 'intermedio', prerequisites: ['B01'], duration: '2 meses'),
  CurriculumSubject(code: 'C04', title: 'Efesios - 1 Parte', level: 'intermedio', prerequisites: ['B01'], duration: '2 meses'),
  CurriculumSubject(code: 'C05', title: 'Efesios – 2 Parte', level: 'intermedio', prerequisites: ['C04'], duration: '2 meses'),
  CurriculumSubject(code: 'C06', title: 'Mayordomía Cristiana', level: 'intermedio', prerequisites: ['B01'], duration: '2 meses'),
  CurriculumSubject(code: 'C07', title: 'Bases bíblica de la misión', level: 'intermedio', prerequisites: ['B01'], duration: '2 meses'),
  CurriculumSubject(code: 'C08', title: '1 Corintios – 1 Parte', level: 'intermedio', prerequisites: ['B01'], duration: '2 meses'),
  CurriculumSubject(code: 'C09', title: '1 Corintios – 2 Parte', level: 'intermedio', prerequisites: ['C08'], duration: '2 meses'),
  CurriculumSubject(code: 'C10', title: 'Romanos', level: 'intermedio', prerequisites: ['B01'], duration: '2 meses'),

  // --- NIVEL AVANZADO --- (Requiere Intermedio culminado. Secuenciales: ETE 1->6, Viajes 1->3, Pentateuco I->II)
  CurriculumSubject(code: 'D01', title: 'ETE 1', level: 'avanzado', prerequisites: ['C10'], duration: '3 meses'),
  CurriculumSubject(code: 'D02', title: 'ETE 2', level: 'avanzado', prerequisites: ['D01'], duration: '3 meses'),
  CurriculumSubject(code: 'D03', title: 'ETE 3', level: 'avanzado', prerequisites: ['D02'], duration: '3 meses'),
  CurriculumSubject(code: 'D04', title: 'ETE 4', level: 'avanzado', prerequisites: ['D03'], duration: '3 meses'),
  CurriculumSubject(code: 'D05', title: 'ETE 5', level: 'avanzado', prerequisites: ['D04'], duration: '3 meses'),
  CurriculumSubject(code: 'D06', title: 'ETE 6', level: 'avanzado', prerequisites: ['D05'], duration: '3 meses'),
  CurriculumSubject(code: 'D07', title: 'Viajes de Pablo 1', level: 'avanzado', prerequisites: ['C10'], duration: '3 meses'),
  CurriculumSubject(code: 'D08', title: 'Viajes de Pablo 2', level: 'avanzado', prerequisites: ['D07'], duration: '3 meses'),
  CurriculumSubject(code: 'D09', title: 'Viajes de Pablo 3', level: 'avanzado', prerequisites: ['D08'], duration: '3 meses'),
  CurriculumSubject(code: 'D10', title: 'Hebreos', level: 'avanzado', prerequisites: ['C10'], duration: '3 meses'),
  CurriculumSubject(code: 'D12', title: 'Pentateuco I', level: 'avanzado', prerequisites: ['C10'], duration: '3 meses'),
  CurriculumSubject(code: 'D13', title: 'Pentateuco II', level: 'avanzado', prerequisites: ['D12'], duration: '3 meses'),

];

int getMaxAllowedAbsences(int totalSessions, [dynamic customMax]) {
  if (customMax != null) {
    final parsed = int.tryParse(customMax.toString());
    if (parsed != null && parsed > 0) return parsed;
  }
  if (totalSessions <= 0) return 0;
  if (totalSessions <= 4) return 1;
  if (totalSessions <= 8) return 2;
  if (totalSessions <= 12) return 3;
  return (totalSessions * 0.25).floor();
}

class CourseSessionInfo {
  final int sessionNumber;
  final int totalSessions;
  final DateTime date;
  final String time;
  final bool isReprogrammed;
  final String? reprogrammedReason;
  final bool isToday;
  final bool isCompleted;

  CourseSessionInfo({
    required this.sessionNumber,
    required this.totalSessions,
    required this.date,
    required this.time,
    this.isReprogrammed = false,
    this.reprogrammedReason,
    this.isToday = false,
    this.isCompleted = false,
  });

  String get formattedDate => DateFormat('dd/MM/yyyy').format(date);

  String get fullDateDisplay {
    const dayNames = {
      DateTime.monday: 'Lunes',
      DateTime.tuesday: 'Martes',
      DateTime.wednesday: 'Miércoles',
      DateTime.thursday: 'Jueves',
      DateTime.friday: 'Viernes',
      DateTime.saturday: 'Sábado',
      DateTime.sunday: 'Domingo',
    };
    const monthNames = {
      1: 'Enero', 2: 'Febrero', 3: 'Marzo', 4: 'Abril',
      5: 'Mayo', 6: 'Junio', 7: 'Julio', 8: 'Agosto',
      9: 'Setiembre', 10: 'Octubre', 11: 'Noviembre', 12: 'Diciembre',
    };
    final dayStr = dayNames[date.weekday] ?? '';
    final monthStr = monthNames[date.month] ?? '';
    return '$dayStr, ${date.day} de $monthStr';
  }
}

class ScheduleParser {
  static final _dayMap = {
    'lunes': 1,
    'martes': 2,
    'miercoles': 3,
    'miércoles': 3,
    'jueves': 4,
    'viernes': 5,
    'sabado': 6,
    'sábado': 6,
    'domingo': 7,
  };

  static int? parseDay(String scheduleStr) {
    final lower = scheduleStr.toLowerCase();
    for (final entry in _dayMap.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  static int? parseTimeInMinutes(String scheduleStr) {
    final regex = RegExp(r'(\d{1,2}):(\d{2})\s*(am|pm)?', caseSensitive: false);
    final match = regex.firstMatch(scheduleStr);
    if (match == null) return null;

    int hour = int.tryParse(match.group(1) ?? '') ?? 0;
    final int minute = int.tryParse(match.group(2) ?? '') ?? 0;
    final String? amPm = match.group(3)?.toLowerCase();

    if (amPm != null) {
      if (amPm == 'pm' && hour < 12) {
        hour += 12;
      } else if (amPm == 'am' && hour == 12) {
        hour = 0;
      }
    }
    return hour * 60 + minute;
  }

  static bool doSchedulesConflict(String schedA, String schedB) {
    if (schedA.trim().isEmpty || schedB.trim().isEmpty) return false;

    final dayA = parseDay(schedA);
    final dayB = parseDay(schedB);

    if (dayA != null && dayB != null && dayA != dayB) {
      return false;
    }

    if (dayA != null && dayB != null && dayA == dayB) {
      final timeA = parseTimeInMinutes(schedA);
      final timeB = parseTimeInMinutes(schedB);

      if (timeA != null && timeB != null) {
        final diff = (timeA - timeB).abs();
        return diff < 90;
      }
      return true;
    }

    return schedA.trim().toLowerCase() == schedB.trim().toLowerCase();
  }
}

class AcademiaScreen extends ConsumerStatefulWidget {
  const AcademiaScreen({super.key});

  @override
  ConsumerState<AcademiaScreen> createState() => _AcademiaScreenState();
}

class _AcademiaScreenState extends ConsumerState<AcademiaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _tabControllerInitialized = false;
  String _activeCycle = '2026-III';
  List<Map<String, dynamic>> _offeredCourses = [];
  List<Map<String, dynamic>> _userEnrollments = [];
  List<Map<String, dynamic>> _approvedSubjects = [];
  List<Map<String, dynamic>> _studentAttendanceList = [];
  int _activeCourseTotalSessions = 0;
  String? _selectedActiveCourseId;
  final Map<String, int> _courseTotalSessions = {};
  bool _loading = true;
  bool _initialLoadDone = false;
  RealtimeChannel? _academiaChannel;
  String _selectedModality = 'todos'; // 'todos', 'presencial', 'virtual'

  // Teacher Panel States
  List<Map<String, dynamic>> _teacherCourses = [];
  String? _selectedTeacherCourseId;
  List<Map<String, dynamic>> _courseStudents = [];
  bool _loadingStudents = false;
  final Map<String, TextEditingController> _gradeControllers = {};
  bool _savingGrades = false;

  // Material upload state
  final TextEditingController _materialTitleController = TextEditingController();
  final TextEditingController _materialUrlController = TextEditingController();
  PlatformFile? _selectedMaterialFile;
  bool _savingMaterial = false;

  // Coordinator States
  List<Map<String, dynamic>> _allCycles = [];
  List<Map<String, dynamic>> _teachersList = [];
  List<Map<String, dynamic>> _allReportsList = [];
  List<Map<String, dynamic>> _pendingSpecialRequests = [];
  String _coordSubTab = 'dashboard'; // 'dashboard', 'cycles', 'courses', 'grades', 'requests'
  String _statsCycle = '2026-III';
  String _gradesCycle = '2026-III';
  String _coursesCycle = '2026-III';

  // Attendance & Network Report Tab State
  String _attendanceCycle = '2026-III';
  String _attendanceSubView = 'cursos'; // 'cursos', 'redes'
  String _selectedNetworkFilter = 'todas';
  List<Map<String, dynamic>> _attendanceReportData = [];
  List<Map<String, dynamic>> _networkReportData = [];
  Map<String, dynamic> _attendanceGeneralSummary = {};
  bool _loadingAttendanceReport = false;
  String? _expandedAttendanceCourseId;
  String? _expandedNetworkId;
  String _networkMemberView = 'matriculados'; // 'matriculados', 'no_matriculados'

  final Map<String, String> _levelNames = const {
    'inicial': 'Nivel Inicial',
    'basico': 'Nivel Básico',
    'intermedio': 'Nivel Intermedio',
    'avanzado': 'Nivel Avanzado',
    'especial': 'Cursos Especiales',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    try {
      final client = Supabase.instance.client;
      _academiaChannel = client
          .channel('public:academia_realtime')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'courses',
            callback: (_) {
              if (mounted) _loadData(isSilent: true);
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'academy_cycles',
            callback: (_) {
              if (mounted) _loadData(isSilent: true);
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'enrollments',
            callback: (_) {
              if (mounted) _loadData(isSilent: true);
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'academy_attendance',
            callback: (_) {
              if (mounted) _loadData(isSilent: true);
            },
          )
          .subscribe();
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_academiaChannel != null) {
      Supabase.instance.client.removeChannel(_academiaChannel!);
    }
    if (_tabControllerInitialized) {
      _tabController.dispose();
    }
    for (final c in _gradeControllers.values) {
      c.dispose();
    }
    _materialTitleController.dispose();
    _materialUrlController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getActiveEnrollments() {
    return _userEnrollments.where((e) {
      final course = e['courses'];
      if (course == null) return false;
      if (e['status'] == 'pendiente') return false;

      final courseCycle = course['cycle']?.toString() ?? '';
      if (_activeCycle.isNotEmpty && courseCycle == _activeCycle) {
        return true;
      }
      if (course['is_active'] == true) {
        return true;
      }
      return false;
    }).toList();
  }

  bool _isUserEnrolledInActiveCycle() {
    return _getActiveEnrollments().isNotEmpty;
  }

  Map<String, dynamic>? _getSelectedActiveEnrollment() {
    final list = _getActiveEnrollments();
    if (list.isEmpty) return null;
    if (_selectedActiveCourseId != null) {
      final match = list.where(
        (e) => (e['course_id']?.toString() == _selectedActiveCourseId || e['courses']?['id']?.toString() == _selectedActiveCourseId),
      ).toList();
      if (match.isNotEmpty) return match.first;
    }
    // Prefer ongoing active course if available
    final ongoing = list.where((e) => e['courses']?['is_active'] == true && e['is_approved'] != true).toList();
    if (ongoing.isNotEmpty) return ongoing.first;
    return list.first;
  }

  Map<String, dynamic>? _getActiveEnrollment() {
    return _getSelectedActiveEnrollment();
  }

  Map<String, dynamic>? _getScheduleConflict(Map<String, dynamic> candidateCourse) {
    final activeEnrs = _getActiveEnrollments();
    final candSched = candidateCourse['schedule']?.toString() ?? '';
    if (candSched.isEmpty) return null;

    for (final enr in activeEnrs) {
      final c = enr['courses'] as Map<String, dynamic>?;
      if (c == null) continue;
      if (c['id']?.toString() == candidateCourse['id']?.toString()) continue;

      final existSched = c['schedule']?.toString() ?? '';
      if (ScheduleParser.doSchedulesConflict(candSched, existSched)) {
        return {
          'conflictingTitle': c['title'] ?? c['code'] ?? 'Otro curso',
          'conflictingSchedule': existSched,
        };
      }
    }
    return null;
  }

  Map<String, dynamic>? _getPendingEnrollment() {
    try {
      return _userEnrollments.firstWhere((e) {
        if (e['status'] != 'pendiente') return false;
        final course = e['courses'];
        if (course == null) return false;
        final isCourseActive = course['is_active'] == true;
        if (!isCourseActive) return false;

        final courseCycle = course['cycle']?.toString() ?? '';
        final cycleInfo = _allCycles.firstWhere(
          (c) => c['cycle'] == courseCycle,
          orElse: () => {},
        );
        if (cycleInfo.isNotEmpty && cycleInfo['status'] == 'cerrado') {
          return false;
        }

        return true;
      });
    } catch (_) {
      return null;
    }
  }

  bool _isEnrollmentOpen([String? cycleName]) {
    final cycleToCheck = cycleName ?? _activeCycle;
    if (cycleToCheck.isEmpty) return false;
    final cycleMap = _allCycles.firstWhere(
      (c) => c['cycle']?.toString().toUpperCase() == cycleToCheck.toUpperCase(),
      orElse: () => <String, dynamic>{},
    );
    if (cycleMap.isEmpty) return false;
    if (cycleMap['status'] != 'abierto') return false;
    return cycleMap['enrollment_open'] != false;
  }

  int _calculateTabCount(dynamic user) {
    final isEnrolled = _isUserEnrolledInActiveCycle();
    // If enrolled: [Mis Cursos, Matrícula ABC, Mi Historial] = 3
    // If not enrolled: [Matrícula ABC, Mi Historial] = 2
    int count = isEnrolled ? 3 : 2;
    if (user != null) {
      if (user.isTeacher || user.isPastor) count++; // Panel Docente
      if (user.isAcademyCoordinator || user.isPastor) count++; // Coordinación
      if (user.isAcademyCoordinator || user.isPastor) count++; // Reporte Asistencias y Redes (Solo Coordinación, Pastor y Admin)
    }
    return count;
  }

  Future<void> _loadData({bool isSilent = false}) async {
    if (!_initialLoadDone && !isSilent) {
      setState(() => _loading = true);
    }
    final client = Supabase.instance.client;
    final user = ref.read(authStateProvider).userProfile;

    try {
      // 1. Fetch active cycles
      final cycleRes = await client
          .from('academy_cycles')
          .select()
          .order('cycle', ascending: false);

      _allCycles = List<Map<String, dynamic>>.from(cycleRes);

      if (_allCycles.isNotEmpty) {
        final openCycle = _allCycles.firstWhere(
          (c) => c['status'] == 'abierto',
          orElse: () => <String, dynamic>{},
        );
        _activeCycle = openCycle.isNotEmpty ? (openCycle['cycle']?.toString() ?? '') : '';
        final fallback = _activeCycle.isNotEmpty ? _activeCycle : (_allCycles.first['cycle']?.toString() ?? '');
        _statsCycle = fallback;
        _gradesCycle = fallback;
        _attendanceCycle = fallback;
        _coursesCycle = fallback;
      } else {
        _activeCycle = '';
      }

      // 2. Fetch opened courses for active cycle (if any)
      if (_activeCycle.isNotEmpty) {
        final coursesRes = await client
            .from('courses')
            .select('*, profiles:teacher_id(first_name, last_name)')
            .eq('cycle', _activeCycle)
            .eq('is_active', true);

        _offeredCourses = List<Map<String, dynamic>>.from(coursesRes);
      } else {
        _offeredCourses = [];
      }

      // 3. User specific data
      if (user != null) {
        final enrollRes = await client
            .from('enrollments')
            .select('*, courses(*, profiles:teacher_id(first_name, last_name))')
            .eq('student_id', user.id);
        _userEnrollments = List<Map<String, dynamic>>.from(enrollRes);

        final approvedRes = await client
            .from('academy_approved_subjects')
            .select()
            .eq('student_id', user.id);
        _approvedSubjects = List<Map<String, dynamic>>.from(approvedRes);

        // User attendance sessions
        final attRes = await client
            .from('academy_attendance')
            .select('course_id, session_date, status, marked_at, created_at')
            .eq('student_id', user.id)
            .order('session_date', ascending: false);
        _studentAttendanceList = List<Map<String, dynamic>>.from(attRes);

        // Compute total distinct sessions for active courses
        final activeList = _getActiveEnrollments();
        _courseTotalSessions.clear();
        for (final enr in activeList) {
          final cId = enr['courses']?['id']?.toString();
          if (cId != null) {
            try {
              final sessRes = await client
                  .from('academy_attendance')
                  .select('session_date')
                  .eq('course_id', cId);
              final uniqueDates = (sessRes as List).map((s) => s['session_date'].toString()).toSet();
              _courseTotalSessions[cId] = uniqueDates.length;
            } catch (_) {
              _courseTotalSessions[cId] = 0;
            }
          }
        }

        final sel = _getSelectedActiveEnrollment();
        if (sel != null && sel['courses'] != null) {
          final cId = sel['courses']['id']?.toString();
          _activeCourseTotalSessions = _courseTotalSessions[cId] ?? 0;
          if (_selectedActiveCourseId == null || !activeList.any((e) => e['courses']?['id']?.toString() == _selectedActiveCourseId)) {
            _selectedActiveCourseId = cId;
          }
        } else {
          _activeCourseTotalSessions = 0;
        }

        // Teacher courses (All active courses for this teacher across cycles)
        if (user.isTeacher || user.isPastor) {
          final tCoursesRes = await client
              .from('courses')
              .select('id, code, title, level, schedule, cycle, materials, is_active, attendance_open, attendance_session_date, max_absences')
              .eq('teacher_id', user.id)
              .order('created_at', ascending: false);
          _teacherCourses = List<Map<String, dynamic>>.from(tCoursesRes);
          if (_teacherCourses.isNotEmpty) {
            if (_selectedTeacherCourseId == null || !_teacherCourses.any((c) => c['id'] == _selectedTeacherCourseId)) {
              _selectedTeacherCourseId = _teacherCourses.first['id'];
            }
            await _loadStudentsForTeacherCourse(_selectedTeacherCourseId!);
          }
        }

        // Attendance & Network report for Coordinator, Pastor & Admin
        if (user.isAcademyCoordinator || user.isPastor) {
          await _fetchDetailedAttendanceReport(_attendanceCycle);
        }

        // Coordinator & Support data
        if (user.isAcademyCoordinator || user.isPastor || user.rolesList.contains('apoyo_abc')) {
          final tListRes = await client
              .from('profiles')
              .select('id, first_name, last_name, role')
              .order('first_name');
          final allProfiles = List<Map<String, dynamic>>.from(tListRes);
          _teachersList = allProfiles.where((p) {
            final role = (p['role'] ?? '').toString().toLowerCase();
            final roles = role.split(',').map((r) => r.trim()).toList();
            return roles.contains('maestro') ||
                roles.contains('instructor_abc') ||
                roles.contains('instructor_temporal') ||
                roles.contains('coordinador_academia') ||
                roles.contains('pastor') ||
                roles.contains('admin');
          }).toList();

          try {
            final reqsRes = await client
                .from('enrollments')
                .select('*, profiles:student_id(id, first_name, last_name, dni, phone, email), courses(*, profiles:teacher_id(first_name, last_name))')
                .eq('status', 'pendiente')
                .order('created_at', ascending: false);
            _pendingSpecialRequests = List<Map<String, dynamic>>.from(reqsRes);
          } catch (_) {
            _pendingSpecialRequests = [];
          }

          await _fetchCoordinatorReports();
        }
      }

      // Default modality selection: 'todos'
      _selectedModality = 'todos';

      final tabCount = _calculateTabCount(user);
      final prevIndex = _tabControllerInitialized ? _tabController.index : 0;
      if (!_tabControllerInitialized || _tabController.length != tabCount) {
        if (_tabControllerInitialized) {
          _tabController.dispose();
        }
        _tabController = TabController(
          length: tabCount,
          vsync: this,
          initialIndex: prevIndex.clamp(0, tabCount > 0 ? tabCount - 1 : 0),
        );
        _tabControllerInitialized = true;
      }

      _initialLoadDone = true;
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      _initialLoadDone = true;
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchCoordinatorReports() async {
    final client = Supabase.instance.client;
    try {
      final dbCourses = await client
          .from('courses')
          .select('id, code, title, level, cycle, is_active, is_virtual, schedule, classroom, teacher_id, virtual_platform, virtual_link, book_title, book_store_info, is_special, requires_approval, rescheduled_date, rescheduled_time, rescheduled_reason, start_date, manually_opened, profiles:teacher_id(first_name, last_name)')
          .order('cycle', ascending: false);

      final enrollments = await client
          .from('enrollments')
          .select('id, course_id, final_grade, attendance_percentage, is_approved, profiles:student_id(id, first_name, last_name, dni, phone)');

      final mapped = <Map<String, dynamic>>[];
      for (final c in dbCourses) {
        final teacher = c['profiles'];
        final teacherName = teacher != null
            ? '${teacher['first_name'] ?? ''} ${teacher['last_name'] ?? ''}'.trim()
            : 'Sin docente asignado';

        final matchingStudents = (enrollments as List)
            .where((e) => e['course_id'] == c['id'])
            .map((e) {
              final p = e['profiles'];
              return {
                'enrollmentId': e['id'],
                'studentId': p?['id'],
                'name': p != null ? '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim() : 'Estudiante',
                'dni': p?['dni'] ?? 'No registrado',
                'phone': p?['phone'] ?? '',
                'grade': e['final_grade'],
                'attendance': e['attendance_percentage'],
                'isApproved': e['is_approved'] == true,
              };
            })
            .toList();

        mapped.add({
          'id': c['id'],
          'code': c['code'],
          'title': c['title'],
          'level': c['level'],
          'cycle': c['cycle'],
          'schedule': c['schedule'] ?? '',
          'classroom': c['classroom'] ?? '',
          'isVirtual': c['is_virtual'] == true,
          'isActive': c['is_active'] ?? true,
          'teacherId': c['teacher_id'],
          'teacherName': teacherName,
          'virtualPlatform': c['virtual_platform'],
          'virtualLink': c['virtual_link'],
          'bookTitle': c['book_title'],
          'bookStoreInfo': c['book_store_info'],
          'isSpecial': c['is_special'] == true,
          'requiresApproval': c['requires_approval'] == true,
          'rescheduledDate': c['rescheduled_date'],
          'rescheduledTime': c['rescheduled_time'],
          'rescheduledReason': c['rescheduled_reason'],
          'start_date': c['start_date'],
          'startDate': c['start_date'],
          'manually_opened': c['manually_opened'] == true,
          'manuallyOpened': c['manually_opened'] == true,
          'students': matchingStudents,
        });
      }

      _allReportsList = mapped;
    } catch (_) {}
  }

  Future<void> _showTeacherManualEnrollDialog(Map<String, dynamic> course) async {
    final courseTitle = course['title'] ?? 'Curso';
    final courseCode = course['code'] ?? '';
    final cycle = course['cycle'] ?? _activeCycle;

    final enrolledIds = _courseStudents.map((s) => s['student_id']?.toString()).toSet();

    List<Map<String, dynamic>> allMembers = [];
    bool isLoading = true;
    String searchQuery = '';

    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('profiles')
          .select('id, first_name, last_name, dni, email, phone, role')
          .order('first_name', ascending: true);
      allMembers = List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint('Error loading profiles for manual enrollment: $e');
    }
    isLoading = false;

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = allMembers.where((m) {
              final id = m['id']?.toString() ?? '';
              if (enrolledIds.contains(id)) return false;
              final name = '${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'.toLowerCase();
              final dni = (m['dni'] ?? '').toString().toLowerCase();
              final email = (m['email'] ?? '').toString().toLowerCase();
              final q = searchQuery.toLowerCase().trim();
              if (q.isEmpty) return true;
              return name.contains(q) || dni.contains(q) || email.contains(q);
            }).toList();

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
                        child: const Icon(Icons.person_add_alt_1, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Matricular Alumno Directo',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              '$courseCode: $courseTitle (Sin prerrequisitos)',
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
                  TextField(
                    onChanged: (val) {
                      setModalState(() => searchQuery = val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre, apellido o DNI...',
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.primary),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
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
                  const SizedBox(height: 12),
                  Text(
                    '${filtered.length} hermanos disponibles para matricular',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'No se encontraron alumnos disponibles.',
                                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.secondary),
                                ),
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final member = filtered[idx];
                                  final name = '${member['first_name'] ?? ''} ${member['last_name'] ?? ''}'.trim();
                                  final dni = member['dni']?.toString() ?? 'S/DNI';
                                  final email = member['email']?.toString() ?? '';

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                    ),
                                    title: Text(
                                      name.isNotEmpty ? name : 'Sin Nombre',
                                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(
                                      'DNI: $dni ${email.isNotEmpty ? "• $email" : ""}',
                                      style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: () async {
                                        final rootNav = Navigator.of(ctx);
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (c) => AlertDialog(
                                            title: const Text('Confirmar Matrícula'),
                                            content: Text('¿Deseas matricular a "$name" en $courseCode: $courseTitle (Ciclo $cycle)?'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(c, true),
                                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                                child: const Text('Matricular'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          rootNav.pop();
                                          await _enrollStudentDirectly(member, course);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: const Text('Matricular', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _enrollStudentDirectly(Map<String, dynamic> member, Map<String, dynamic> course) async {
    try {
      final client = Supabase.instance.client;
      await client.from('enrollments').insert({
        'student_id': member['id'],
        'course_id': course['id'],
        'attendance_percentage': 100,
        'final_grade': null,
        'is_approved': false,
        'status': 'aprobado',
      });

      final email = member['email']?.toString();
      final name = '${member['first_name'] ?? ''} ${member['last_name'] ?? ''}'.trim();
      if (email != null && email.contains('@') && !email.endsWith('@alianzachaclacayo.pe')) {
        final teacher = course['profiles'];
        final teacherName = teacher != null
            ? '${teacher['first_name'] ?? ''} ${teacher['last_name'] ?? ''}'.trim()
            : 'Secretaría Académica';

        ResendEmailService.sendEnrollmentConfirmation(
          to: email,
          studentName: name.isNotEmpty ? name : 'Alumno',
          courseTitle: course['title'] ?? 'Curso ABC',
          courseCode: course['code'] ?? '',
          schedule: course['schedule'] ?? 'Horario regular',
          level: _levelNames[course['level']] ?? (course['level'] ?? 'Inicial'),
          teacherName: teacherName,
          cycleCode: course['cycle'] ?? _activeCycle,
          isVirtual: course['is_virtual'] == true,
          virtualLink: course['virtual_link']?.toString(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16A34A),
            content: Text('¡Alumno $name matriculado exitosamente en ${course['title']}!'),
          ),
        );
        _loadStudentsForTeacherCourse(course['id']);
        _loadData(isSilent: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error al matricular alumno: $e')),
        );
      }
    }
  }

  Future<void> _toggleCourseAttendanceOpen(Map<String, dynamic> course, bool open) async {
    final client = Supabase.instance.client;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      await client.from('courses').update({
        'attendance_open': open,
        'attendance_session_date': open ? todayStr : null,
        'attendance_opened_at': open ? DateTime.now().toIso8601String() : null,
      }).eq('id', course['id']);

      if (mounted) {
        setState(() {
          course['attendance_open'] = open;
          course['attendance_session_date'] = open ? todayStr : null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: open ? const Color(0xFF16A34A) : AppColors.secondary,
            content: Text(
              open
                  ? '¡Asistencia habilitada para los alumnos en la clase de hoy ($todayStr)!'
                  : 'Asistencia cerrada para los alumnos.',
            ),
          ),
        );
        _loadData(isSilent: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error al cambiar asistencia: $e')),
        );
      }
    }
  }

  Future<void> _openCourseByCoordinator(Map<String, dynamic> course) async {
    final title = course['title'] ?? 'Curso';
    final code = course['code'] ?? '';
    final startDate = _getCourseStartDate(course);
    final dateStr = startDate != null ? DateFormat('dd/MM/yyyy').format(startDate) : 'Hoy';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.play_circle_fill_rounded, color: Color(0xFF16A34A)),
            SizedBox(width: 8),
            Text('Abrir Curso'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Deseas abrir oficialmente el curso "$code: $title"?',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            const SizedBox(height: 10),
            Text(
              'Fecha de inicio programada: $dateStr.\n\n'
              'Al abrir el curso:\n'
              '• Quedará iniciado y activo en la aplicación.\n'
              '• Se revelarán los datos del docente, materiales y enlaces a los alumnos matriculados.\n'
              '• El docente podrá abrir asistencias y registrar notas.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
            child: const Text('Sí, Abrir Curso'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final client = Supabase.instance.client;
      await client.from('courses').update({
        'is_active': true,
        'manually_opened': true,
      }).eq('id', course['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Curso "$code: $title" abierto correctamente.'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
      await _loadData(isSilent: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir curso: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleCycleEnrollment(Map<String, dynamic> cycleData) async {
    final cycleName = cycleData['cycle']?.toString() ?? '';
    final isCurrentlyOpen = cycleData['enrollment_open'] != false;
    final newStatus = !isCurrentlyOpen;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              newStatus ? Icons.how_to_reg : Icons.lock_clock,
              color: newStatus ? const Color(0xFF16A34A) : const Color(0xFFD97706),
            ),
            const SizedBox(width: 8),
            Text(newStatus ? '¿Abrir Inscripciones?' : '¿Cerrar Inscripciones?'),
          ],
        ),
        content: Text(
          newStatus
              ? '¿Deseas abrir las inscripciones para el ciclo "$cycleName"?\n\nLos miembros de la iglesia podrán volver a matricularse en los cursos disponibles.'
              : '¿Deseas cerrar las inscripciones para el ciclo "$cycleName"?\n\nLos alumnos ya inscritos seguirán teniendo acceso a sus clases y materiales normalmente, pero no se permitirán nuevas matrículas.',
          style: GoogleFonts.inter(fontSize: 12.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? const Color(0xFF16A34A) : const Color(0xFFD97706),
            ),
            child: Text(newStatus ? 'Sí, Abrir Inscripciones' : 'Sí, Cerrar Inscripciones'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final client = Supabase.instance.client;
      await client
          .from('academy_cycles')
          .update({'enrollment_open': newStatus})
          .eq('cycle', cycleName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus
                ? 'Inscripciones abiertas para el ciclo "$cycleName".'
                : 'Inscripciones cerradas para el ciclo "$cycleName".'),
            backgroundColor: newStatus ? const Color(0xFF16A34A) : const Color(0xFFD97706),
          ),
        );
      }
      await _loadData(isSilent: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar estado de inscripciones: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _closeCourseByCoordinator(Map<String, dynamic> course) async {
    final courseId = course['id'];
    final courseCode = course['code'] ?? '';
    final courseTitle = course['title'] ?? '';
    final courseCycle = course['cycle'] ?? _activeCycle;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.lock_clock, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Cerrar Curso'),
          ],
        ),
        content: Text(
          '¿Estás seguro de cerrar el curso "$courseCode: $courseTitle" ($courseCycle)?\n\n'
          '• El curso se marcará como cerrado/inactivo y la asistencia se cerrará.\n'
          '• Se evaluará la relación de clases dictadas: los alumnos que superen el límite permitido de inasistencias desaprobarán por faltas.\n'
          '• Los alumnos con nota final >= 14 y asistencia dentro del límite serán aprobados formalmente y registrados en su historial.',
          style: GoogleFonts.inter(fontSize: 12.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
            child: const Text('Sí, Cerrar Curso'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final client = Supabase.instance.client;
    try {
      // 1. Mark course inactive & close attendance
      await client.from('courses').update({
        'is_active': false,
        'attendance_open': false,
      }).eq('id', courseId);

      // 2. Fetch all attendance sessions for this course
      final attRes = await client
          .from('academy_attendance')
          .select('student_id, session_date, status')
          .eq('course_id', courseId);

      final uniqueSessions = (attRes as List).map((a) => a['session_date'].toString()).toSet().toList();
      final totalSessions = uniqueSessions.length;
      final maxAllowed = getMaxAllowedAbsences(totalSessions, course['max_absences']);

      // 3. Fetch enrollments
      final enrollments = await client
          .from('enrollments')
          .select('id, student_id, final_grade, attendance_percentage')
          .eq('course_id', courseId);

      for (final e in enrollments) {
        final g = e['final_grade'];
        final studentId = e['student_id']?.toString();
        if (studentId == null) continue;

        final gNum = g != null ? double.tryParse(g.toString()) ?? 0 : 0;
        final stAtts = (attRes as List).where((a) => a['student_id']?.toString() == studentId).toList();
        final attended = stAtts.where((a) => a['status'] == 'presente' || a['status'] == 'justificado').length;
        final absent = stAtts.where((a) => a['status'] == 'ausente').length;
        final unrecorded = totalSessions - (attended + absent);
        final totalAbsences = absent + (unrecorded > 0 ? unrecorded : 0);
        final pct = totalSessions > 0 ? ((attended / totalSessions) * 100).round() : 0;

        final bool exceeded = totalSessions > 0 && totalAbsences > maxAllowed;

        if (exceeded) {
          await client.from('enrollments').update({
            'is_approved': false,
            'status': 'desaprobado_inasistencias',
            'attendance_percentage': pct,
            'disapproval_reason': 'Desaprobado por superar el límite de inasistencias ($totalAbsences inasistencias de $totalSessions clases dictadas. Límite: $maxAllowed).',
          }).eq('id', e['id']);
        } else {
          final isApproved = gNum >= 14;
          await client.from('enrollments').update({
            'is_approved': isApproved,
            'status': isApproved ? 'aprobado' : 'desaprobado',
            'attendance_percentage': pct,
            'disapproval_reason': isApproved ? null : 'Calificación insuficiente ($gNum/20). Requiere mínimo 14.',
          }).eq('id', e['id']);

          if (isApproved) {
            try {
              await client.from('academy_approved_subjects').upsert({
                'student_id': studentId,
                'subject_code': courseCode,
                'subject_title': courseTitle,
                'level': course['level'] ?? 'inicial',
                'cycle': courseCycle,
                'grade': gNum,
                'approved_at': DateTime.now().toIso8601String(),
              }, onConflict: 'student_id,subject_code');
            } catch (err) {
              debugPrint('Warning upserting approved subject: $err');
            }
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16A34A),
            content: Text('¡Curso "$courseTitle" cerrado y actas finalizadas con éxito!'),
          ),
        );
        _loadData(isSilent: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error al cerrar curso: $e')),
        );
      }
    }
  }

  Future<void> _markMyAttendance() async {
    final enrollment = _getActiveEnrollment();
    if (enrollment == null) return;
    if (enrollment['status'] == 'pendiente') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFD97706),
          content: Text('Tu matrícula está en evaluación. Podrás marcar asistencia una vez aprobada por la Coordinación o Pastoral.'),
        ),
      );
      return;
    }
    final course = enrollment['courses'];
    if (course == null) return;
    final courseId = course['id'];
    final user = ref.read(authStateProvider).userProfile;
    if (user == null) return;

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.how_to_reg, color: Color(0xFF16A34A)),
            SizedBox(width: 8),
            Text('Marcar Asistencia'),
          ],
        ),
        content: Text(
          '¿Deseas registrar tu asistencia a la clase de hoy (${DateFormat("dd/MM/yyyy").format(DateTime.now())}) en "${course['title']}"?',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
            child: const Text('Confirmar Asistencia'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final now = DateTime.now();
    final timeStr = DateFormat('hh:mm a').format(now);
    final dateDisplayStr = DateFormat('dd/MM/yyyy').format(now);

    final client = Supabase.instance.client;
    try {
      // 1. Call database procedure to record attendance with exact timestamp
      await client.rpc('mark_student_attendance', params: {
        'p_course_id': courseId,
        'p_session_date': todayStr,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16A34A),
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('¡Asistencia registrada exitosamente hoy ($dateDisplayStr a las $timeStr)!'),
                ),
              ],
            ),
          ),
        );
        _loadData(isSilent: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error al marcar asistencia: $e')),
        );
      }
    }
  }

  Future<void> _fetchDetailedAttendanceReport(String targetCycle) async {
    setState(() => _loadingAttendanceReport = true);
    final client = Supabase.instance.client;
    try {
      final coursesRes = await client
          .from('courses')
          .select('id, code, title, level, teacher_id, max_absences, profiles:teacher_id(first_name, last_name)')
          .eq('cycle', targetCycle);

      final filteredCourses = List<Map<String, dynamic>>.from(coursesRes);
      final courseIds = filteredCourses.map((c) => c['id'].toString()).toList();

      if (courseIds.isEmpty) {
        setState(() {
          _attendanceReportData = [];
          _networkReportData = [];
          _attendanceGeneralSummary = {};
          _loadingAttendanceReport = false;
        });
        return;
      }

      final enrollRes = await client
          .from('enrollments')
          .select('course_id, attendance_percentage, status, is_approved, disapproval_reason, profiles:student_id(id, first_name, last_name, dni, phone, assigned_network)')
          .inFilter('course_id', courseIds);

      final attRes = await client
          .from('academy_attendance')
          .select('course_id, student_id, session_date, status')
          .inFilter('course_id', courseIds)
          .order('session_date', ascending: true);

      final list = <Map<String, dynamic>>[];
      for (final c in filteredCourses) {
        final cId = c['id'].toString();
        final teacher = c['profiles'];
        final teacherName = teacher != null
            ? '${teacher['first_name'] ?? ''} ${teacher['last_name'] ?? ''}'.trim()
            : 'Sin docente asignado';

        final courseAtt = (attRes as List).where((a) => a['course_id'].toString() == cId).toList();
        final uniqueDates = courseAtt.map((a) => a['session_date'].toString()).toSet().toList()..sort();
        final totalSessions = uniqueDates.length;
        final maxAllowed = getMaxAllowedAbsences(totalSessions, c['max_absences']);

        final courseEnrolled = (enrollRes as List).where((e) => e['course_id'].toString() == cId).toList();

        final studentsList = courseEnrolled.map((e) {
          final p = e['profiles'];
          final stId = p?['id']?.toString() ?? '';
          final stName = p != null ? '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim() : 'Estudiante';
          final stDni = p?['dni']?.toString() ?? 'No registrado';
          final stPhone = p?['phone']?.toString() ?? '';
          final stNetwork = p?['assigned_network']?.toString() ?? '';

          final sessionsMap = <String, String>{};
          for (final a in courseAtt) {
            if (a['student_id'].toString() == stId) {
              sessionsMap[a['session_date'].toString()] = a['status'].toString();
            }
          }

          final attended = sessionsMap.values.where((s) => s == 'presente' || s == 'justificado').length;
          final absent = sessionsMap.values.where((s) => s == 'ausente').length;
          final unrecorded = totalSessions - (attended + absent);
          final totalAbsences = absent + (unrecorded > 0 ? unrecorded : 0);
          final calculatedPct = totalSessions > 0 ? ((attended / totalSessions) * 100).round() : 0;
          final isExceeded = totalSessions > 0 && totalAbsences > maxAllowed;

          return {
            'id': stId,
            'name': stName,
            'dni': stDni,
            'phone': stPhone,
            'network': stNetwork,
            'attendancePercentage': calculatedPct,
            'totalAbsences': totalAbsences,
            'maxAllowed': maxAllowed,
            'isExceeded': isExceeded,
            'status': e['status'],
            'isApproved': e['is_approved'],
            'disapprovalReason': e['disapproval_reason'],
            'sessions': sessionsMap,
          };
        }).toList();

        // 1. CANTIDAD TOTAL DE ASISTENCIAS POR SESIÓN PARA ESTE CURSO
        final sessionStats = uniqueDates.map((sDate) {
          final sessionAtts = courseAtt.where((a) => a['session_date'].toString() == sDate).toList();
          final presentList = <Map<String, dynamic>>[];
          final absentList = <Map<String, dynamic>>[];
          final justifiedList = <Map<String, dynamic>>[];

          for (final st in studentsList) {
            final stId = st['id'].toString();
            final rec = sessionAtts.firstWhere(
              (a) => a['student_id']?.toString() == stId,
              orElse: () => <String, dynamic>{},
            );
            final stInfo = {'name': st['name'], 'dni': st['dni'], 'phone': st['phone']};
            final status = rec['status']?.toString();
            if (status == 'presente') {
              presentList.add(stInfo);
            } else if (status == 'justificado') {
              justifiedList.add(stInfo);
            } else {
              absentList.add(stInfo);
            }
          }
          final totalCount = studentsList.length;
          final attendees = presentList.length + justifiedList.length;
          final pct = totalCount > 0 ? ((attendees / totalCount) * 100).round() : 0;

          return {
            'date': sDate,
            'present': presentList.length,
            'absent': absentList.length,
            'justified': justifiedList.length,
            'total': totalCount,
            'pct': pct,
            'presentStudents': presentList,
            'absentStudents': absentList,
            'justifiedStudents': justifiedList,
          };
        }).toList();

        final avgCourseAtt = studentsList.isNotEmpty
            ? (studentsList.map((s) => (s['attendancePercentage'] as int)).reduce((a, b) => a + b) / studentsList.length).round()
            : 0;

        list.add({
          'id': cId,
          'code': c['code'],
          'title': c['title'],
          'level': c['level'],
          'teacherName': teacherName,
          'maxAbsences': c['max_absences'],
          'sessionsList': uniqueDates,
          'sessionStats': sessionStats,
          'students': studentsList,
          'avgAttendance': avgCourseAtt,
        });
      }

      // 2. CONSOLIDADO GENERAL DEL CICLO
      final allUniqueStudentIds = <String>{};
      final criticalStudents = <Map<String, dynamic>>[];
      int totalStudentAttSum = 0;
      int totalStudentsInCycles = 0;

      for (final course in list) {
        for (final st in (course['students'] as List)) {
          allUniqueStudentIds.add(st['id'].toString());
          totalStudentsInCycles++;
          totalStudentAttSum += (st['attendancePercentage'] as int? ?? 0);
          if (st['isExceeded'] == true || st['status'] == 'desaprobado_inasistencias') {
            criticalStudents.add({
              'courseTitle': course['title'],
              'studentName': st['name'],
              'dni': st['dni'],
              'phone': st['phone'],
              'attendancePct': st['attendancePercentage'],
              'totalAbsences': st['totalAbsences'],
              'maxAllowed': st['maxAllowed'],
              'reason': st['disapprovalReason'] ?? 'Límite de inasistencias superado',
            });
          }
        }
      }

      final globalAttendanceAvg = totalStudentsInCycles > 0
          ? (totalStudentAttSum / totalStudentsInCycles).round()
          : 0;

      final summary = {
        'totalCourses': list.length,
        'totalUniqueStudents': allUniqueStudentIds.length,
        'globalAttendanceAvg': globalAttendanceAvg,
        'criticalStudents': criticalStudents,
      };

      // 3. REPORTE POR REDES (MATRICULADOS Y NO MATRICULADOS)
      final profilesRes = await client
          .from('profiles')
          .select('id, first_name, last_name, dni, phone, assigned_network')
          .order('first_name');
      final allProfiles = List<Map<String, dynamic>>.from(profilesRes);

      const networksConfig = [
        {'id': 'mujeres', 'label': 'Red de Mujeres', 'icon': 'favorite'},
        {'id': 'varones', 'label': 'Red de Varones', 'icon': 'shield'},
        {'id': 'legado', 'label': 'Legado (Jóvenes)', 'icon': 'bolt'},
        {'id': 'dunamis', 'label': 'Dunamis (Jóv. Adultos)', 'icon': 'wb_sunny'},
        {'id': 'matrimonios', 'label': 'Red de Matrimonios', 'icon': 'people'},
        {'id': 'maravillosos', 'label': 'Años Maravillosos', 'icon': 'elderly'},
        {'id': 'free', 'label': 'Free (Adolescentes)', 'icon': 'star'},
        {'id': 'next', 'label': 'NEXT (Pre-adolescentes)', 'icon': 'explore'},
        {'id': 'kids', 'label': 'Generación Kids', 'icon': 'child_care'},
        {'id': 'sin_red', 'label': 'Sin Red Asignada', 'icon': 'person_outline'},
      ];

      final networksReport = <Map<String, dynamic>>[];

      for (final net in networksConfig) {
        final netId = net['id']!;
        final netProfiles = allProfiles.where((p) {
          final netField = (p['assigned_network'] ?? '').toString().trim().toLowerCase();
          if (netId == 'sin_red') {
            return netField.isEmpty || netField == 'sin_red';
          }
          return netField == netId;
        }).toList();

        final enrolledList = <Map<String, dynamic>>[];
        final notEnrolledList = <Map<String, dynamic>>[];

        for (final p in netProfiles) {
          final pId = p['id'].toString();
          final fullName = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();
          final phone = p['phone']?.toString() ?? '';
          final dni = p['dni']?.toString() ?? '';

          final memberEnrollments = (enrollRes as List).where((e) {
            final prof = e['profiles'];
            return prof?['id']?.toString() == pId;
          }).toList();

          if (memberEnrollments.isNotEmpty) {
            final courseTitles = <String>[];
            int attSum = 0;
            for (final me in memberEnrollments) {
              final courseMatch = filteredCourses.firstWhere(
                (c) => c['id'].toString() == me['course_id'].toString(),
                orElse: () => <String, dynamic>{},
              );
              if (courseMatch.isNotEmpty) {
                courseTitles.add(courseMatch['title']?.toString() ?? 'Curso');
              }
              attSum += (me['attendance_percentage'] as num? ?? 100).toInt();
            }
            final avgAtt = (attSum / memberEnrollments.length).round();

            enrolledList.add({
              'id': pId,
              'name': fullName.isEmpty ? 'Hermano/a' : fullName,
              'phone': phone,
              'dni': dni,
              'courses': courseTitles,
              'avgAttendance': avgAtt,
            });
          } else {
            notEnrolledList.add({
              'id': pId,
              'name': fullName.isEmpty ? 'Hermano/a' : fullName,
              'phone': phone,
              'dni': dni,
            });
          }
        }

        final total = netProfiles.length;
        final coverage = total > 0 ? ((enrolledList.length / total) * 100).round() : 0;
        final netAvgAtt = enrolledList.isNotEmpty
            ? (enrolledList.map((e) => e['avgAttendance'] as int).reduce((a, b) => a + b) / enrolledList.length).round()
            : 0;

        networksReport.add({
          'id': netId,
          'label': net['label']!,
          'icon': net['icon']!,
          'total': total,
          'enrolled': enrolledList,
          'notEnrolled': notEnrolledList,
          'coveragePct': coverage,
          'avgAttendance': netAvgAtt,
        });
      }

      setState(() {
        _attendanceReportData = list;
        _attendanceGeneralSummary = summary;
        _networkReportData = networksReport;
        _loadingAttendanceReport = false;
      });
    } catch (e) {
      debugPrint('Error loading detailed attendance report: $e');
      setState(() => _loadingAttendanceReport = false);
    }
  }

  Future<void> _loadStudentsForTeacherCourse(String courseId) async {
    setState(() => _loadingStudents = true);
    final client = Supabase.instance.client;
    try {
      final res = await client
          .from('enrollments')
          .select('id, student_id, final_grade, attendance_percentage, status, is_approved, disapproval_reason, profiles:student_id(id, first_name, last_name, dni, phone)')
          .eq('course_id', courseId);

      final attRes = await client
          .from('academy_attendance')
          .select('student_id, session_date, status')
          .eq('course_id', courseId);

      final uniqueSessions = (attRes as List).map((a) => a['session_date'].toString()).toSet().toList()..sort();
      final totalSessions = uniqueSessions.length;

      final course = _teacherCourses.firstWhere((c) => c['id'] == courseId, orElse: () => {});
      final maxAllowed = getMaxAllowedAbsences(totalSessions, course['max_absences']);

      _courseStudents = List<Map<String, dynamic>>.from(res);
      for (final st in _courseStudents) {
        final stId = st['student_id']?.toString() ?? '';
        final grade = st['final_grade'];
        _gradeControllers[stId] ??= TextEditingController(
          text: grade != null ? grade.toString() : '',
        );

        final stAtts = (attRes as List).where((a) => a['student_id']?.toString() == stId).toList();
        final attended = stAtts.where((a) => a['status'] == 'presente' || a['status'] == 'justificado').length;
        final absent = stAtts.where((a) => a['status'] == 'ausente').length;
        final unrecorded = totalSessions - (attended + absent);
        final totalAbsences = absent + (unrecorded > 0 ? unrecorded : 0);
        final pct = totalSessions > 0 ? ((attended / totalSessions) * 100).round() : 0;
        final isExceeded = totalSessions > 0 && totalAbsences > maxAllowed;

        st['computed_attendance'] = {
          'totalSessions': totalSessions,
          'attended': attended,
          'absent': totalAbsences,
          'pct': pct,
          'maxAllowed': maxAllowed,
          'isExceeded': isExceeded,
        };
      }
      if (mounted) setState(() => _loadingStudents = false);
    } catch (e) {
      if (mounted) setState(() => _loadingStudents = false);
    }
  }

  Future<void> _saveAllGrades({bool closeCourse = false}) async {
    if (_selectedTeacherCourseId == null || _courseStudents.isEmpty) return;

    if (closeCourse) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.lock_clock, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(child: Text('Cerrar Curso y Finalizar Acta')),
            ],
          ),
          content: const Text(
            'Al cerrar el curso:\n\n'
            '• Se cerrará el registro de asistencia.\n'
            '• Se evaluará la relación de inasistencias vs clases dictadas: los alumnos con faltas excedidas desaprobarán automáticamente.\n'
            '• Los alumnos con nota final >= 14 y sin faltas excesivas recibirán su certificado oficial y la materia pasará a su Historial.\n'
            '• El curso se dará por culminado.\n\n'
            '¿Estás seguro de finalizar y cerrar este curso?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
              child: const Text('Sí, Cerrar Curso'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _savingGrades = true);
    final client = Supabase.instance.client;

    try {
      final course = _teacherCourses.firstWhere(
        (c) => c['id'] == _selectedTeacherCourseId,
        orElse: () => <String, dynamic>{},
      );
      final courseCycle = course['cycle']?.toString() ?? _activeCycle;

      // If closing course, fetch all attendance sessions
      List<dynamic> attRes = [];
      int totalSessions = 0;
      int maxAllowed = 0;
      if (closeCourse) {
        final aRes = await client
            .from('academy_attendance')
            .select('student_id, session_date, status')
            .eq('course_id', _selectedTeacherCourseId!);
        attRes = List<dynamic>.from(aRes);
        final uniqueSessions = attRes.map((a) => a['session_date'].toString()).toSet().toList();
        totalSessions = uniqueSessions.length;
        maxAllowed = getMaxAllowedAbsences(totalSessions, course['max_absences']);
      }

      for (final st in _courseStudents) {
        final stId = st['student_id']?.toString() ?? '';
        final controller = _gradeControllers[stId];
        final textVal = controller?.text.trim() ?? '';
        final gradeNum = double.tryParse(textVal);

        if (closeCourse) {
          final stAtts = attRes.where((a) => a['student_id']?.toString() == stId).toList();
          final attended = stAtts.where((a) => a['status'] == 'presente' || a['status'] == 'justificado').length;
          final absent = stAtts.where((a) => a['status'] == 'ausente').length;
          final unrecorded = totalSessions - (attended + absent);
          final totalAbsences = absent + (unrecorded > 0 ? unrecorded : 0);
          final pct = totalSessions > 0 ? ((attended / totalSessions) * 100).round() : 0;

          final bool exceeded = totalSessions > 0 && totalAbsences > maxAllowed;

          if (exceeded) {
            await client.from('enrollments').update({
              'final_grade': gradeNum,
              'is_approved': false,
              'status': 'desaprobado_inasistencias',
              'attendance_percentage': pct,
              'disapproval_reason': 'Desaprobado por superar el límite de inasistencias ($totalAbsences inasistencias de $totalSessions clases dictadas. Límite: $maxAllowed).',
            }).eq('course_id', _selectedTeacherCourseId!).eq('student_id', stId);
          } else {
            final isApproved = gradeNum != null && gradeNum >= 14;
            await client.from('enrollments').update({
              'final_grade': gradeNum,
              'is_approved': isApproved,
              'status': isApproved ? 'aprobado' : 'desaprobado',
              'attendance_percentage': pct,
              'disapproval_reason': isApproved ? null : (gradeNum != null ? 'Calificación insuficiente ($gradeNum/20). Requiere mínimo 14.' : 'Sin calificación registrada.'),
            }).eq('course_id', _selectedTeacherCourseId!).eq('student_id', stId);

            if (isApproved && course.isNotEmpty) {
              try {
                await client.from('academy_approved_subjects').upsert({
                  'student_id': stId,
                  'subject_code': course['code'],
                  'subject_title': course['title'],
                  'level': course['level'] ?? 'inicial',
                  'grade': gradeNum,
                  'cycle': courseCycle,
                  'approved_at': DateTime.now().toIso8601String(),
                }, onConflict: 'student_id,subject_code');
              } catch (err) {
                debugPrint('Warning upserting approved subject in teacher close course: $err');
              }
            }
          }
        } else {
          // Saving grades only without closing course
          if (gradeNum != null) {
            final isApproved = gradeNum >= 14;
            await client
                .from('enrollments')
                .update({
                  'final_grade': gradeNum,
                  'is_approved': isApproved,
                })
                .eq('course_id', _selectedTeacherCourseId!)
                .eq('student_id', stId);

            if (isApproved && course.isNotEmpty) {
              try {
                await client.from('academy_approved_subjects').upsert({
                  'student_id': stId,
                  'subject_code': course['code'],
                  'subject_title': course['title'],
                  'level': course['level'] ?? 'inicial',
                  'grade': gradeNum,
                  'cycle': courseCycle,
                  'approved_at': DateTime.now().toIso8601String(),
                }, onConflict: 'student_id,subject_code');
              } catch (err) {
                debugPrint('Warning upserting approved subject in teacher save grades: $err');
              }
            }
          }
        }
      }

      if (closeCourse) {
        await client
            .from('courses')
            .update({
              'is_active': false,
              'attendance_open': false,
            })
            .eq('id', _selectedTeacherCourseId!);
      }

      if (mounted) {
        setState(() => _savingGrades = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16A34A),
            content: Text(
              closeCourse
                  ? '¡Curso cerrado y finalizado con éxito! Actas y certificados emitidos.'
                  : '¡Acta de notas guardada y sincronizada correctamente!',
            ),
          ),
        );
        _loadData(isSilent: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _savingGrades = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  Future<void> _pickMaterialFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'png', 'jpg', 'jpeg', 'zip'],
      );
      if (result.isNotEmpty) {
        setState(() {
          _selectedMaterialFile = result.first;
          if (_materialTitleController.text.trim().isEmpty) {
            _materialTitleController.text = _selectedMaterialFile!.name;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error al seleccionar archivo: $e')),
        );
      }
    }
  }

  Future<void> _uploadAndAddMaterial() async {
    if (_selectedTeacherCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un curso primero')),
      );
      return;
    }

    final manualUrl = _materialUrlController.text.trim();
    if (_selectedMaterialFile == null && manualUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un archivo o ingresa un enlace')),
      );
      return;
    }

    setState(() => _savingMaterial = true);
    final client = Supabase.instance.client;

    try {
      String fileUrl = manualUrl;
      String fileName = _materialTitleController.text.trim();

      if (_selectedMaterialFile != null) {
        final ext = _selectedMaterialFile!.name.contains('.')
            ? _selectedMaterialFile!.name.split('.').last
            : '';
        final cleanFileName = _selectedMaterialFile!.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
        final storagePath = '$_selectedTeacherCourseId/${DateTime.now().millisecondsSinceEpoch}_$cleanFileName';

        final fileBytes = await _selectedMaterialFile!.readAsBytes();

        await client.storage.from('academy-materials').uploadBinary(
          storagePath,
          fileBytes,
          fileOptions: FileOptions(
            contentType: _getContentType(ext),
            upsert: true,
          ),
        );

        fileUrl = client.storage.from('academy-materials').getPublicUrl(storagePath);
        if (fileName.isEmpty) {
          fileName = _selectedMaterialFile!.name;
        }
      }

      if (fileName.isEmpty) {
        fileName = 'Material de Estudio';
      }

      final course = _teacherCourses.firstWhere((c) => c['id'] == _selectedTeacherCourseId);
      final List existingMaterials = course['materials'] != null && course['materials'] is List
          ? List.from(course['materials'])
          : [];

      existingMaterials.add({
        'name': fileName,
        'url': fileUrl,
        'uploaded_at': DateTime.now().toIso8601String().split('T')[0],
      });

      await client
          .from('courses')
          .update({'materials': existingMaterials})
          .eq('id', _selectedTeacherCourseId!);

      course['materials'] = existingMaterials;
      _materialTitleController.clear();
      _materialUrlController.clear();
      _selectedMaterialFile = null;

      if (mounted) {
        setState(() => _savingMaterial = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF16A34A),
            content: Text('¡Material de estudio subido y publicado con éxito!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _savingMaterial = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error al subir material: $e')),
        );
      }
    }
  }

  Future<void> _deleteCourseMaterial(int materialIndex) async {
    if (_selectedTeacherCourseId == null) return;
    final client = Supabase.instance.client;
    try {
      final course = _teacherCourses.firstWhere((c) => c['id'] == _selectedTeacherCourseId);
      final List existingMaterials = course['materials'] != null && course['materials'] is List
          ? List.from(course['materials'])
          : [];
      if (materialIndex >= 0 && materialIndex < existingMaterials.length) {
        existingMaterials.removeAt(materialIndex);
        await client
            .from('courses')
            .update({'materials': existingMaterials})
            .eq('id', _selectedTeacherCourseId!);
        setState(() {
          course['materials'] = existingMaterials;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF16A34A),
              content: Text('Material eliminado correctamente.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error al eliminar material: $e')),
        );
      }
    }
  }

  String _getContentType(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf': return 'application/pdf';
      case 'png': return 'image/png';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'ppt': return 'application/vnd.ms-powerpoint';
      case 'pptx': return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'xls': return 'application/vnd.ms-excel';
      case 'xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'zip': return 'application/zip';
      default: return 'application/octet-stream';
    }
  }

  DateTime? _getCourseStartDate(Map<String, dynamic>? course) {
    if (course == null) return null;

    if (course['start_date'] != null && course['start_date'].toString().isNotEmpty) {
      try {
        return DateTime.parse(course['start_date'].toString());
      } catch (_) {}
    }

    final cycleName = course['cycle']?.toString().toUpperCase();
    if (cycleName != null && cycleName.isNotEmpty) {
      final cycleMap = _allCycles.firstWhere(
        (c) => c['cycle']?.toString().toUpperCase() == cycleName,
        orElse: () => <String, dynamic>{},
      );
      if (cycleMap.isNotEmpty) {
        final isVirtual = course['is_virtual'] == true;
        final dateStr = isVirtual
            ? (cycleMap['start_date_virtual'] ?? cycleMap['start_date_presencial'])
            : (cycleMap['start_date_presencial'] ?? cycleMap['start_date_virtual']);
        if (dateStr != null && dateStr.toString().isNotEmpty) {
          try {
            return DateTime.parse(dateStr.toString());
          } catch (_) {}
        }
      }
    }

    return null;
  }

  bool _hasCourseStarted(Map<String, dynamic>? course) {
    if (course == null) return false;
    if (course['manually_opened'] == true || course['manuallyOpened'] == true) return true;
    final startDate = _getCourseStartDate(course);
    if (startDate == null) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(startDate.year, startDate.month, startDate.day);
    return !today.isBefore(startDay);
  }

  String _getTeacherDisplayNameForStudent(Map<String, dynamic>? course, Map<String, dynamic>? teacherProfile) {
    final started = _hasCourseStarted(course);
    if (!started) {
      final startDate = _getCourseStartDate(course);
      if (startDate != null) {
        final formatted = DateFormat('dd/MM/yyyy').format(startDate);
        return 'Docente reservado (Se revela al inicio: $formatted)';
      }
      return 'Docente reservado hasta la fecha de inicio';
    }
    if (teacherProfile != null) {
      final name = '${teacherProfile['first_name'] ?? ''} ${teacherProfile['last_name'] ?? ''}'.trim();
      if (name.isNotEmpty) return name;
    }
    return 'Docente asignado por Secretaría';
  }

  CourseSessionInfo _getCurrentSessionInfo(Map<String, dynamic>? course) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const int totalSessions = 8;

    final startDate = _getCourseStartDate(course) ?? today;

    // Extraer hora habitual del schedule
    String regularTime = '09:45 AM';
    final schedule = (course?['schedule'] ?? '').toString();
    final timeMatch = RegExp(r'(\d{1,2}:\d{2}\s*(?:AM|PM)?)', caseSensitive: false).firstMatch(schedule);
    if (timeMatch != null) {
      regularTime = timeMatch.group(1)!;
    }

    // Datos de reprogramación
    final resDateStr = (course?['rescheduled_date'] ?? course?['rescheduledDate'])?.toString();
    final resTimeStr = (course?['rescheduled_time'] ?? course?['rescheduledTime'])?.toString();
    final resReason = (course?['rescheduled_reason'] ?? course?['rescheduledReason'])?.toString();
    DateTime? resDate;
    if (resDateStr != null && resDateStr.isNotEmpty) {
      try {
        resDate = DateTime.parse(resDateStr);
      } catch (_) {}
    }

    // Calcular cuántas sesiones regulares ya pasaron antes de hoy
    int pastCount = 0;
    for (int i = 0; i < totalSessions; i++) {
      final regDate = startDate.add(Duration(days: 7 * i));
      final regDay = DateTime(regDate.year, regDate.month, regDate.day);
      if (regDay.isBefore(today)) {
        pastCount++;
      } else {
        break;
      }
    }

    // Sesión candidata: la próxima que no ha pasado (o la última si concluyó)
    final int currentNum = (pastCount + 1).clamp(1, totalSessions);
    DateTime sessionDate = startDate.add(Duration(days: 7 * (currentNum - 1)));
    String sessionTime = regularTime;
    bool isReprog = false;

    // Si hay una reprogramación activa en fecha vigente (hoy o futura)
    if (resDate != null) {
      final resDay = DateTime(resDate.year, resDate.month, resDate.day);
      if (!resDay.isBefore(today)) {
        sessionDate = resDate;
        sessionTime = (resTimeStr != null && resTimeStr.isNotEmpty) ? resTimeStr : regularTime;
        isReprog = true;
      }
    }

    final sessionDay = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
    final bool isToday = sessionDay.isAtSameMomentAs(today);
    final bool isCompleted = pastCount >= totalSessions && !isReprog;

    return CourseSessionInfo(
      sessionNumber: currentNum,
      totalSessions: totalSessions,
      date: sessionDate,
      time: sessionTime,
      isReprogrammed: isReprog,
      reprogrammedReason: isReprog ? resReason : null,
      isToday: isToday,
      isCompleted: isCompleted,
    );
  }

  List<Map<String, dynamic>> _getEnrollableCourses() {
    final user = ref.read(authStateProvider).userProfile;
    final approvedCodes = _approvedSubjects.map((s) => s['subject_code']?.toString() ?? '').toSet();

    // Qualification by progression
    final bool hasApprovedInicial = approvedCodes.contains('A03') ||
        (approvedCodes.contains('A01') && approvedCodes.contains('A02')) ||
        approvedCodes.any((c) => c.startsWith('B') || c.startsWith('C') || c.startsWith('D'));
    final bool hasApprovedBasico = hasApprovedInicial &&
        (approvedCodes.contains('B01') || approvedCodes.contains('B02') || approvedCodes.contains('B03') || approvedCodes.contains('B04') || approvedCodes.contains('B05') ||
         approvedCodes.any((c) => c.startsWith('C') || c.startsWith('D')));
    final bool hasApprovedIntermedio = hasApprovedBasico &&
        (approvedCodes.contains('C01') || approvedCodes.contains('C10') || approvedCodes.contains('C04') || approvedCodes.contains('C08') ||
         approvedCodes.any((c) => c.startsWith('D')));

    final filtered = _offeredCourses.where((c) {
      if (user != null && c['teacher_id'] == user.id) {
        return false;
      }

      // Filter by modality: 'todos', 'presencial', 'virtual'
      final isVirtual = c['is_virtual'] == true;
      if (_selectedModality == 'presencial' && isVirtual) {
        return false;
      }
      if (_selectedModality == 'virtual' && !isVirtual) {
        return false;
      }

      final level = (c['level']?.toString() ?? 'inicial').toLowerCase();
      final isSpecial = level == 'especial' || c['is_special'] == true || c['requires_approval'] == true;

      final code = (c['code']?.toString() ?? '').trim().toUpperCase();
      final title = (c['title']?.toString() ?? '').trim().toLowerCase();
      final isAlreadyApproved = approvedCodes.contains(code) ||
          ((code == 'A01' || title.contains('vida abundante') || title.contains('nueva alianza')) &&
           _approvedSubjects.any((s) {
             final sCode = (s['subject_code']?.toString() ?? '').trim().toUpperCase();
             final sTitle = (s['subject_title']?.toString() ?? '').trim().toLowerCase();
             return sCode == 'A01' || sTitle.contains('vida abundante') || sTitle.contains('nueva alianza');
           }));

      // El curso A01 (Vida Abundante) es de preparación bautismal y se cursa una sola vez
      final isA01Course = code == 'A01' || title.contains('vida abundante') || title.contains('nueva alianza');
      if (isA01Course && isAlreadyApproved) {
        return false;
      }

      // Si el alumno ya llevó y aprobó cualquier otro curso previamente, se le permite volver a llevarlo en el nuevo ciclo
      if (isAlreadyApproved) return true;

      // Special courses are open to the entire church without prerequisites
      if (isSpecial) return true;

      final curriculumItem = abcCurriculum.firstWhere(
        (sub) => sub.code == code,
        orElse: () => CurriculumSubject(code: code, title: '', level: level, prerequisites: [], duration: ''),
      );

      if (level == 'inicial') {
        if (code == 'A01') return true;
        return curriculumItem.prerequisites.every((p) => approvedCodes.contains(p));
      } else if (level == 'basico') {
        if (!hasApprovedInicial) return false;
        // Sequential prerequisites (e.g. B03 requires B02)
        if (curriculumItem.prerequisites.isNotEmpty) {
          return curriculumItem.prerequisites.every((p) => approvedCodes.contains(p));
        }
        return true;
      } else if (level == 'intermedio') {
        if (!hasApprovedBasico) return false;
        // Sequential prerequisites (e.g. C05 requires C04, C09 requires C08)
        if (curriculumItem.prerequisites.isNotEmpty) {
          return curriculumItem.prerequisites.every((p) => approvedCodes.contains(p));
        }
        return true;
      } else if (level == 'avanzado') {
        if (!hasApprovedIntermedio) return false;
        // Sequential prerequisites (e.g. ETE 2 requires ETE 1)
        if (curriculumItem.prerequisites.isNotEmpty) {
          return curriculumItem.prerequisites.every((p) => approvedCodes.contains(p));
        }
        return true;
      }

      return true;
    }).toList();

    // Order courses by levels progression and then code
    const levelWeights = {
      'inicial': 0,
      'basico': 1,
      'intermedio': 2,
      'avanzado': 3,
      'especial': 4,
    };

    filtered.sort((a, b) {
      final lvlA = (a['level']?.toString() ?? 'inicial').toLowerCase();
      final lvlB = (b['level']?.toString() ?? 'inicial').toLowerCase();
      final weightA = levelWeights[lvlA] ?? 99;
      final weightB = levelWeights[lvlB] ?? 99;
      final compLevel = weightA.compareTo(weightB);
      if (compLevel != 0) return compLevel;
      final codeA = a['code']?.toString() ?? '';
      final codeB = b['code']?.toString() ?? '';
      return codeA.compareTo(codeB);
    });

    return filtered;
  }

  Future<void> _enrollInCourse(Map<String, dynamic> course) async {
    final user = ref.read(authStateProvider).userProfile;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para matricularte.')),
      );
      return;
    }

    final cycle = course['cycle']?.toString() ?? _activeCycle;
    if (!_isEnrollmentOpen(cycle)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Las inscripciones para el ciclo $cycle se encuentran cerradas por Coordinación.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final isAlready = _userEnrollments.any((e) => e['course_id'] == course['id'] && e['status'] == 'aprobado');
    if (isAlready) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya te encuentras matriculado en este curso.')),
      );
      return;
    }

    final cCode = (course['code']?.toString() ?? '').trim().toUpperCase();
    final cTitle = (course['title']?.toString() ?? '').trim().toLowerCase();
    final isA01 = cCode == 'A01' || cTitle.contains('vida abundante') || cTitle.contains('nueva alianza');
    final hasA01Approved = _approvedSubjects.any((s) {
      final code = (s['subject_code']?.toString() ?? '').trim().toUpperCase();
      final title = (s['subject_title']?.toString() ?? '').trim().toLowerCase();
      return code == 'A01' || title.contains('vida abundante') || title.contains('nueva alianza');
    });

    if (isA01 && hasA01Approved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya has llevado y aprobado el curso Vida Abundante previamente. Este curso es preparatorio para el bautismo y se realiza una sola vez.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final conflict = _getScheduleConflict(course);
    if (conflict != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
              SizedBox(width: 8),
              Expanded(child: Text('Cruce de Horarios')),
            ],
          ),
          content: Text(
            'No puedes matricularte en "${course['title']}" porque su horario (${course['schedule'] ?? "No especificado"}) se cruza con tu curso ya inscrito:\n\n• ${conflict['conflictingTitle']} (${conflict['conflictingSchedule']}).',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    final level = (course['level']?.toString() ?? '').toLowerCase();
    final isSpecial = level == 'especial' || course['is_special'] == true || course['requires_approval'] == true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isSpecial ? 'Solicitud de Curso Especial' : 'Confirmar Matrícula',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSpecial
                  ? 'Este es un Curso Especial abierto a toda la iglesia que requiere aprobación por parte de la Pastoral o Coordinación ABC.'
                  : '¿Deseas matricularte en "${course['code']} - ${course['title']}" para el ciclo $_activeCycle?',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            if (isSpecial) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: Color(0xFFB45309)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tu matrícula quedará registrada como "Pendiente de Aprobación" hasta que sea evaluada.',
                        style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF92400E), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(isSpecial ? 'Enviar Solicitud' : 'Sí, Matricularme'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final client = Supabase.instance.client;
      await client.from('enrollments').insert({
        'student_id': user.id,
        'course_id': course['id'],
        'attendance_percentage': 100,
        'final_grade': null,
        'is_approved': false,
        'status': isSpecial ? 'pendiente' : 'aprobado',
      });

      if (user.email.isNotEmpty) {
        final teacher = course['profiles'];
        final teacherName = teacher != null
            ? '${teacher['first_name'] ?? ''} ${teacher['last_name'] ?? ''}'.trim()
            : 'Secretaría Académica';

        ResendEmailService.sendEnrollmentConfirmation(
          to: user.email,
          studentName: user.name,
          courseTitle: course['title'] ?? 'Curso ABC',
          courseCode: course['code'] ?? '',
          schedule: course['schedule'] ?? 'Horario regular',
          level: _levelNames[course['level']] ?? (course['level'] ?? 'Inicial'),
          teacherName: teacherName,
          cycleCode: _activeCycle,
          isVirtual: course['is_virtual'] == true,
          virtualLink: course['virtual_link']?.toString(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16A34A),
            content: Text(
              isSpecial
                  ? '¡Solicitud enviada! Pendiente de aprobación por la Pastoral o Coordinación.'
                  : '¡Matrícula exitosa en ${course['title']}! Se envió confirmación a tu correo.',
            ),
          ),
        );
        _selectedActiveCourseId = course['id']?.toString();
        await _loadData(isSilent: true);
        if (!isSpecial && _tabControllerInitialized && mounted) {
          _tabController.animateTo(0);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error al matricularse: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.userProfile;
    final isEnrolled = _isUserEnrolledInActiveCycle();
    final activeEnrs = _getActiveEnrollments();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Tab Bar
                Container(
                  color: AppColors.primary,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: AppColors.tertiaryAccent,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                    tabs: [
                      // Tab 1 (when enrolled): Mis Cursos (N) / Mi Curso Actual
                      if (isEnrolled)
                        Tab(
                          icon: const Icon(Icons.school, size: 18),
                          text: activeEnrs.length > 1
                              ? 'Mis Cursos (${activeEnrs.length})'
                              : 'Mi Curso Actual',
                        ),
                      // Tab Matrícula: Always accessible
                      Tab(
                        icon: Icon(_isEnrollmentOpen() ? Icons.how_to_reg : Icons.lock_clock, size: 18),
                        text: _activeCycle.isNotEmpty
                            ? (_isEnrollmentOpen() ? 'Matrícula ABC' : 'Inscripciones Cerradas')
                            : 'Ciclo Cerrado',
                      ),
                      // Tab Mi Historial
                      const Tab(
                        icon: Icon(Icons.history_edu, size: 18),
                        text: 'Mi Historial',
                      ),
                      // Tab Conditional: Panel Docente
                      if (user != null && (user.isTeacher || user.isPastor))
                        const Tab(
                          icon: Icon(Icons.edit_note, size: 18),
                          text: 'Panel Docente',
                        ),
                      // Tab Conditional: Coordinación ABC
                      if (user != null && (user.isAcademyCoordinator || user.isPastor))
                        const Tab(
                          icon: Icon(Icons.admin_panel_settings, size: 18),
                          text: 'Coordinación ABC',
                        ),
                      // Tab Conditional: Reportes y Redes
                      if (user != null && (user.isAcademyCoordinator || user.isPastor))
                        const Tab(
                          icon: Icon(Icons.analytics_outlined, size: 18),
                          text: 'Reportes y Redes',
                        ),
                    ],
                  ),
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // TAB 1 (when enrolled): Enrolled active courses view
                      if (isEnrolled) _buildActiveCourseView(),

                      // TAB Matrícula: Catalog of available courses
                      _buildEnrollmentTab(),

                      // TAB Mi Historial: Academic history & past grades
                      _buildHistoryTab(),

                      // TAB 3: Teacher
                      if (user != null && (user.isTeacher || user.isPastor))
                        _buildTeacherPanelTab(),

                      // TAB 4: Coordinator
                      if (user != null && (user.isAcademyCoordinator || user.isPastor))
                        _buildCoordinatorTab(),

                      // TAB 5: Attendance & Network Report
                      if (user != null && (user.isAcademyCoordinator || user.isPastor))
                        _buildAttendanceReportTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // TAB 1 (A): Vista del Curso Activo (cuando el alumno ya está matriculado)
  Widget _buildActiveCourseView() {
    final activeEnrollments = _getActiveEnrollments();
    final enrollment = _getSelectedActiveEnrollment();
    if (enrollment == null) return const SizedBox.shrink();

    final course = enrollment['courses'];
    final courseId = course?['id']?.toString() ?? '';
    final teacher = course?['profiles'];
    final teacherName = _getTeacherDisplayNameForStudent(course, teacher);

    final grade = enrollment['final_grade'];
    final isVirtual = course?['is_virtual'] == true;
    final virtualLink = course?['virtual_link']?.toString() ?? '';
    final virtualPlatform = course?['virtual_platform']?.toString() ?? 'Zoom';
    final classroom = course?['classroom']?.toString() ?? 'Aula Principal';
    final bookTitle = course?['book_title']?.toString() ?? 'Sin libro requerido';
    final bookStore = course?['book_store_info']?.toString() ?? 'Consultar en Secretaría';
    final materials = course?['materials'] is List ? List.from(course['materials']) : [];
    final courseAttendances = _studentAttendanceList
        .where((a) => a['course_id'] == course?['id'])
        .toList();
    final isCourseActive = course?['is_active'] ?? true;
    final isDisapprovedAbsences = enrollment['status'] == 'desaprobado_inasistencias' || (enrollment['disapproval_reason']?.toString().contains('inasistencias') ?? false);
    final disapprovalReason = enrollment['disapproval_reason']?.toString();

    // Compute student attendance stats for the selected course
    final totalSessions = _courseTotalSessions[courseId] ?? _activeCourseTotalSessions;
    final studentAttended = courseAttendances.where((a) => a['status'] == 'presente' || a['status'] == 'justificado').length;
    final studentPct = totalSessions > 0 ? ((studentAttended / totalSessions) * 100).round() : 0;
    final maxAllowedAbsences = getMaxAllowedAbsences(totalSessions, course?['max_absences']);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector de múltiples cursos activos
          if (activeEnrollments.length > 1) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...activeEnrollments.map((enr) {
                      final c = enr['courses'];
                      final cId = c?['id']?.toString() ?? '';
                      final isSelected = cId == courseId;
                      final cTitle = c?['title'] ?? 'Curso';
                      final cCode = c?['code'] ?? '';
                      final isSpecial = c?['level']?.toString().toLowerCase() == 'especial';
                      final isAppr = enr['is_approved'] == true;
                      final isAct = c?['is_active'] == true;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _selectedActiveCourseId = cId;
                                _activeCourseTotalSessions = _courseTotalSessions[cId] ?? 0;
                              });
                            }
                          },
                          avatar: Icon(
                            isAppr ? Icons.verified : (isSpecial ? Icons.star_rounded : Icons.school_outlined),
                            size: 16,
                            color: isSelected ? Colors.white : AppColors.primary,
                          ),
                          label: Text(
                            '$cCode: $cTitle ${isAppr ? "(Aprobado)" : (!isAct ? "(Finalizado)" : "")}',
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }),
                    if (_isEnrollmentOpen())
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: const Icon(Icons.add_circle_outline, size: 16, color: Color(0xFF16A34A)),
                          label: const Text('Matricular otro curso', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 12)),
                          backgroundColor: const Color(0xFFF0FDF4),
                          side: const BorderSide(color: Color(0xFFBBF7D0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onPressed: () => _tabController.animateTo(1),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mi Curso Actual',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  if (_isEnrollmentOpen())
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF16A34A),
                        backgroundColor: const Color(0xFFF0FDF4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFFBBF7D0)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Matricular otro curso', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      onPressed: () => _tabController.animateTo(1),
                    ),
                ],
              ),
            ),
          ],

          if (_isEnrollmentOpen()) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF16A34A), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Puedes matricularte en otro curso de este ciclo siempre que no haya cruce de horarios.',
                      style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF166534), fontWeight: FontWeight.w500),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _tabController.animateTo(1),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Ver Cursos', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],

          // If course is closed, display outcome banner
          if (!isCourseActive) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: enrollment['is_approved'] == true
                    ? const Color(0xFFF0FDF4)
                    : AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: enrollment['is_approved'] == true
                      ? const Color(0xFFBBF7D0)
                      : AppColors.error.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    enrollment['is_approved'] == true
                        ? Icons.verified
                        : (isDisapprovedAbsences ? Icons.person_off : Icons.cancel_outlined),
                    color: enrollment['is_approved'] == true ? const Color(0xFF16A34A) : AppColors.error,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          enrollment['is_approved'] == true
                              ? '¡Curso Aprobado Satisfactoriamente!'
                              : (isDisapprovedAbsences
                                  ? 'Curso Finalizado: Desaprobado por Inasistencias'
                                  : 'Curso Finalizado: Desaprobado'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: enrollment['is_approved'] == true ? const Color(0xFF166534) : AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          disapprovalReason ??
                              (enrollment['is_approved'] == true
                                  ? 'Has completado y aprobado los requisitos de este curso.'
                                  : 'No se alcanzó la nota mínima aprobatoria.'),
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: enrollment['is_approved'] == true ? const Color(0xFF166534) : AppColors.error,
                          ),
                        ),
                        if (isDisapprovedAbsences && totalSessions > 0) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Relación: ${totalSessions - studentAttended} faltas en $totalSessions clases dictadas (Límite permitido: $maxAllowedAbsences).',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Enrolled Header Banner
          Container(
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
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: !isCourseActive
                        ? (enrollment['is_approved'] == true ? const Color(0xFF16A34A) : AppColors.error)
                        : const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    !isCourseActive
                        ? (enrollment['is_approved'] == true ? 'Curso Concluido (Aprobado)' : 'Curso Concluido')
                        : 'Matriculado en Ciclo $_activeCycle',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${course?['code']}: ${course?['title']}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nivel ${_levelNames[course?['level']] ?? course?['level']} • $teacherName',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.onPrimaryContainer),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 16),

                // Metrics Row (ASISTENCIA & NOTA FINAL)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    InkWell(
                      onTap: () {
                        if (course?['id'] != null) {
                          _showStudentAttendanceHistoryDialog(
                            course!['id'].toString(),
                            course['title']?.toString() ?? 'Curso',
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'ASISTENCIA',
                                  style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white70),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.info_outline, size: 12, color: Colors.white70),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              totalSessions == 0
                                  ? '0%'
                                  : '$studentPct%',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              totalSessions == 0
                                  ? 'Sin clases dictadas'
                                  : '$studentAttended de $totalSessions clases (Ver >)',
                              style: GoogleFonts.inter(fontSize: 9.5, color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(height: 36, width: 1, color: Colors.white24),
                    Column(
                      children: [
                        Text(
                          'NOTA FINAL',
                          style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          grade != null ? '$grade / 20' : (isCourseActive ? 'En Curso' : 'Sin Nota'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          grade != null
                              ? ((num.tryParse(grade.toString()) ?? 0) >= 14 ? 'Aprobatorio' : 'Desaprobatorio')
                              : 'Evaluación docente',
                          style: GoogleFonts.inter(fontSize: 9.5, color: Colors.white60),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (grade != null && (num.tryParse(grade.toString()) ?? 0) >= 14 && enrollment['is_approved'] == true) ...[
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () {
                _showCertificateOptions(
                  courseTitle: course?['title']?.toString() ?? 'Curso ABC',
                  subjectCode: course?['code']?.toString(),
                  grade: grade,
                  cycleCode: _activeCycle,
                );
              },
              icon: const Icon(Icons.workspace_premium, size: 18),
              label: const Text('Descargar Certificado de Aprobación'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Current Session Status Card
          Builder(
            builder: (context) {
              final sessionInfo = _getCurrentSessionInfo(course);
              final isReprog = sessionInfo.isReprogrammed;
              final isToday = sessionInfo.isToday;

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isReprog
                      ? const Color(0xFFFFFBEB)
                      : (isToday ? const Color(0xFFF0FDF4) : AppColors.surfaceContainerLowest),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isReprog
                        ? const Color(0xFFF59E0B)
                        : (isToday ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0)),
                    width: isReprog || isToday ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isReprog
                          ? const Color(0xFFD97706).withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isReprog
                                    ? const Color(0xFFFEF3C7)
                                    : (isToday ? const Color(0xFFDCFCE7) : AppColors.primary.withValues(alpha: 0.1)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isReprog
                                    ? Icons.event_repeat
                                    : (isToday ? Icons.today : Icons.event_note),
                                color: isReprog
                                    ? const Color(0xFFD97706)
                                    : (isToday ? const Color(0xFF16A34A) : AppColors.primary),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ESTADO DE SESIÓN',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    color: isReprog
                                        ? const Color(0xFFB45309)
                                        : (isToday ? const Color(0xFF15803D) : AppColors.primary),
                                  ),
                                ),
                                Text(
                                  isReprog
                                      ? 'Sesión ${sessionInfo.sessionNumber}: Reprogramada'
                                      : (isToday
                                          ? 'Sesión Actual: ${sessionInfo.sessionNumber} (Hoy)'
                                          : 'Sesión Actual: ${sessionInfo.sessionNumber}'),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isReprog
                                        ? const Color(0xFF92400E)
                                        : (isToday ? const Color(0xFF166534) : AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isReprog
                                ? const Color(0xFFFEF3C7)
                                : (isToday ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isReprog
                                  ? const Color(0xFFFCD34D)
                                  : (isToday ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1)),
                            ),
                          ),
                          child: Text(
                            'Sesión ${sessionInfo.sessionNumber} de ${sessionInfo.totalSessions}',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: isReprog
                                  ? const Color(0xFFB45309)
                                  : (isToday ? const Color(0xFF15803D) : AppColors.secondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 15, color: AppColors.secondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Fecha: ${sessionInfo.fullDateDisplay} (${sessionInfo.formattedDate})',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 15, color: AppColors.secondary),
                        const SizedBox(width: 8),
                        Text(
                          'Hora: ${sessionInfo.time}',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ],
                    ),
                    if (isReprog && sessionInfo.reprogrammedReason != null && sessionInfo.reprogrammedReason!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Text(
                          'Motivo: ${sessionInfo.reprogrammedReason}',
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF991B1B), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Self Attendance Registration Card
          Builder(
            builder: (context) {
              final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
              final hasMarkedToday = courseAttendances.any((a) => a['session_date'] == todayStr);
              final isAttendanceOpen = isCourseActive && (course?['attendance_open'] == true);

              Color cardBg = AppColors.surfaceContainerLowest;
              Color borderColor = const Color(0xFFE2E8F0);
              IconData iconData = Icons.how_to_reg;
              Color iconColor = AppColors.primary;
              String titleText = 'Marcar Asistencia a la Clase';
              String subtitleText = 'Registra tu asistencia para aligerar la labor del maestro.';

              if (!isCourseActive) {
                cardBg = Colors.grey.withValues(alpha: 0.05);
                iconData = Icons.lock_clock;
                iconColor = Colors.grey;
                titleText = 'Curso Concluido';
                subtitleText = 'Las clases y registros de este curso han finalizado.';
              } else if (hasMarkedToday) {
                cardBg = const Color(0xFFF0FDF4);
                borderColor = const Color(0xFFBBF7D0);
                iconData = Icons.check_circle;
                iconColor = const Color(0xFF16A34A);
                titleText = '¡Asistencia de Hoy Registrada!';
                subtitleText = 'Sesión: ${DateFormat("dd/MM/yyyy").format(DateTime.now())} • Registrado como Presente.';
              } else if (isAttendanceOpen) {
                cardBg = const Color(0xFFF0FDF4);
                borderColor = const Color(0xFF86EFAC);
                iconData = Icons.lock_open;
                iconColor = const Color(0xFF16A34A);
                titleText = '¡Asistencia Habilitada por el Docente!';
                subtitleText = 'El maestro ha abierto el registro para la clase de hoy. Marca tu asistencia ahora.';
              } else {
                cardBg = AppColors.surfaceContainerLowest;
                iconData = Icons.lock_outline;
                iconColor = AppColors.secondary;
                titleText = 'Asistencia Cerrada por el Docente';
                subtitleText = 'El maestro abrirá el registro durante la sesión de clase. Podrás marcar aquí cuando esté habilitada.';
              }

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: hasMarkedToday || isAttendanceOpen
                          ? const Color(0xFF16A34A).withValues(alpha: 0.08)
                          : AppColors.primaryContainer.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
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
                            color: iconColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(iconData, color: iconColor, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                titleText,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: hasMarkedToday || isAttendanceOpen ? const Color(0xFF15803D) : AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitleText,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: hasMarkedToday || isAttendanceOpen ? const Color(0xFF166534) : AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (isCourseActive && !hasMarkedToday) ...[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: isAttendanceOpen ? _markMyAttendance : null,
                        icon: Icon(isAttendanceOpen ? Icons.check_circle_outline : Icons.lock, size: 18),
                        label: Text(
                          isAttendanceOpen ? 'Marcar Mi Asistencia de Hoy' : 'Asistencia Aún No Habilitada',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAttendanceOpen ? const Color(0xFF16A34A) : Colors.grey[400],
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          disabledForegroundColor: Colors.grey[600],
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Schedule & Modality Card
          Builder(
            builder: (context) {
              final detailSessionInfo = _getCurrentSessionInfo(course);

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
                    Text(
                      'DETALLES DE LA CLASE',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                  Icons.event_note,
                  detailSessionInfo.isReprogrammed
                      ? 'Sesión ${detailSessionInfo.sessionNumber} (Reprogramada): ${detailSessionInfo.formattedDate} a las ${detailSessionInfo.time}'
                      : (detailSessionInfo.isToday
                          ? 'Sesión Actual: ${detailSessionInfo.sessionNumber} (Hoy) • ${detailSessionInfo.formattedDate}'
                          : 'Sesión Actual: ${detailSessionInfo.sessionNumber} • ${detailSessionInfo.formattedDate}'),
                ),
                const SizedBox(height: 6),
                _buildDetailRow(Icons.schedule, 'Horario Habitual: ${course?['schedule'] ?? "No especificado"}'),
                if (course?['rescheduled_date'] != null && course!['rescheduled_date'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.event_repeat, size: 18, color: Color(0xFFDC2626)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Próxima Sesión Reprogramada',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF991B1B)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Fecha: ${course['rescheduled_date']}${course['rescheduled_time'] != null && course['rescheduled_time'].toString().isNotEmpty ? " a las ${course['rescheduled_time']}" : ""}${course['rescheduled_reason'] != null && course['rescheduled_reason'].toString().isNotEmpty ? " • Motivo: ${course['rescheduled_reason']}" : ""}',
                                style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF7F1D1D)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 16),
                _buildDetailRow(
                  isVirtual ? Icons.devices : Icons.room,
                  isVirtual ? 'Modalidad: Virtual ($virtualPlatform)' : 'Aula Presencial: $classroom',
                ),
                if (isVirtual && virtualLink.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(virtualLink), mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.videocam, size: 16),
                    label: const Text('Ingresar a Clase Virtual'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 42),
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                const Divider(height: 16),
                _buildDetailRow(Icons.menu_book, 'Libro: $bookTitle'),
                const SizedBox(height: 4),
                _buildDetailRow(Icons.storefront, 'Librería / Adquisición: $bookStore'),
              ],
            ),
          );
        },
      ),

      const SizedBox(height: 20),

          // Course Materials Section
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MATERIALES Y GUÍAS DE CLASE',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '${materials.length} disponibles',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (materials.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        'El docente aún no ha subido guías o materiales para este curso.',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: materials.length,
                    separatorBuilder: (context, index) => const Divider(height: 12),
                    itemBuilder: (context, index) {
                      final mat = materials[index];
                      final name = mat['name']?.toString() ?? 'Material de Estudio';
                      final url = mat['url']?.toString() ?? '';

                      return Row(
                        children: [
                          const Icon(Icons.picture_as_pdf, color: AppColors.error, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                          ),
                          if (url.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.download, color: AppColors.primary, size: 20),
                              onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                              tooltip: 'Abrir / Descargar material',
                            ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Attendance History for this Course
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
                Text(
                  'HISTORIAL DE ASISTENCIAS POR SESIÓN',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                if (courseAttendances.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        'Aún no hay sesiones de asistencia registradas para tu curso.',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary, fontStyle: FontStyle.italic),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: courseAttendances.length,
                    separatorBuilder: (context, index) => const Divider(height: 10),
                    itemBuilder: (context, index) {
                      final att = courseAttendances[index];
                      final status = att['status']?.toString() ?? 'presente';
                      final date = att['session_date']?.toString() ?? '';

                      Color badgeColor;
                      String statusText;
                      if (status == 'presente') {
                        badgeColor = const Color(0xFF16A34A);
                        statusText = 'Asistió';
                      } else if (status == 'ausente') {
                        badgeColor = AppColors.error;
                        statusText = 'No Asistió';
                      } else {
                        badgeColor = const Color(0xFFD97706);
                        statusText = 'Justificado';
                      }

                      final rawMarkedAt = att['marked_at'] ?? att['created_at'];
                      String timeFormatted = '';
                      if (rawMarkedAt != null && rawMarkedAt.toString().isNotEmpty) {
                        try {
                          final parsedTime = DateTime.parse(rawMarkedAt.toString()).toLocal();
                          timeFormatted = ' • ${DateFormat("hh:mm a").format(parsedTime)}';
                        } catch (_) {}
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.event_available, size: 16, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'Sesión: $date$timeFormatted',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // TAB 1 (B): Pestaña de Matrícula (cuando NO está matriculado en el ciclo actual)
  Widget _buildEnrollmentTab() {
    final isCycleTrulyClosed = _activeCycle.isEmpty;
    final latestCycleName = _allCycles.isNotEmpty ? (_allCycles.first['cycle']?.toString() ?? '') : '';

    if (isCycleTrulyClosed) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner de Ciclo Cerrado
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF334155), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_clock, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          latestCycleName.isNotEmpty ? 'Ciclo Cerrado • $latestCycleName' : 'Ciclo Cerrado',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Actualmente no hay un periodo de matrícula abierto ni cursos activos. La coordinación de la Academia Bíblica Cristiana habilitará el próximo ciclo pronto.',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.school_outlined, size: 48, color: AppColors.secondary),
                  const SizedBox(height: 12),
                  Text(
                    'Período Académico en Pausa / Finalizado',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Puedes revisar tu historial académico, notas pasadas y certificados en la pestaña "Mi Historial".',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      final isEnr = _isUserEnrolledInActiveCycle();
                      _tabController.animateTo(isEnr ? 2 : 1);
                    },
                    icon: const Icon(Icons.history_edu, size: 16),
                    label: const Text('Ver Mi Historial Académico'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_offeredCourses.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner de Ciclo Abierto pero cursos en preparación
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.how_to_reg, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Matrícula Abierta • Ciclo $_activeCycle',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('ABIERTO', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'El ciclo actual se encuentra formalmente abierto. La coordinación académica está publicando y asignando los cursos y docentes para este período.',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppColors.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.pending_actions, size: 48, color: AppColors.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Cursos en Proceso de Publicación',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Los cursos habilitados para el Ciclo $_activeCycle estarán disponibles para matrícula en breves momentos.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final enrollableCourses = _getEnrollableCourses();
    final pendingEnrollment = _getPendingEnrollment();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner de Matrícula Abierta
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.school, color: Colors.white, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Matrícula Abierta • Ciclo $_activeCycle',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cursos organizados por niveles según tu historial académico. Filtra por modalidad presencial o virtual.',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppColors.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (!_isEnrollmentOpen() && _activeCycle.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_clock, color: Color(0xFFD97706), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inscripciones Cerradas para el Ciclo $_activeCycle',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'El período de matrícula ha concluido. Si necesitas una inscripción extemporánea, comunícate con Coordinación.',
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF78350F)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Solicitud en Evaluación Banner (si el alumno tiene una inscripción especial pendiente)
          if (pendingEnrollment != null) ...[
            Builder(
              builder: (context) {
                final pendingCourse = pendingEnrollment['courses'];
                final pendingTeacher = pendingCourse != null ? pendingCourse['profiles'] : null;
                final pendingTeacherName = _getTeacherDisplayNameForStudent(pendingCourse, pendingTeacher);

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD97706).withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
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
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'SOLICITUD EN EVALUACIÓN',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                        color: const Color(0xFFB45309),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFFCD34D)),
                                      ),
                                      child: const Text('PENDIENTE', style: TextStyle(color: Color(0xFFB45309), fontSize: 9.5, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${pendingCourse?['code'] ?? ""}: ${pendingCourse?['title'] ?? "Curso Especial"}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFFFDE68A), height: 1),
                      const SizedBox(height: 12),
                      _buildDetailRow(Icons.person_outline, 'Docente: $pendingTeacherName'),
                      const SizedBox(height: 4),
                      _buildDetailRow(Icons.schedule, 'Horario: ${pendingCourse?['schedule'] ?? "Por coordinar"}'),
                      const SizedBox(height: 4),
                      _buildDetailRow(
                        pendingCourse?['is_virtual'] == true ? Icons.devices : Icons.room,
                        pendingCourse?['is_virtual'] == true ? 'Modalidad: Virtual' : 'Aula: ${pendingCourse?['classroom'] ?? "Presencial"}',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7).withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: Color(0xFF92400E)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tu solicitud está siendo revisada por Coordinación o Pastoral. La marcación de asistencia y el acceso al aula virtual se habilitarán una vez aprobada.',
                                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF92400E), height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],

          // Modality Organization Filter Chips (Todos, Presencial, Virtual)
          Text(
            'ORGANIZAR POR MODALIDAD',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(
                      Icons.apps_rounded,
                      size: 15,
                      color: _selectedModality == 'todos' ? Colors.white : AppColors.primary,
                    ),
                    label: const Text('Todos'),
                    selected: _selectedModality == 'todos',
                    onSelected: (val) {
                      if (val) setState(() => _selectedModality = 'todos');
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceContainerLowest,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: _selectedModality == 'todos' ? FontWeight.bold : FontWeight.normal,
                      color: _selectedModality == 'todos' ? Colors.white : AppColors.primary,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(
                      Icons.apartment,
                      size: 15,
                      color: _selectedModality == 'presencial' ? Colors.white : const Color(0xFF059669),
                    ),
                    label: const Text('Presencial'),
                    selected: _selectedModality == 'presencial',
                    onSelected: (val) {
                      if (val) setState(() => _selectedModality = 'presencial');
                    },
                    selectedColor: const Color(0xFF059669),
                    backgroundColor: AppColors.surfaceContainerLowest,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: _selectedModality == 'presencial' ? FontWeight.bold : FontWeight.normal,
                      color: _selectedModality == 'presencial' ? Colors.white : const Color(0xFF059669),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(
                      Icons.devices,
                      size: 15,
                      color: _selectedModality == 'virtual' ? Colors.white : const Color(0xFF7C3AED),
                    ),
                    label: const Text('Virtual'),
                    selected: _selectedModality == 'virtual',
                    onSelected: (val) {
                      if (val) setState(() => _selectedModality = 'virtual');
                    },
                    selectedColor: const Color(0xFF7C3AED),
                    backgroundColor: AppColors.surfaceContainerLowest,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: _selectedModality == 'virtual' ? FontWeight.bold : FontWeight.normal,
                      color: _selectedModality == 'virtual' ? Colors.white : const Color(0xFF7C3AED),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Eligible Courses List
          Text(
            'CURSOS DISPONIBLES PARA MATRICULARTE',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),

          if (enrollableCourses.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.info_outline, size: 36, color: AppColors.secondary),
                    const SizedBox(height: 10),
                    Text(
                      _selectedModality == 'todos'
                          ? 'No hay cursos disponibles según tu historial académico o prerrequisitos.'
                          : 'No hay cursos ${_selectedModality == "presencial" ? "presenciales" : "virtuales"} disponibles según tu historial académico.',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.secondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: enrollableCourses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final course = enrollableCourses[index];
                return _buildCourseEnrollmentCard(course);
              },
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCourseEnrollmentCard(Map<String, dynamic> course, {VoidCallback? onEnrolled}) {
    final teacher = course['profiles'];
    final teacherName = _getTeacherDisplayNameForStudent(course, teacher);
    final isSpecialCourse = (course['level']?.toString().toLowerCase() == 'especial') ||
        course['is_special'] == true ||
        course['requires_approval'] == true;
    final isVirtualCourse = course['is_virtual'] == true;
    final isEnrolledInThis = _userEnrollments.any((e) => e['course_id'] == course['id'] && e['status'] == 'aprobado');
    final isPendingThis = _userEnrollments.any((e) => e['course_id'] == course['id'] && e['status'] == 'pendiente');
    final isPreviouslyApproved = _approvedSubjects.any((s) => s['subject_code']?.toString() == course['code']?.toString());
    final conflict = _getScheduleConflict(course);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSpecialCourse ? const Color(0xFFFCD34D) : const Color(0xFFE2E8F0),
          width: isSpecialCourse ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSpecialCourse
                          ? const Color(0xFFFEF3C7)
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      course['code'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSpecialCourse ? const Color(0xFFB45309) : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isVirtualCourse
                          ? const Color(0xFFF3E8FF)
                          : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isVirtualCourse
                            ? const Color(0xFFD8B4FE)
                            : const Color(0xFFA7F3D0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isVirtualCourse ? Icons.devices : Icons.apartment,
                          size: 11,
                          color: isVirtualCourse ? const Color(0xFF7C3AED) : const Color(0xFF059669),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isVirtualCourse ? 'Virtual' : 'Presencial',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: isVirtualCourse ? const Color(0xFF7C3AED) : const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isSpecialCourse)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 12, color: Color(0xFFB45309)),
                      const SizedBox(width: 4),
                      Text(
                        'Especial • Con Aprobación',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    _levelNames[course['level']] ?? course['level'] ?? '',
                    style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.secondary, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            course['title'] ?? '',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          if (isPreviouslyApproved) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, size: 13, color: Color(0xFF16A34A)),
                  const SizedBox(width: 5),
                  Text(
                    'Ya lo aprobaste anteriormente • Puedes volver a llevarlo',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF15803D)),
                  ),
                ],
              ),
            ),
          ],
          if (isSpecialCourse) ...[
            const SizedBox(height: 4),
            Text(
              '⭐ Abierto a toda la iglesia sin prerrequisitos académicos (requiere visto bueno del pastor/coordinación).',
              style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF92400E), fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 8),
          _buildDetailRow(Icons.person_outline, 'Docente: $teacherName'),
          const SizedBox(height: 4),
          _buildDetailRow(Icons.schedule, 'Horario: ${course['schedule'] ?? ""}'),
          const SizedBox(height: 4),
          _buildDetailRow(
            course['is_virtual'] == true ? Icons.devices : Icons.room,
            course['is_virtual'] == true ? 'Modalidad: Virtual' : 'Aula: ${course['classroom'] ?? "Presencial"}',
          ),
          if (_getCourseStartDate(course) != null) ...[
            const SizedBox(height: 4),
            _buildDetailRow(
              Icons.event_available,
              'Fecha de Inicio: ${DateFormat("dd/MM/yyyy").format(_getCourseStartDate(course)!)}',
            ),
          ],
          if (_hasCourseStarted(course)) ...[
            const SizedBox(height: 4),
            _buildDetailRow(
              Icons.event_note,
              _getCurrentSessionInfo(course).isReprogrammed
                  ? 'Sesión ${_getCurrentSessionInfo(course).sessionNumber} (Reprogramada): ${_getCurrentSessionInfo(course).formattedDate} a las ${_getCurrentSessionInfo(course).time}'
                  : (_getCurrentSessionInfo(course).isToday
                      ? 'Sesión ${_getCurrentSessionInfo(course).sessionNumber} (Hoy) • ${_getCurrentSessionInfo(course).formattedDate}'
                      : 'Sesión Actual: ${_getCurrentSessionInfo(course).sessionNumber} • ${_getCurrentSessionInfo(course).formattedDate}'),
            ),
          ],
          if (course['rescheduled_date'] != null && course['rescheduled_date'].toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_repeat, size: 16, color: Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reprogramado: ${course['rescheduled_date']}${course['rescheduled_time'] != null && course['rescheduled_time'].toString().isNotEmpty ? " a las ${course['rescheduled_time']}" : ""}${course['rescheduled_reason'] != null && course['rescheduled_reason'].toString().isNotEmpty ? " (${course['rescheduled_reason']})" : ""}',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF991B1B), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (isEnrolledInThis)
            ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.check_circle, size: 18, color: Color(0xFF16A34A)),
              label: const Text('Ya estás matriculado', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                backgroundColor: const Color(0xFFF0FDF4),
                disabledBackgroundColor: const Color(0xFFF0FDF4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFBBF7D0)),
                ),
              ),
            )
          else if (!_isEnrollmentOpen(course['cycle']?.toString()))
            ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.lock_clock, size: 18, color: Colors.grey),
              label: const Text('Inscripciones Cerradas', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                backgroundColor: const Color(0xFFF1F5F9),
                disabledBackgroundColor: const Color(0xFFF1F5F9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          else if (isPendingThis)
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.hourglass_top_rounded, size: 18, color: Color(0xFFD97706)),
              label: const Text('Solicitud Enviada (En Evaluación)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                side: const BorderSide(color: Color(0xFFFCD34D), width: 1.5),
                backgroundColor: const Color(0xFFFEF3C7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          else if (conflict != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFB45309)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cruce de horario con ${conflict['conflictingTitle']} (${conflict['conflictingSchedule']})',
                          style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF92400E), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.block, size: 18, color: Colors.grey),
                  label: const Text('Horario Cruzado (No disponible)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    backgroundColor: const Color(0xFFF1F5F9),
                    disabledBackgroundColor: const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            )
          else
            ElevatedButton.icon(
              onPressed: () async {
                await _enrollInCourse(course);
                onEnrolled?.call();
              },
              icon: Icon(isSpecialCourse ? Icons.send_rounded : (isPreviouslyApproved ? Icons.replay : Icons.check_circle_outline), size: 18),
              label: Text(
                isSpecialCourse
                    ? 'Solicitar Inscripción Especial'
                    : (isPreviouslyApproved
                        ? 'Volver a Matricularme en este Curso'
                        : 'Matricularme en este Curso'),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                backgroundColor: isSpecialCourse ? const Color(0xFFD97706) : AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }


  // TAB 2: Historial Aprobado
  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified, color: Color(0xFF16A34A), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Cursos Aprobados: ${_approvedSubjects.length}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'Historial oficial registrado en la base de datos de la academia.',
                        style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_approvedSubjects.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Aún no tienes materias aprobadas registradas.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.secondary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _approvedSubjects.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final sub = _approvedSubjects[index];
                final title = sub['subject_title']?.toString() ?? 'Curso Aprobado';
                final code = sub['subject_code']?.toString() ?? '';
                final grade = sub['grade'] ?? 20;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              code.isNotEmpty ? '$code - $title' : title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Nota: $grade',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          _showCertificateOptions(
                            courseTitle: title,
                            subjectCode: code,
                            grade: grade,
                            cycleCode: sub['cycle']?.toString() ?? _activeCycle,
                          );
                        },
                        icon: const Icon(Icons.workspace_premium, size: 16, color: Color(0xFF16A34A)),
                        label: const Text(
                          'Descargar Certificado PDF',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 38),
                          side: const BorderSide(color: Color(0xFF16A34A)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          if (_userEnrollments.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'TODAS MIS MATRÍCULAS Y CURSOS',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _userEnrollments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final enr = _userEnrollments[index];
                final c = enr['courses'];
                final cTitle = c?['title']?.toString() ?? 'Curso ABC';
                final cCode = c?['code']?.toString() ?? '';
                final cCycle = c?['cycle']?.toString() ?? '';
                final g = enr['final_grade'];
                final att = enr['attendance_percentage'];
                final isApproved = enr['is_approved'] == true;
                final isDisapprovedAbsences = enr['status'] == 'desaprobado_inasistencias' || (enr['disapproval_reason']?.toString().contains('inasistencias') ?? false);
                final isPending = enr['status'] == 'pendiente';
                final isAct = c?['is_active'] == true;

                Color badgeColor = const Color(0xFF16A34A);
                String badgeText = 'Aprobado';
                if (isPending) {
                  badgeColor = const Color(0xFFD97706);
                  badgeText = 'Pendiente';
                } else if (isDisapprovedAbsences) {
                  badgeColor = AppColors.error;
                  badgeText = 'Desap. Inasistencias';
                } else if (!isApproved && !isAct) {
                  badgeColor = AppColors.error;
                  badgeText = 'Desaprobado';
                } else if (isAct && !isApproved) {
                  badgeColor = AppColors.primary;
                  badgeText = 'En Curso';
                }

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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              cCode.isNotEmpty ? '$cCode: $cTitle' : cTitle,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ciclo: $cCycle • Asistencia: ${att != null ? "$att%" : "S/R"} • Nota: ${g != null ? "$g/20" : "S/N"}',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary),
                      ),
                      if (enr['disapproval_reason'] != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          enr['disapproval_reason'].toString(),
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          if (c?['id'] != null) {
                            _showStudentAttendanceHistoryDialog(c!['id'].toString(), cTitle);
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.history_edu, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Ver Detalle de Asistencias',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showCertificateOptions({
    required String courseTitle,
    String? subjectCode,
    dynamic grade,
    String? cycleCode,
  }) {
    final user = ref.read(authStateProvider).userProfile;
    final studentName = user?.name ?? 'Estudiante Miembro';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium, color: Color(0xFF16A34A), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Certificado de Aprobación',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        courseTitle,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                CertificateGenerator.printPreviewCertificate(
                  studentName: studentName,
                  courseTitle: courseTitle,
                  subjectCode: subjectCode,
                  grade: grade,
                  cycleCode: cycleCode,
                );
              },
              icon: const Icon(Icons.picture_as_pdf, size: 18),
              label: const Text('Ver / Imprimir Diploma PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                CertificateGenerator.shareOrPrintCertificate(
                  studentName: studentName,
                  courseTitle: courseTitle,
                  subjectCode: subjectCode,
                  grade: grade,
                  cycleCode: cycleCode,
                );
              },
              icon: const Icon(Icons.share, size: 18),
              label: const Text('Compartir Diploma (WhatsApp / Archivo)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            if (user != null && user.email.isNotEmpty) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final ok = await ResendEmailService.sendCertificateEmail(
                    to: user.email,
                    studentName: studentName,
                    courseTitle: courseTitle,
                    subjectCode: subjectCode ?? '',
                    grade: grade,
                    cycleCode: cycleCode ?? _activeCycle,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? '¡Certificado enviado a tu correo (${user.email})!'
                            : 'No se pudo enviar el correo en este momento.'),
                        backgroundColor: ok ? const Color(0xFF059669) : AppColors.error,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.email_outlined, size: 18, color: Color(0xFF2563EB)),
                label: const Text(
                  'Enviar Diploma a mi Correo',
                  style: TextStyle(color: Color(0xFF2563EB)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // TAB 3: Panel Docente (Para profesores y pastores con paridad web y máxima responsividad)
  Widget _buildTeacherPanelTab() {
    if (_teacherCourses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.school_outlined, size: 48, color: AppColors.secondary),
              const SizedBox(height: 14),
              Text(
                'No tienes clases asignadas actualmente',
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'El coordinador de la ABC asignará tus materias correspondientes.',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final selectedCourse = _teacherCourses.firstWhere(
      (c) => c['id'] == _selectedTeacherCourseId,
      orElse: () => _teacherCourses.first,
    );
    final isSelectedActive = selectedCourse['is_active'] ?? true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Select assigned course
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SELECCIONA TU CLASE ASIGNADA',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppColors.primary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelectedActive
                            ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                            : Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isSelectedActive ? 'En Curso (Abierto)' : 'Cerrado',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelectedActive ? const Color(0xFF16A34A) : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedTeacherCourseId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _teacherCourses.map((c) {
                    final isAct = c['is_active'] ?? true;
                    return DropdownMenuItem<String>(
                      value: c['id'],
                      child: Text(
                        '${c['code']}: ${c['title']} (${c['cycle'] ?? ""})${isAct ? "" : " [Cerrado]"}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isAct ? AppColors.primary : AppColors.secondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedTeacherCourseId = val);
                      _loadStudentsForTeacherCourse(val);
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Live Attendance Enabling Card for Teacher
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: (selectedCourse['attendance_open'] == true)
                        ? const Color(0xFFF0FDF4)
                        : Colors.grey.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (selectedCourse['attendance_open'] == true)
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        (selectedCourse['attendance_open'] == true) ? Icons.lock_open : Icons.lock,
                        color: (selectedCourse['attendance_open'] == true) ? const Color(0xFF16A34A) : AppColors.secondary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (selectedCourse['attendance_open'] == true)
                                  ? 'Asistencia Habilitada para Alumnos'
                                  : 'Asistencia Cerrada para Alumnos',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: (selectedCourse['attendance_open'] == true)
                                    ? const Color(0xFF166534)
                                    : AppColors.primary,
                              ),
                            ),
                            Text(
                              (selectedCourse['attendance_open'] == true)
                                  ? 'Los alumnos pueden registrar su asistencia desde su app.'
                                  : 'Activa el switch para permitir que los alumnos marquen asistencia hoy.',
                              style: GoogleFonts.inter(fontSize: 10, color: AppColors.secondary),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: selectedCourse['attendance_open'] == true,
                        activeThumbColor: const Color(0xFF16A34A),
                        onChanged: isSelectedActive
                            ? (val) => _toggleCourseAttendanceOpen(selectedCourse, val)
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Action buttons for Teacher (Tomar Asistencia, Reporte, Matricular y Cerrar Curso)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AsistenciaClaseScreen(
                                courseId: selectedCourse['id'],
                                courseTitle: '${selectedCourse['code']}: ${selectedCourse['title']}',
                                schedule: selectedCourse['schedule'] ?? '',
                                level: selectedCourse['level'] ?? 'inicial',
                              ),
                            ),
                          );
                          if (result == true) {
                            _loadStudentsForTeacherCourse(selectedCourse['id']);
                          }
                        },
                        icon: const Icon(Icons.fact_check, size: 15),
                        label: const Text('Tomar Lista', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showCourseAttendanceReportDialog(selectedCourse),
                        icon: const Icon(Icons.assessment, size: 15),
                        label: const Text('Reporte', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: AppColors.tertiaryAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    if (isSelectedActive) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showTeacherManualEnrollDialog(selectedCourse),
                          icon: const Icon(Icons.person_add_alt_1, size: 15),
                          label: const Text('Matricular', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Bulk grading grid (Acta de Notas Masiva)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACTA DE NOTAS DEL GRUPO',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'Ingresa notas de 0 a 20.',
                            style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ),
                    if (_courseStudents.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Botón Guardar Borrador
                          OutlinedButton.icon(
                            onPressed: _savingGrades ? null : () => _saveAllGrades(closeCourse: false),
                            icon: const Icon(Icons.save, size: 14),
                            label: const Text('Guardar', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          if (isSelectedActive) ...[
                            const SizedBox(width: 6),
                            // Botón Finalizar / Cerrar Curso
                            ElevatedButton.icon(
                              onPressed: _savingGrades ? null : () => _saveAllGrades(closeCourse: true),
                              icon: const Icon(Icons.lock, size: 14),
                              label: const Text('Cerrar Curso', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_loadingStudents)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                else if (_courseStudents.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No hay alumnos matriculados en esta clase todavía.',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary, fontStyle: FontStyle.italic),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _courseStudents.length,
                    separatorBuilder: (context, index) => const Divider(height: 14),
                    itemBuilder: (context, index) {
                      final st = _courseStudents[index];
                      final profile = st['profiles'];
                      final name = profile != null ? '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim() : 'Alumno';
                      final dni = profile?['dni'] ?? 'S/DNI';
                      final phone = profile?['phone'] ?? '';
                      final stId = st['student_id']?.toString() ?? '';
                      final controller = _gradeControllers[stId];

                      final attData = st['computed_attendance'] as Map<String, dynamic>?;
                      final totalSessions = attData?['totalSessions'] ?? 0;
                      final attPct = attData?['pct'] ?? (st['attendance_percentage'] ?? 0);
                      final totalAbsences = attData?['absent'] ?? 0;
                      final maxAllowed = attData?['maxAllowed'] ?? 0;
                      final isExceeded = attData?['isExceeded'] == true;
                      final isDisapprovedAbsences = st['status'] == 'desaprobado_inasistencias';

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            // Student Info (Expanded)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    totalSessions == 0
                                        ? 'DNI: $dni • Asistencia: 0% (Sin clases dictadas)'
                                        : 'DNI: $dni • Asistencia: $attPct% ($totalAbsences faltas de $totalSessions clases)',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      color: isExceeded || isDisapprovedAbsences ? AppColors.error : AppColors.secondary,
                                      fontWeight: isExceeded || isDisapprovedAbsences ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  if (isDisapprovedAbsences)
                                    Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('DESAPROBADO POR INASISTENCIAS', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.error)),
                                    )
                                  else if (isExceeded)
                                    Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text('⚠️ FALTAS EXCEDIDAS ($totalAbsences/$maxAllowed máx)', style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.error)),
                                    ),
                                ],
                              ),
                            ),

                            // Grade Input (56 width)
                            SizedBox(
                              width: 56,
                              child: TextFormField(
                                controller: controller,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  hintText: '0-20',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),

                            const SizedBox(width: 4),

                            // WhatsApp notify button
                            if (phone.toString().isNotEmpty)
                              IconButton(
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.send_to_mobile, color: Color(0xFF16A34A), size: 20),
                                tooltip: 'Notificar por WhatsApp',
                                onPressed: () {
                                  final currentGrade = controller?.text.trim() ?? '';
                                  final cleanPhone = phone.toString().startsWith('+')
                                      ? phone.toString().replaceAll(RegExp(r'[^0-9+]'), '')
                                      : '+51${phone.toString().replaceAll(RegExp(r'[^0-9]'), '')}';
                                  final msg = 'Hola *$name*, te informamos de tu desempeño en el curso *${selectedCourse['title']}* del Ciclo $_activeCycle en la ABC:\n\n'
                                      '*Nota Final:* ${currentGrade.isNotEmpty ? "$currentGrade/20" : "Pendiente"}\n'
                                      '*Asistencia:* $attPct%\n\nBendiciones.';
                                  launchUrl(
                                    Uri.parse('https://api.whatsapp.com/send?phone=$cleanPhone&text=${Uri.encodeComponent(msg)}'),
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Materials Manager Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MATERIALES Y GUÍAS DE ESTUDIO',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '${(selectedCourse['materials'] is List ? (selectedCourse['materials'] as List).length : 0)} archivos',
                      style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.secondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Existing Materials List
                if (selectedCourse['materials'] is List && (selectedCourse['materials'] as List).isNotEmpty) ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: (selectedCourse['materials'] as List).length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final mat = (selectedCourse['materials'] as List)[index];
                      final matName = mat['name'] ?? 'Material de Estudio';
                      final matUrl = mat['url'] ?? '';
                      final isPdf = matName.toString().toLowerCase().endsWith('.pdf') || matUrl.toString().toLowerCase().contains('.pdf');

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isPdf ? Icons.picture_as_pdf : Icons.description,
                              color: isPdf ? const Color(0xFFDC2626) : AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    matName,
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (mat['uploaded_at'] != null)
                                    Text(
                                      'Publicado: ${mat['uploaded_at']}',
                                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.secondary),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.open_in_new, size: 18, color: Color(0xFF2563EB)),
                              tooltip: 'Ver archivo',
                              onPressed: () {
                                if (matUrl.isNotEmpty) {
                                  launchUrl(Uri.parse(matUrl), mode: LaunchMode.externalApplication);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                              tooltip: 'Eliminar material',
                              onPressed: () => _deleteCourseMaterial(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),
                ],

                // Upload New Material Form
                Text(
                  'Subir nuevo archivo o guía',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 10),

                // File Picker Button / Info Card
                InkWell(
                  onTap: _savingMaterial ? null : _pickMaterialFile,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _selectedMaterialFile != null
                          ? AppColors.primaryContainer.withValues(alpha: 0.1)
                          : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selectedMaterialFile != null ? AppColors.primary : const Color(0xFFCBD5E1),
                        style: _selectedMaterialFile != null ? BorderStyle.solid : BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _selectedMaterialFile != null ? AppColors.primary : AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _selectedMaterialFile != null ? Icons.attach_file : Icons.cloud_upload_outlined,
                            color: _selectedMaterialFile != null ? Colors.white : AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedMaterialFile != null
                                    ? _selectedMaterialFile!.name
                                    : 'Seleccionar archivo del dispositivo',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedMaterialFile != null
                                    ? '${((_selectedMaterialFile!.lengthSync() ?? 0) / 1024).toStringAsFixed(1)} KB • Toca para cambiar'
                                    : 'PDF, Documentos, Imágenes, etc.',
                                style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.secondary),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedMaterialFile != null)
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                            tooltip: 'Quitar archivo',
                            onPressed: () {
                              setState(() {
                                _selectedMaterialFile = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _materialTitleController,
                  decoration: InputDecoration(
                    labelText: 'Título / Nombre del Material',
                    hintText: 'Ej. Guía de Estudio - Sesión 1',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _materialUrlController,
                  decoration: InputDecoration(
                    labelText: 'O ingresar enlace directo (opcional si subes archivo)',
                    hintText: 'https://...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                ElevatedButton.icon(
                  onPressed: _savingMaterial ? null : _uploadAndAddMaterial,
                  icon: _savingMaterial
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.cloud_upload, size: 18),
                  label: Text(_savingMaterial ? 'Subiendo archivo al servidor...' : 'Subir & Compartir Material'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // TAB 4: Coordinación ABC (Subtabs: Dashboard, Ciclos, Cursos, Actas, Solicitudes)
  Widget _buildCoordinatorTab() {
    return Column(
      children: [
        // Sub Navigation Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSubNavButton('dashboard', 'Dashboard', Icons.dashboard),
                const SizedBox(width: 6),
                _buildSubNavButton('cycles', 'Ciclos Académicos', Icons.calendar_month),
                const SizedBox(width: 6),
                _buildSubNavButton('courses', 'Cursos & Horarios', Icons.library_books),
                const SizedBox(width: 6),
                _buildSubNavButton('grades', 'Actas de Notas', Icons.description),
                const SizedBox(width: 6),
                _buildSubNavButton('requests', 'Solicitudes Especiales', Icons.how_to_reg, badgeCount: _pendingSpecialRequests.length),
              ],
            ),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_coordSubTab == 'dashboard') _buildCoordDashboard(),
                if (_coordSubTab == 'cycles') _buildCoordCycles(),
                if (_coordSubTab == 'courses') _buildCoordCourses(),
                if (_coordSubTab == 'grades') _buildCoordGrades(),
                if (_coordSubTab == 'requests') _buildCoordRequests(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubNavButton(String key, String title, IconData icon, {int badgeCount = 0}) {
    final isSelected = _coordSubTab == key;
    return InkWell(
      onTap: () => setState(() => _coordSubTab = key),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.primary),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.primary : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCoordRequests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solicitudes de Cursos Especiales',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                Text(
                  'Miembros que solicitaron inscripción en cursos especiales que requieren aprobación.',
                  style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.secondary),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_pendingSpecialRequests.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline, size: 42, color: Color(0xFF16A34A)),
                  const SizedBox(height: 10),
                  Text(
                    'No hay solicitudes especiales pendientes de aprobación.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.secondary, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pendingSpecialRequests.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final req = _pendingSpecialRequests[index];
              final student = req['profiles'] ?? {};
              final course = req['courses'] ?? {};
              final studentName = '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'.trim();
              final dni = student['dni']?.toString() ?? 'Sin DNI';
              final phone = student['phone']?.toString() ?? '';
              final courseTitle = '${course['code'] ?? ''}: ${course['title'] ?? 'Curso'}';
              final courseCycle = course['cycle']?.toString() ?? '';
              final schedule = course['schedule']?.toString() ?? '';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.hourglass_top, size: 12, color: Color(0xFFB45309)),
                              const SizedBox(width: 4),
                              Text(
                                'Pendiente de Aprobación',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFB45309)),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          courseCycle.isNotEmpty ? 'Ciclo $courseCycle' : '',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      studentName.isNotEmpty ? studentName : 'Miembro sin nombre',
                      style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'DNI: $dni ${phone.isNotEmpty ? "• Cel: $phone" : ""}',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.school, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$courseTitle • $schedule',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.close, size: 14, color: AppColors.error),
                          label: const Text('Rechazar', style: TextStyle(fontSize: 12, color: AppColors.error)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _rejectSpecialEnrollment(req),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check, size: 14),
                          label: const Text('Aprobar Matrícula', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _approveSpecialEnrollment(req),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _approveSpecialEnrollment(Map<String, dynamic> req) async {
    final client = Supabase.instance.client;
    try {
      await client.from('enrollments').update({'status': 'aprobado'}).eq('id', req['id']);
      if (mounted) {
        setState(() {
          _pendingSpecialRequests.removeWhere((r) => r['id'] == req['id']);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF16A34A),
            content: Text('¡Matrícula especial aprobada exitosamente!'),
          ),
        );
        _loadData(isSilent: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error al aprobar: $e')),
        );
      }
    }
  }

  Future<void> _rejectSpecialEnrollment(Map<String, dynamic> req) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar Solicitud'),
        content: const Text('¿Estás seguro de rechazar esta solicitud de matrícula especial?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sí, Rechazar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final client = Supabase.instance.client;
    try {
      await client.from('enrollments').delete().eq('id', req['id']);
      if (mounted) {
        setState(() {
          _pendingSpecialRequests.removeWhere((r) => r['id'] == req['id']);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud rechazada y eliminada.')),
        );
        _loadData(isSilent: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error al rechazar: $e')),
        );
      }
    }
  }

  Widget _buildCoordDashboard() {
    final filteredCourses = _allReportsList.where((c) => c['cycle'] == _statsCycle).toList();
    int totalInscriptions = 0;
    final uniqueStudents = <String>{};
    int totalGraded = 0;
    double gradedSum = 0;
    int totalApproved = 0;

    final levelCounts = {'inicial': 0, 'basico': 0, 'intermedio': 0, 'avanzado': 0};

    for (final course in filteredCourses) {
      final students = course['students'] as List;
      totalInscriptions += students.length;
      final lvl = course['level']?.toString();
      if (lvl != null && levelCounts.containsKey(lvl)) {
        levelCounts[lvl] = (levelCounts[lvl] ?? 0) + students.length;
      }

      for (final st in students) {
        if (st['studentId'] != null) uniqueStudents.add(st['studentId'].toString());
        final grade = st['grade'];
        final att = st['attendance'] ?? 100;
        if (grade != null) {
          final gNum = double.tryParse(grade.toString()) ?? 0;
          if (gNum > 0) {
            totalGraded++;
            gradedSum += gNum;
            if (gNum >= 14 && att >= 80) totalApproved++;
          }
        }
      }
    }

    final avgGrade = totalGraded > 0 ? (gradedSum / totalGraded).toStringAsFixed(1) : '0.0';
    final approvalRate = totalGraded > 0 ? ((totalApproved / totalGraded) * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cycle filter dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ciclo de Análisis:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: _statsCycle,
                underline: const SizedBox(),
                items: _allCycles.map((c) {
                  final code = c['cycle']?.toString() ?? '';
                  return DropdownMenuItem<String>(
                    value: code,
                    child: Text('$code (${c['status'] == 'abierto' ? 'Activo' : 'Cerrado'})', style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _statsCycle = val);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 4 KPI Cards in responsive layout
        Row(
          children: [
            Expanded(child: _buildKpiCard('Estudiantes Únicos', '${uniqueStudents.length}', Icons.people)),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Total Matrículas', '$totalInscriptions', Icons.app_registration)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildKpiCard('Promedio General', '$avgGrade / 20', Icons.analytics)),
            const SizedBox(width: 8),
            Expanded(
              child: _buildKpiCard(
                'Tasa de Aprobación',
                '$approvalRate%',
                Icons.verified,
                color: approvalRate >= 75 ? const Color(0xFF16A34A) : const Color(0xFFD97706),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Distribution by levels
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DISTRIBUCIÓN DE ALUMNOS POR NIVEL',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              ...['inicial', 'basico', 'intermedio', 'avanzado'].map((lvl) {
                final count = levelCounts[lvl] ?? 0;
                final pct = totalInscriptions > 0 ? (count / totalInscriptions) : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_levelNames[lvl] ?? lvl, style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600)),
                          Text('$count (${(pct * 100).round()}%)', style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 7,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color ?? AppColors.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.secondary, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordCycles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'CICLOS ACADÉMICOS REGISTRADOS',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _showCreateCycleDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Nuevo Ciclo', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _allCycles.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final c = _allCycles[index];
            final isOpen = c['status'] == 'abierto';

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              c['cycle'] ?? '',
                              style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isOpen ? const Color(0xFF16A34A).withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isOpen ? Icons.lock_open_rounded : Icons.lock_rounded,
                                    size: 11,
                                    color: isOpen ? const Color(0xFF16A34A) : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isOpen ? 'Activo (Abierto)' : 'Cerrado',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isOpen ? const Color(0xFF16A34A) : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isOpen) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: c['enrollment_open'] != false
                                      ? const Color(0xFF0284C7).withValues(alpha: 0.15)
                                      : const Color(0xFFD97706).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      c['enrollment_open'] != false ? Icons.how_to_reg : Icons.lock_clock,
                                      size: 11,
                                      color: c['enrollment_open'] != false ? const Color(0xFF0284C7) : const Color(0xFFD97706),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      c['enrollment_open'] != false ? 'Matrícula Abierta' : 'Matrícula Cerrada',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: c['enrollment_open'] != false ? const Color(0xFF0284C7) : const Color(0xFFD97706),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (c['start_date_virtual'] != null || c['start_date_presencial'] != null) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              if (c['start_date_virtual'] != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.laptop, size: 12, color: Color(0xFF7C3AED)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Virtual: ${c['start_date_virtual']}',
                                      style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.secondary),
                                    ),
                                  ],
                                ),
                              if (c['start_date_presencial'] != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.place_outlined, size: 12, color: Color(0xFF0284C7)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Presencial: ${c['start_date_presencial']}',
                                      style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.secondary),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isOpen) ...[
                        ElevatedButton.icon(
                          icon: Icon(c['enrollment_open'] == false ? Icons.how_to_reg : Icons.lock_clock, size: 13),
                          label: Text(
                            c['enrollment_open'] == false ? 'Abrir Matrícula' : 'Cerrar Matrícula',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c['enrollment_open'] == false ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          onPressed: () => _toggleCycleEnrollment(c),
                        ),
                        const SizedBox(width: 6),
                      ],
                      ElevatedButton.icon(
                        icon: Icon(isOpen ? Icons.lock_outline : Icons.lock_open_rounded, size: 13),
                        label: Text(
                          isOpen ? 'Cerrar Ciclo' : 'Abrir Ciclo',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOpen ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          if (!isOpen) {
                            final openCycle = _allCycles.firstWhere(
                              (x) => x['status'] == 'abierto',
                              orElse: () => {},
                            );
                            if (openCycle.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.error,
                                  content: Text('No se puede abrir este ciclo. El ciclo "${openCycle['cycle']}" ya está abierto. Debes cerrarlo primero.'),
                                ),
                              );
                              return;
                            }
                          }

                          if (isOpen) {
                            final confirmClose = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: Row(
                                  children: const [
                                    Icon(Icons.warning_amber_rounded, color: AppColors.error),
                                    SizedBox(width: 8),
                                    Text('¿Cerrar Ciclo?'),
                                  ],
                                ),
                                content: Text(
                                  '¿Estás seguro de cerrar el ciclo "${c['cycle']}"?\n\n'
                                  'Todos los cursos de este ciclo que aún se encuentren activos se marcarán como cerrados/finalizados para que los alumnos puedan ver y matricularse en el nuevo ciclo.',
                                  style: GoogleFonts.inter(fontSize: 12.5),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                    child: const Text('Sí, Cerrar Ciclo'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmClose != true) return;
                          }

                          final client = Supabase.instance.client;
                          await client
                              .from('academy_cycles')
                              .update({'status': isOpen ? 'cerrado' : 'abierto'})
                              .eq('cycle', c['cycle']);

                          if (isOpen) {
                            // Mark all courses in this cycle inactive
                            await client
                              .from('courses')
                              .update({'is_active': false})
                              .eq('cycle', c['cycle']);
                          }

                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                backgroundColor: isOpen ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                content: Text(isOpen
                                    ? 'Ciclo ${c['cycle']} cerrado correctamente.'
                                    : 'Ciclo ${c['cycle']} abierto y activado.'),
                              ),
                            );
                            _loadData(isSilent: true);
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFDC2626)),
                        tooltip: 'Eliminar ciclo',
                        onPressed: () => _deleteCycle(c),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _deleteCycle(Map<String, dynamic> cycleData) async {
    final cycleName = cycleData['cycle']?.toString() ?? '';
    if (cycleName.isEmpty) return;

    final client = Supabase.instance.client;

    // Check if there are courses in this cycle
    final coursesInCycle = await client
        .from('courses')
        .select('id, title')
        .eq('cycle', cycleName);

    final coursesList = List<Map<String, dynamic>>.from(coursesInCycle as List);
    final coursesCount = coursesList.length;

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.delete_forever, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('¿Eliminar Ciclo?'),
          ],
        ),
        content: Text(
          coursesCount > 0
              ? 'El ciclo "$cycleName" tiene $coursesCount curso(s) registrado(s).\n\n¿Estás seguro de eliminar permanentemente este ciclo, todos sus cursos, actas e inscripciones asociadas? Esta acción no se puede deshacer.'
              : '¿Estás seguro de que deseas eliminar permanentemente el ciclo "$cycleName"?',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Sí, Eliminar Todo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (coursesCount > 0) {
        final courseIds = coursesList.map((c) => c['id']).toList();
        // 1. Delete attendance records for these courses
        await client.from('academy_attendance').delete().inFilter('course_id', courseIds);
        // 2. Delete enrollments for these courses
        await client.from('enrollments').delete().inFilter('course_id', courseIds);
        // 3. Delete courses
        await client.from('courses').delete().eq('cycle', cycleName);
      }

      // 4. Delete the cycle
      await client.from('academy_cycles').delete().eq('cycle', cycleName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16A34A),
            content: Text('Ciclo "$cycleName" y sus cursos eliminados exitosamente.'),
          ),
        );
        _loadData(isSilent: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Error al eliminar ciclo: $e'),
          ),
        );
      }
    }
  }

  void _showCreateCycleDialog() {
    final openCycle = _allCycles.firstWhere(
      (x) => x['status'] == 'abierto',
      orElse: () => {},
    );
    if (openCycle.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppColors.error),
              SizedBox(width: 8),
              Text('Ciclo Activo en Curso'),
            ],
          ),
          content: Text(
            'Actualmente el ciclo "${openCycle['cycle']}" se encuentra ABIERTO.\n\nNo es posible abrir un nuevo ciclo si ya existe uno abierto. Debes cerrar el ciclo actual antes de crear y abrir uno nuevo.',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    final cycleCodeCtrl = TextEditingController();
    DateTime? selectedVirtualDate;
    DateTime? selectedPresencialDate;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final now = DateTime.now();
          final dateFormatter = DateFormat('yyyy-MM-dd');

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Crear Ciclo Académico',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ingresa el código y las fechas oficiales de apertura para las modalidades de estudio.',
                    style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.secondary),
                  ),
                  const SizedBox(height: 16),

                  // Cycle Code Input
                  TextField(
                    controller: cycleCodeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Código / Nombre del Ciclo *',
                      hintText: 'Ej. 2026-IV',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Start Virtual Date Picker
                  Text(
                    'Fecha de Apertura Virtual *',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedVirtualDate ?? now,
                        firstDate: DateTime(now.year - 1),
                        lastDate: DateTime(now.year + 2),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedVirtualDate = picked;
                          // Auto calculate Presencial Start (+3 days, typically Sunday)
                          selectedPresencialDate = picked.add(const Duration(days: 3));
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.laptop, size: 18, color: Color(0xFF7C3AED)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedVirtualDate != null
                                  ? dateFormatter.format(selectedVirtualDate!)
                                  : 'Seleccionar fecha (Jueves)...',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: selectedVirtualDate != null ? AppColors.primary : AppColors.secondary,
                                fontWeight: selectedVirtualDate != null ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                          const Icon(Icons.calendar_month, size: 16, color: AppColors.secondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Start Presencial Date Picker
                  Text(
                    'Fecha de Apertura Presencial *',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedPresencialDate ?? (selectedVirtualDate?.add(const Duration(days: 3)) ?? now),
                        firstDate: DateTime(now.year - 1),
                        lastDate: DateTime(now.year + 2),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedPresencialDate = picked;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 18, color: Color(0xFF0284C7)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedPresencialDate != null
                                  ? dateFormatter.format(selectedPresencialDate!)
                                  : 'Seleccionar fecha (Domingo)...',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: selectedPresencialDate != null ? AppColors.primary : AppColors.secondary,
                                fontWeight: selectedPresencialDate != null ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                          const Icon(Icons.calendar_month, size: 16, color: AppColors.secondary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final code = cycleCodeCtrl.text.trim();
                        final messenger = ScaffoldMessenger.of(context);
                        if (code.isEmpty) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Ingresa el código del ciclo')),
                          );
                          return;
                        }

                        if (selectedVirtualDate == null || selectedPresencialDate == null) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Selecciona ambas fechas de apertura')),
                          );
                          return;
                        }

                        setDialogState(() => isSubmitting = true);
                        try {
                          final formatted = code.toUpperCase().trim();
                          final client = Supabase.instance.client;
                          await client.from('academy_cycles').insert({
                            'cycle': formatted,
                            'status': 'abierto',
                            'start_date_virtual': dateFormatter.format(selectedVirtualDate!),
                            'start_date_presencial': dateFormatter.format(selectedPresencialDate!),
                          });

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                          messenger.showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF16A34A),
                              content: Text('¡Ciclo $formatted creado y habilitado! Notificando a los miembros por correo...'),
                            ),
                          );

                          // Notify registered members via email in background
                          Future.microtask(() async {
                            try {
                              final profilesRes = await client
                                  .from('profiles')
                                  .select('email, first_name, last_name')
                                  .not('email', 'is', null);

                              final List<dynamic> profiles = profilesRes as List<dynamic>;
                              for (final p in profiles) {
                                final email = p['email']?.toString().trim();
                                if (email != null &&
                                    email.contains('@') &&
                                    !email.endsWith('@alianzachaclacayo.pe')) {
                                  final name = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();
                                  ResendEmailService.sendNewCycleAnnouncementEmail(
                                    to: email,
                                    memberName: name.isNotEmpty ? name : 'Hermano(a)',
                                    cycleName: 'Ciclo $formatted',
                                    startDate: 'Virtual: ${dateFormatter.format(selectedVirtualDate!)} • Presencial: ${dateFormatter.format(selectedPresencialDate!)}',
                                  );
                                }
                              }
                            } catch (e) {
                              debugPrint('Error broadcasting cycle notification: $e');
                            }
                          });

                          if (mounted) {
                            _loadData(isSilent: true);
                          }
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          messenger.showSnackBar(
                            SnackBar(backgroundColor: AppColors.error, content: Text('Error al crear ciclo: $e')),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isSubmitting
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Crear Ciclo'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCoordCourses() {
    final availableCycles = _allCycles.map((c) => c['cycle']?.toString() ?? '').where((c) => c.isNotEmpty).toList();
    if (availableCycles.isNotEmpty && !availableCycles.contains(_coursesCycle)) {
      _coursesCycle = availableCycles.first;
    }

    final filteredCourses = _allReportsList.where((c) => c['cycle'] == _coursesCycle).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cycle filter and New Course Button Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text('Ciclo:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: availableCycles.contains(_coursesCycle)
                          ? _coursesCycle
                          : (availableCycles.isNotEmpty ? availableCycles.first : null),
                      underline: const SizedBox(),
                      items: availableCycles.map((c) {
                        final isCycleOpen = _allCycles.any((x) => x['cycle'] == c && x['status'] == 'abierto');
                        return DropdownMenuItem<String>(
                          value: c,
                          child: Text(
                            '$c (${isCycleOpen ? "Activo" : "Cerrado"})',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isCycleOpen ? FontWeight.bold : FontWeight.normal,
                              color: isCycleOpen ? const Color(0xFF16A34A) : AppColors.primary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _coursesCycle = val);
                      },
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showCreateCourseDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nuevo Curso', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (filteredCourses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(Icons.menu_book, size: 32, color: AppColors.secondary),
                const SizedBox(height: 8),
                Text(
                  'No hay cursos registrados para el ciclo $_coursesCycle',
                  style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.secondary),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredCourses.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final c = filteredCourses[index];
              final teacherName = c['teacherName'] ?? 'Sin docente asignado';
              final isActive = c['isActive'] == true;
              final isVirtual = c['isVirtual'] == true;
              final studentsCount = (c['students'] as List?)?.length ?? 0;
              final hasStarted = _hasCourseStarted(c);

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isActive ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isVirtual ? Colors.purple.withValues(alpha: 0.12) : AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isVirtual ? 'Virtual' : 'Presencial',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: isVirtual ? Colors.purple : AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive
                                ? (hasStarted ? const Color(0xFF16A34A).withValues(alpha: 0.12) : const Color(0xFF0284C7).withValues(alpha: 0.12))
                                : Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isActive
                                ? (hasStarted ? 'En Curso (Iniciado)' : 'Por Iniciar')
                                : 'Cerrado / Finalizado',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: isActive
                                  ? (hasStarted ? const Color(0xFF16A34A) : const Color(0xFF0284C7))
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$studentsCount Alumnos',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${c['code']} - ${c['title']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isActive ? AppColors.primary : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Docente: $teacherName • ${c['schedule'] ?? ""}',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary),
                    ),
                    if (_getCourseStartDate(c) != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.event_available, size: 12, color: AppColors.secondary),
                          const SizedBox(width: 4),
                          Text(
                            'Inicio: ${DateFormat("dd/MM/yyyy").format(_getCourseStartDate(c)!)}${c['manually_opened'] == true ? " (Abierto manualmente)" : ""}',
                            style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.secondary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                    if (c['rescheduledDate'] != null && c['rescheduledDate'].toString().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event_repeat, size: 14, color: Color(0xFFDC2626)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Sesión Reprogramada: ${c['rescheduledDate']}${c['rescheduledTime'] != null && c['rescheduledTime'].toString().isNotEmpty ? " a las ${c['rescheduledTime']}" : ""}${c['rescheduledReason'] != null && c['rescheduledReason'].toString().isNotEmpty ? " (${c['rescheduledReason']})" : ""}',
                                style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF991B1B), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.fact_check_outlined, size: 14),
                              label: const Text('Asistencias', style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AsistenciaClaseScreen(
                                      courseId: c['id'],
                                      courseTitle: '${c['code']}: ${c['title']}',
                                      schedule: c['schedule'] ?? '',
                                      level: c['level'] ?? 'inicial',
                                    ),
                                  ),
                                );
                                _loadData(isSilent: true);
                              },
                            ),
                            if (!hasStarted) ...[
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.play_circle_fill_rounded, size: 13),
                                label: const Text('Abrir Curso', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A34A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _openCourseByCoordinator(c),
                              ),
                            ] else if (isActive) ...[
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.lock, size: 13),
                                label: const Text('Cerrar Curso', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD97706),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _closeCourseByCoordinator(c),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isActive ? 'Activo' : 'Inactivo',
                              style: GoogleFonts.inter(fontSize: 10.5, color: isActive ? const Color(0xFF16A34A) : Colors.grey),
                            ),
                            Switch(
                              value: isActive,
                              activeThumbColor: const Color(0xFF16A34A),
                              onChanged: (val) async {
                                final client = Supabase.instance.client;
                                await client.from('courses').update({'is_active': val}).eq('id', c['id']);
                                _loadData(isSilent: true);
                              },
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                              tooltip: 'Editar Curso',
                              onPressed: () => _showEditCourseDialog(c),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFDC2626)),
                              tooltip: 'Eliminar Curso',
                              onPressed: () => _deleteCourseByCoordinator(c),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _deleteCourseByCoordinator(Map<String, dynamic> course) async {
    final courseId = course['id'];
    final code = course['code'] ?? '';
    final title = course['title'] ?? '';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.delete_forever, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('¿Eliminar Curso?'),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar permanentemente el curso "$code: $title"?\n\n'
          'Esta acción no se puede deshacer y eliminará las asistencias y matrículas asociadas.',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Sí, Eliminar Curso', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final client = Supabase.instance.client;
    try {
      // 1. Delete attendances
      await client.from('academy_attendance').delete().eq('course_id', courseId);
      // 2. Delete enrollments
      await client.from('enrollments').delete().eq('course_id', courseId);
      // 3. Delete course
      await client.from('courses').delete().eq('id', courseId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16A34A),
            content: Text('¡Curso "$code: $title" eliminado exitosamente!'),
          ),
        );
        _loadData(isSilent: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error al eliminar curso: $e')),
        );
      }
    }
  }

  void _showEditCourseDialog(Map<String, dynamic> course) {
    final daysOfWeek = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];

    final courseId = course['id'];
    final codeCtrl = TextEditingController(text: course['code'] ?? '');
    final titleCtrl = TextEditingController(text: course['title'] ?? '');
    String level = (course['level'] ?? 'inicial').toString().toLowerCase();

    // Parse schedule
    final currentSchedule = (course['schedule'] ?? '').toString();
    String selectedDay = 'Domingo';
    for (final d in daysOfWeek) {
      if (currentSchedule.contains(d)) {
        selectedDay = d;
        break;
      }
    }

    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 45);
    final timeMatch = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)?', caseSensitive: false).firstMatch(currentSchedule);
    if (timeMatch != null) {
      int hour = int.tryParse(timeMatch.group(1)!) ?? 9;
      final int minute = int.tryParse(timeMatch.group(2)!) ?? 0;
      final period = timeMatch.group(3)?.toUpperCase();
      if (period == 'PM' && hour < 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
      selectedTime = TimeOfDay(hour: hour, minute: minute);
    }

    String formatCourseSchedule(String day, TimeOfDay t) {
      final hour12 = (t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod).toString().padLeft(2, '0');
      final minute = t.minute.toString().padLeft(2, '0');
      final amPm = t.period == DayPeriod.am ? 'AM' : 'PM';
      return '$day • $hour12:$minute $amPm';
    }

    final scheduleCtrl = TextEditingController(
      text: currentSchedule.isNotEmpty ? currentSchedule : formatCourseSchedule(selectedDay, selectedTime),
    );

    bool isVirtual = course['is_virtual'] == true || course['isVirtual'] == true;
    final classroomCtrl = TextEditingController(text: course['classroom'] ?? '');
    final virtualPlatformCtrl = TextEditingController(text: course['virtual_platform'] ?? course['virtualPlatform'] ?? 'Zoom');
    final virtualLinkCtrl = TextEditingController(text: course['virtual_link'] ?? course['virtualLink'] ?? '');
    final bookTitleCtrl = TextEditingController(text: course['book_title'] ?? course['bookTitle'] ?? '');
    final bookStoreCtrl = TextEditingController(text: course['book_store_info'] ?? course['bookStoreInfo'] ?? '');

    String? teacherId = course['teacher_id'] ?? course['teacherId'];

    bool isSpecialCourse = level == 'especial' || course['is_special'] == true || course['isSpecial'] == true;

    final existingStartDate = (course['start_date'] ?? course['startDate'])?.toString();
    DateTime? customStartDate;
    if (existingStartDate != null && existingStartDate.isNotEmpty) {
      try {
        customStartDate = DateTime.parse(existingStartDate);
      } catch (_) {}
    }

    // Rescheduling fields
    final existingRescheduledDate = (course['rescheduled_date'] ?? course['rescheduledDate'])?.toString();
    bool hasRescheduled = existingRescheduledDate != null && existingRescheduledDate.isNotEmpty;
    DateTime rescheduledDate = DateTime.now();
    if (hasRescheduled) {
      try {
        rescheduledDate = DateTime.parse(existingRescheduledDate);
      } catch (_) {
        rescheduledDate = DateTime.now();
      }
    }
    TimeOfDay rescheduledTime = selectedTime;
    final existingRescheduledTime = (course['rescheduled_time'] ?? course['rescheduledTime'])?.toString();
    if (existingRescheduledTime != null && existingRescheduledTime.isNotEmpty) {
      final resMatch = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)?', caseSensitive: false).firstMatch(existingRescheduledTime);
      if (resMatch != null) {
        int h = int.tryParse(resMatch.group(1)!) ?? 9;
        final int m = int.tryParse(resMatch.group(2)!) ?? 0;
        final p = resMatch.group(3)?.toUpperCase();
        if (p == 'PM' && h < 12) h += 12;
        if (p == 'AM' && h == 12) h = 0;
        rescheduledTime = TimeOfDay(hour: h, minute: m);
      }
    }
    final rescheduledReasonCtrl = TextEditingController(
      text: (course['rescheduled_reason'] ?? course['rescheduledReason'] ?? '').toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.edit_note, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Editar Curso: ${course['code'] ?? ""}',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
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
                  Text('INFORMACIÓN BÁSICA', style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Código del Curso *',
                      labelStyle: const TextStyle(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Título del Curso *',
                      labelStyle: const TextStyle(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: level,
                    decoration: InputDecoration(
                      labelText: 'Nivel del Curso *',
                      labelStyle: const TextStyle(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'inicial', child: Text('Inicial / Vida Nueva', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'basico', child: Text('Básico', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'intermedio', child: Text('Intermedio', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'avanzado', child: Text('Avanzado', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'especial', child: Text('Especial (Abierto / Requiere Aprobación)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706)))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          level = val;
                          isSpecialCourse = level == 'especial';
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 14),

                  Text('MODALIDAD *', style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Presencial', style: TextStyle(fontSize: 11.5))),
                          selected: !isVirtual,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(color: !isVirtual ? Colors.white : AppColors.primary, fontWeight: FontWeight.bold),
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() {
                                isVirtual = false;
                                selectedDay = 'Domingo';
                                selectedTime = const TimeOfDay(hour: 9, minute: 45);
                                scheduleCtrl.text = formatCourseSchedule(selectedDay, selectedTime);
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Virtual', style: TextStyle(fontSize: 11.5))),
                          selected: isVirtual,
                          selectedColor: const Color(0xFF7C3AED),
                          labelStyle: TextStyle(color: isVirtual ? Colors.white : const Color(0xFF7C3AED), fontWeight: FontWeight.bold),
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() {
                                isVirtual = true;
                                selectedDay = 'Miércoles';
                                selectedTime = const TimeOfDay(hour: 20, minute: 0);
                                scheduleCtrl.text = formatCourseSchedule(selectedDay, selectedTime);
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Text('HORARIO SEMANAL *', style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          initialValue: daysOfWeek.contains(selectedDay) ? selectedDay : daysOfWeek.first,
                          decoration: InputDecoration(
                            labelText: 'Día habitual',
                            labelStyle: const TextStyle(fontSize: 11.5),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: daysOfWeek.map((d) {
                            return DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                selectedDay = val;
                                scheduleCtrl.text = formatCourseSchedule(selectedDay, selectedTime);
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(context: ctx, initialTime: selectedTime);
                            if (picked != null) {
                              setDialogState(() {
                                selectedTime = picked;
                                scheduleCtrl.text = formatCourseSchedule(selectedDay, selectedTime);
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, size: 16, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Hora', style: GoogleFonts.inter(fontSize: 9, color: Colors.grey.shade600)),
                                      Text(
                                        '${(selectedTime.hourOfPeriod == 0 ? 12 : selectedTime.hourOfPeriod).toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')} ${selectedTime.period == DayPeriod.am ? 'AM' : 'PM'}',
                                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            scheduleCtrl.text,
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  if (!isVirtual) ...[
                    TextField(
                      controller: classroomCtrl,
                      decoration: InputDecoration(
                        labelText: 'Salón / Aula Presencial',
                        hintText: 'Ej. Aula 101 / Auditorio',
                        labelStyle: const TextStyle(fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: virtualPlatformCtrl,
                      decoration: InputDecoration(
                        labelText: 'Plataforma Virtual (Zoom / Meet)',
                        labelStyle: const TextStyle(fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: virtualLinkCtrl,
                      decoration: InputDecoration(
                        labelText: 'Enlace de Reunión (URL)',
                        hintText: 'https://zoom.us/j/...',
                        labelStyle: const TextStyle(fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  Text('DOCENTE ASIGNADO', style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String?>(
                    initialValue: _teachersList.any((t) => t['id'] == teacherId) ? teacherId : null,
                    isExpanded: true,
                    hint: const Text('Sin docente asignado', style: TextStyle(fontSize: 12)),
                    decoration: InputDecoration(
                      labelStyle: const TextStyle(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Sin docente asignado (Pendiente)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                      ..._teachersList.map((t) {
                        return DropdownMenuItem<String?>(
                          value: t['id'],
                          child: Text('${t['first_name'] ?? ''} ${t['last_name'] ?? ''}'.trim(), style: const TextStyle(fontSize: 12)),
                        );
                      }),
                    ],
                    onChanged: (val) => setDialogState(() => teacherId = val),
                  ),

                  const SizedBox(height: 14),

                  // FECHA DE INICIO ESPECÍFICA (OPCIONAL)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.event_available, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Fecha de Inicio del Curso',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                            if (customStartDate != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                                tooltip: 'Restablecer a fecha del ciclo',
                                onPressed: () => setDialogState(() => customStartDate = null),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          customStartDate != null
                              ? 'Inicio programado: ${DateFormat("dd/MM/yyyy").format(customStartDate!)}'
                              : 'Por defecto usa la fecha del ciclo. Personalízala si este curso inicia en una fecha distinta (ej. 07/10/2026).',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: customStartDate ?? DateTime.now(),
                              firstDate: DateTime(2025),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                              locale: const Locale('es', 'PE'),
                            );
                            if (picked != null) {
                              setDialogState(() => customStartDate = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_today, size: 14),
                          label: Text(
                            customStartDate != null
                                ? 'Cambiar Fecha (${DateFormat("dd/MM/yyyy").format(customStartDate!)})'
                                : 'Establecer Fecha Específica',
                            style: const TextStyle(fontSize: 11.5),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // REPROGRAMACIÓN DE SESIÓN
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hasRescheduled ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasRescheduled ? const Color(0xFFFCA5A5) : const Color(0xFFCBD5E1),
                        width: hasRescheduled ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.event_repeat, size: 18, color: hasRescheduled ? const Color(0xFFDC2626) : AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Reprogramación de Sesión',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: hasRescheduled ? const Color(0xFF991B1B) : AppColors.primary,
                                ),
                              ),
                            ),
                            Switch(
                              value: hasRescheduled,
                              activeThumbColor: const Color(0xFFDC2626),
                              onChanged: (val) {
                                setDialogState(() {
                                  hasRescheduled = val;
                                });
                              },
                            ),
                          ],
                        ),
                        if (hasRescheduled) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Indica la fecha y hora específica para la sesión reprogramada (por feriado o evento).',
                            style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF7F1D1D)),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: ctx,
                                      initialDate: rescheduledDate,
                                      firstDate: DateTime(2025),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                      locale: const Locale('es', 'PE'),
                                    );
                                    if (picked != null) {
                                      setDialogState(() => rescheduledDate = picked);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: const Color(0xFFFCA5A5)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_month, size: 16, color: Color(0xFFDC2626)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            DateFormat('dd/MM/yyyy', 'es_PE').format(rescheduledDate),
                                            style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF991B1B)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showTimePicker(context: ctx, initialTime: rescheduledTime);
                                    if (picked != null) {
                                      setDialogState(() => rescheduledTime = picked);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: const Color(0xFFFCA5A5)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 16, color: Color(0xFFDC2626)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '${(rescheduledTime.hourOfPeriod == 0 ? 12 : rescheduledTime.hourOfPeriod).toString().padLeft(2, '0')}:${rescheduledTime.minute.toString().padLeft(2, '0')} ${rescheduledTime.period == DayPeriod.am ? 'AM' : 'PM'}',
                                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF991B1B)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: rescheduledReasonCtrl,
                            decoration: InputDecoration(
                              labelText: 'Motivo de Reprogramación',
                              hintText: 'Ej. Feriado / Conferencia / Aniversario',
                              labelStyle: const TextStyle(fontSize: 11.5),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              fillColor: Colors.white,
                              filled: true,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: bookTitleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Libro Requerido (Opcional)',
                      labelStyle: const TextStyle(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: bookStoreCtrl,
                    decoration: InputDecoration(
                      labelText: 'Librería / Adquisición (Opcional)',
                      labelStyle: const TextStyle(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save, size: 16),
              label: const Text('Guardar Cambios'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                if (codeCtrl.text.trim().isEmpty || titleCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(backgroundColor: AppColors.error, content: Text('El código y el título no pueden estar vacíos.')),
                  );
                  return;
                }

                final messenger = ScaffoldMessenger.of(context);
                try {
                  final client = Supabase.instance.client;
                  final formattedResTime = '${(rescheduledTime.hourOfPeriod == 0 ? 12 : rescheduledTime.hourOfPeriod).toString().padLeft(2, '0')}:${rescheduledTime.minute.toString().padLeft(2, '0')} ${rescheduledTime.period == DayPeriod.am ? 'AM' : 'PM'}';
                  final formattedResDate = DateFormat('yyyy-MM-dd').format(rescheduledDate);

                  await client.from('courses').update({
                    'code': codeCtrl.text.trim(),
                    'title': titleCtrl.text.trim(),
                    'level': level,
                    'schedule': scheduleCtrl.text.trim(),
                    'teacher_id': teacherId,
                    'is_virtual': isVirtual,
                    'classroom': isVirtual ? null : (classroomCtrl.text.trim().isNotEmpty ? classroomCtrl.text.trim() : 'Presencial'),
                    'virtual_platform': isVirtual ? virtualPlatformCtrl.text.trim() : null,
                    'virtual_link': isVirtual ? virtualLinkCtrl.text.trim() : null,
                    'is_special': isSpecialCourse,
                    'requires_approval': isSpecialCourse,
                    'book_title': bookTitleCtrl.text.trim().isNotEmpty ? bookTitleCtrl.text.trim() : null,
                    'book_store_info': bookStoreCtrl.text.trim().isNotEmpty ? bookStoreCtrl.text.trim() : null,
                    'rescheduled_date': hasRescheduled ? formattedResDate : null,
                    'rescheduled_time': hasRescheduled ? formattedResTime : null,
                    'rescheduled_reason': hasRescheduled && rescheduledReasonCtrl.text.trim().isNotEmpty ? rescheduledReasonCtrl.text.trim() : null,
                    'start_date': customStartDate != null ? DateFormat('yyyy-MM-dd').format(customStartDate!) : null,
                  }).eq('id', courseId);

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF16A34A),
                        content: Text('Curso actualizado exitosamente'),
                      ),
                    );
                    _loadData(isSilent: true);
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(backgroundColor: AppColors.error, content: Text('Error al actualizar curso: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateCourseDialog() {
    final daysOfWeek = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    String? selectedCurriculumCode;
    final codeCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    String selectedDay = 'Domingo';
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 45);

    String formatCourseSchedule(String day, TimeOfDay t) {
      final hour12 = (t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod).toString().padLeft(2, '0');
      final minute = t.minute.toString().padLeft(2, '0');
      final amPm = t.period == DayPeriod.am ? 'AM' : 'PM';
      return '$day • $hour12:$minute $amPm';
    }

    final scheduleCtrl = TextEditingController(text: formatCourseSchedule(selectedDay, selectedTime));
    final classroomCtrl = TextEditingController();
    final virtualPlatformCtrl = TextEditingController(text: 'Zoom');
    final virtualLinkCtrl = TextEditingController();
    final bookTitleCtrl = TextEditingController();
    final bookStoreCtrl = TextEditingController();
    String level = 'inicial';
    bool isVirtual = false;
    String? teacherId;
    bool isCustomCourse = false;
    DateTime? customStartDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Crear Nuevo Curso',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course type selector
                  Text(
                    'TIPO DE CURSO *',
                    style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Currículo ABC', style: TextStyle(fontSize: 11.5))),
                          selected: !isCustomCourse,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: !isCustomCourse ? Colors.white : AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() {
                                isCustomCourse = false;
                                if (selectedCurriculumCode != null) {
                                  final found = abcCurriculum.firstWhere((s) => s.code == selectedCurriculumCode);
                                  codeCtrl.text = found.code;
                                  titleCtrl.text = found.title;
                                  level = found.level;
                                }
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Nuevo / Especial', style: TextStyle(fontSize: 11.5))),
                          selected: isCustomCourse,
                          selectedColor: const Color(0xFFD97706),
                          labelStyle: TextStyle(
                            color: isCustomCourse ? Colors.white : const Color(0xFFD97706),
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() {
                                isCustomCourse = true;
                                if (level != 'especial' && level != 'inicial' && level != 'basico' && level != 'intermedio' && level != 'avanzado') {
                                  level = 'especial';
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (!isCustomCourse) ...[
                    Text(
                      'SELECCIONA MATERIA DEL CURRÍCULO *',
                      style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCurriculumCode,
                      isExpanded: true,
                      hint: const Text('Elige una materia de la ABC...', style: TextStyle(fontSize: 12)),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: abcCurriculum.map((subj) {
                        return DropdownMenuItem<String>(
                          value: subj.code,
                          child: Text(
                            '${subj.code}: ${subj.title} (${subj.level.toUpperCase()})',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final found = abcCurriculum.firstWhere((s) => s.code == val);
                          setDialogState(() {
                            selectedCurriculumCode = val;
                            codeCtrl.text = found.code;
                            titleCtrl.text = found.title;
                            level = found.level;
                          });
                        }
                      },
                    ),
                  ] else ...[
                    Text(
                      'DATOS DEL NUEVO CURSO *',
                      style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFFD97706)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Código del Curso *',
                        hintText: 'Ej: ESP01, LBR01, TEOL01',
                        labelStyle: const TextStyle(fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nombre / Título del Curso *',
                        hintText: 'Ej: Taller de Liderazgo Ministerial',
                        labelStyle: const TextStyle(fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: level,
                      decoration: InputDecoration(
                        labelText: 'Nivel del Curso *',
                        labelStyle: const TextStyle(fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'inicial', child: Text('Inicial / Vida Nueva', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'basico', child: Text('Básico', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'intermedio', child: Text('Intermedio', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'avanzado', child: Text('Avanzado', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'especial', child: Text('Especial (Abierto / Requiere Aprobación)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706)))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => level = val);
                        }
                      },
                    ),
                    if (level == 'especial') ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, size: 14, color: Color(0xFFB45309)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Este curso especial no requiere prerrequisitos y estará disponible para toda la congregación, pero la matrícula quedará pendiente de aprobación por el pastor o coordinación.',
                                style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF92400E)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 12),

                  // Modality Selection Toggle (Presencial vs Virtual)
                  Text(
                    'MODALIDAD DEL CURSO *',
                    style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Presencial', style: TextStyle(fontSize: 11.5))),
                          selected: !isVirtual,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: !isVirtual ? Colors.white : AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() {
                                isVirtual = false;
                                selectedDay = 'Domingo';
                                selectedTime = const TimeOfDay(hour: 9, minute: 45);
                                scheduleCtrl.text = formatCourseSchedule(selectedDay, selectedTime);
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Virtual', style: TextStyle(fontSize: 11.5))),
                          selected: isVirtual,
                          selectedColor: const Color(0xFF7C3AED),
                          labelStyle: TextStyle(
                            color: isVirtual ? Colors.white : const Color(0xFF7C3AED),
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() {
                                isVirtual = true;
                                selectedDay = 'Miércoles';
                                selectedTime = const TimeOfDay(hour: 20, minute: 0);
                                scheduleCtrl.text = formatCourseSchedule(selectedDay, selectedTime);
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Day and Time Pickers
                  Text(
                    'HORARIO SEMANAL DEL CURSO *',
                    style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Day Dropdown
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          initialValue: daysOfWeek.contains(selectedDay) ? selectedDay : daysOfWeek.first,
                          decoration: InputDecoration(
                            labelText: 'Día habitual *',
                            labelStyle: const TextStyle(fontSize: 11.5),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: daysOfWeek.map((d) {
                            return DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                selectedDay = val;
                                scheduleCtrl.text = formatCourseSchedule(selectedDay, selectedTime);
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Time Selector
                      Expanded(
                        flex: 2,
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: ctx,
                              initialTime: selectedTime,
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedTime = picked;
                                scheduleCtrl.text = formatCourseSchedule(selectedDay, selectedTime);
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, size: 16, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Hora', style: GoogleFonts.inter(fontSize: 9, color: Colors.grey.shade600)),
                                      Text(
                                        '${(selectedTime.hourOfPeriod == 0 ? 12 : selectedTime.hourOfPeriod).toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')} ${selectedTime.period == DayPeriod.am ? 'AM' : 'PM'}',
                                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            scheduleCtrl.text,
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // If Presencial: Classroom, If Virtual: Platform & Link
                  if (!isVirtual) ...[
                    TextField(
                      controller: classroomCtrl,
                      decoration: InputDecoration(
                        labelText: 'Salón / Aula Presencial',
                        hintText: 'Ej. Aula 101 / Auditorio',
                        labelStyle: const TextStyle(fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: virtualPlatformCtrl,
                      decoration: InputDecoration(
                        labelText: 'Plataforma Virtual (Zoom / Meet)',
                        labelStyle: const TextStyle(fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: virtualLinkCtrl,
                      decoration: InputDecoration(
                        labelText: 'Enlace de Reunión (URL)',
                        hintText: 'https://zoom.us/j/...',
                        labelStyle: const TextStyle(fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Assign Teacher Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: teacherId,
                    isExpanded: true,
                    hint: const Text('Asignar Docente...', style: TextStyle(fontSize: 12)),
                    decoration: InputDecoration(
                      labelText: 'Docente Asignado',
                      labelStyle: const TextStyle(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: _teachersList.map((t) {
                      return DropdownMenuItem<String>(
                        value: t['id'],
                        child: Text('${t['first_name'] ?? ''} ${t['last_name'] ?? ''}'.trim(), style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => teacherId = val),
                  ),

                  const SizedBox(height: 10),

                  // Book and Bookstore fields
                  TextField(
                    controller: bookTitleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Libro Requerido (Opcional)',
                      labelStyle: const TextStyle(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: bookStoreCtrl,
                    decoration: InputDecoration(
                      labelText: 'Librería / Adquisición (Opcional)',
                      labelStyle: const TextStyle(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // FECHA DE INICIO ESPECÍFICA (OPCIONAL)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.event_available, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Fecha de Inicio del Curso (Opcional)',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                            if (customStartDate != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                                tooltip: 'Restablecer a fecha del ciclo',
                                onPressed: () => setDialogState(() => customStartDate = null),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          customStartDate != null
                              ? 'Inicio programado: ${DateFormat("dd/MM/yyyy").format(customStartDate!)}'
                              : 'Por defecto iniciará según la fecha general del ciclo. Puedes indicar una fecha distinta (ej. 07/10/2026).',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: customStartDate ?? DateTime.now(),
                              firstDate: DateTime(2025),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                              locale: const Locale('es', 'PE'),
                            );
                            if (picked != null) {
                              setDialogState(() => customStartDate = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_today, size: 14),
                          label: Text(
                            customStartDate != null
                                ? 'Cambiar Fecha (${DateFormat("dd/MM/yyyy").format(customStartDate!)})'
                                : 'Establecer Fecha Específica',
                            style: const TextStyle(fontSize: 11.5),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (codeCtrl.text.isNotEmpty && titleCtrl.text.isNotEmpty) {
                  final client = Supabase.instance.client;
                  final isSpecialCourse = level == 'especial';
                  await client.from('courses').insert({
                    'code': codeCtrl.text.trim(),
                    'title': titleCtrl.text.trim(),
                    'level': level,
                    'schedule': scheduleCtrl.text.trim(),
                    'cycle': _activeCycle,
                    'teacher_id': teacherId,
                    'is_virtual': isVirtual,
                    'classroom': isVirtual ? null : (classroomCtrl.text.trim().isNotEmpty ? classroomCtrl.text.trim() : 'Presencial'),
                    'virtual_platform': isVirtual ? virtualPlatformCtrl.text.trim() : null,
                    'virtual_link': isVirtual ? virtualLinkCtrl.text.trim() : null,
                    'book_title': bookTitleCtrl.text.trim().isNotEmpty ? bookTitleCtrl.text.trim() : null,
                    'book_store_info': bookStoreCtrl.text.trim().isNotEmpty ? bookStoreCtrl.text.trim() : null,
                    'is_active': true,
                    'is_special': isSpecialCourse,
                    'requires_approval': isSpecialCourse,
                    'start_date': customStartDate != null ? DateFormat('yyyy-MM-dd').format(customStartDate!) : null,
                  });
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                  if (mounted) {
                    _loadData(isSilent: true);
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoordGrades() {
    final availableCycles = _allCycles.map((c) => c['cycle'].toString()).toSet().toList();
    if (availableCycles.isEmpty && _gradesCycle.isNotEmpty) {
      availableCycles.add(_gradesCycle);
    }

    final filtered = _allReportsList.where((c) => c['cycle'] == _gradesCycle).toList();

    int totalStudents = 0;
    int totalApproved = 0;
    int totalFailed = 0;
    int totalPending = 0;

    for (final c in filtered) {
      final students = (c['students'] as List?) ?? [];
      for (final st in students) {
        totalStudents++;
        final grade = st['grade'];
        final gradeNum = grade != null ? double.tryParse(grade.toString()) : null;
        if (gradeNum == null) {
          totalPending++;
        } else if (gradeNum >= 14) {
          totalApproved++;
        } else {
          totalFailed++;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cycle Selector Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACTAS DE NOTAS POR CICLO',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Consulta las calificaciones históricas y actuales',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButton<String>(
                      value: availableCycles.contains(_gradesCycle)
                          ? _gradesCycle
                          : (availableCycles.isNotEmpty ? availableCycles.first : null),
                      underline: const SizedBox(),
                      icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.primary),
                      items: availableCycles.map((c) {
                        final isCycleOpen = _allCycles.any((x) => x['cycle'] == c && x['status'] == 'abierto');
                        return DropdownMenuItem<String>(
                          value: c,
                          child: Text(
                            '$c ${isCycleOpen ? "(Activo)" : "(Cerrado)"}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isCycleOpen ? FontWeight.bold : FontWeight.normal,
                              color: isCycleOpen ? const Color(0xFF16A34A) : AppColors.primary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _gradesCycle = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Metric Chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildGradeMetricChip('Cursos: ${filtered.length}', const Color(0xFF032B69)),
                  _buildGradeMetricChip('Total Alumnos: $totalStudents', const Color(0xFF334155)),
                  _buildGradeMetricChip('Aprobados: $totalApproved', const Color(0xFF16A34A)),
                  _buildGradeMetricChip('Desaprobados: $totalFailed', AppColors.error),
                  _buildGradeMetricChip('Sin Calificar: $totalPending', const Color(0xFFEAB308)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (filtered.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(Icons.history_edu, size: 36, color: AppColors.secondary),
                const SizedBox(height: 8),
                Text(
                  'No se encontraron actas registradas para el ciclo $_gradesCycle',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.secondary),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final c = filtered[index];
              final students = (c['students'] as List?) ?? [];

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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${c['code']}: ${c['title']}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${students.length} Alumnos',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Docente: ${c['teacherName']}',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary),
                          ),
                        ),
                        if (c['isActive'] == true)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.lock, size: 12),
                            label: const Text('Cerrar Curso y Actas', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _closeCourseByCoordinator(c),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Acta Cerrada',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                    if (students.isNotEmpty) ...[
                      const Divider(height: 16),
                      ...students.map((st) {
                        final grade = st['grade'];
                        final gradeNum = grade != null ? double.tryParse(grade.toString()) : null;
                        final isApproved = gradeNum != null && gradeNum >= 14;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  st['name'] ?? 'Alumno',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: gradeNum != null
                                      ? (isApproved
                                          ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                                          : AppColors.error.withValues(alpha: 0.12))
                                      : const Color(0xFFEAB308).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  gradeNum != null
                                      ? 'Nota: $gradeNum (${isApproved ? "Aprobado" : "Desaprobado"})'
                                      : 'Pendiente',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: gradeNum != null
                                        ? (isApproved ? const Color(0xFF16A34A) : AppColors.error)
                                        : const Color(0xFFCA8A04),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildGradeMetricChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // TAB 5: Reporte de Asistencias, Consolidado y Redes (Solo Coordinación ABC, Pastor y Admin)
  Widget _buildAttendanceReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with cycle selector
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Reportes y Asistencias ABC',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Consolidado, asistencia por sesión y seguimiento por redes.',
                        style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
                DropdownButton<String>(
                  value: _attendanceCycle,
                  underline: const SizedBox(),
                  items: _allCycles.map((c) {
                    final code = c['cycle']?.toString() ?? '';
                    return DropdownMenuItem<String>(
                      value: code,
                      child: Text(code, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _attendanceCycle = val);
                      _fetchDetailedAttendanceReport(val);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Subview segmented selector: Consolidado & Sesiones vs Reporte por Redes
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _attendanceSubView = 'cursos'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _attendanceSubView == 'cursos' ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _attendanceSubView == 'cursos'
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.table_chart_outlined,
                            size: 16,
                            color: _attendanceSubView == 'cursos' ? AppColors.primary : AppColors.secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Consolidado & Sesiones',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: _attendanceSubView == 'cursos' ? FontWeight.bold : FontWeight.w500,
                              color: _attendanceSubView == 'cursos' ? AppColors.primary : AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _attendanceSubView = 'redes'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _attendanceSubView == 'redes' ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _attendanceSubView == 'redes'
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.hub_outlined,
                            size: 16,
                            color: _attendanceSubView == 'redes' ? AppColors.primary : AppColors.secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Reporte por Redes',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: _attendanceSubView == 'redes' ? FontWeight.bold : FontWeight.w500,
                              color: _attendanceSubView == 'redes' ? AppColors.primary : AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          if (_loadingAttendanceReport)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else if (_attendanceSubView == 'cursos')
            _buildCoursesConsolidatedView()
          else
            _buildNetworksReportView(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // SUBVIEW 1: Consolidado General, Sesiones y Cursos
  Widget _buildCoursesConsolidatedView() {
    if (_attendanceReportData.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No hay cursos registrados en el ciclo $_attendanceCycle.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary),
          ),
        ),
      );
    }

    final totalCourses = _attendanceGeneralSummary['totalCourses'] ?? 0;
    final totalUnique = _attendanceGeneralSummary['totalUniqueStudents'] ?? 0;
    final globalAvg = _attendanceGeneralSummary['globalAttendanceAvg'] ?? 0;
    final criticalStudents = (_attendanceGeneralSummary['criticalStudents'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. TARJETAS DE CONSOLIDADO GENERAL DEL CICLO
        Row(
          children: [
            Expanded(
              child: _buildMetricKpiCard(
                'Cursos',
                '$totalCourses',
                Icons.menu_book,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricKpiCard(
                'Alumnos Únicos',
                '$totalUnique',
                Icons.people,
                const Color(0xFF0284C7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMetricKpiCard(
                'Asist. Global',
                '$globalAvg%',
                Icons.trending_up,
                globalAvg >= 80 ? const Color(0xFF16A34A) : AppColors.error,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: _showCriticalStudentsModal,
                borderRadius: BorderRadius.circular(14),
                child: _buildMetricKpiCard(
                  'En Riesgo',
                  '${criticalStudents.length}',
                  Icons.warning_amber_rounded,
                  criticalStudents.isNotEmpty ? AppColors.error : const Color(0xFF16A34A),
                  subtitle: criticalStudents.isNotEmpty ? 'Ver quiénes' : 'Todo al día',
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Text(
          'CURSOS Y SESIONES DICTADAS',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),

        // 2. LISTA DE CURSOS CON ASISTENCIA POR SESIÓN Y SÁBANA CONSOLIDADA
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _attendanceReportData.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final course = _attendanceReportData[index];
            final isExpanded = _expandedAttendanceCourseId == course['id'];
            final sessionsList = course['sessionsList'] as List;
            final sessionStats = (course['sessionStats'] as List?) ?? [];
            final students = course['students'] as List;
            final avgAtt = course['avgAttendance'] ?? 0;

            return Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _expandedAttendanceCourseId = isExpanded ? null : course['id'];
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${course['code']}',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${course['title']}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Docente: ${course['teacherName']}',
                                      style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.secondary),
                                    ),
                                    const Text(' • ', style: TextStyle(color: Colors.grey)),
                                    Text(
                                      '${students.length} matriculados',
                                      style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.secondary, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (avgAtt >= 80 ? const Color(0xFF16A34A) : AppColors.error).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$avgAtt%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: avgAtt >= 80 ? const Color(0xFF16A34A) : AppColors.error,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 16, color: AppColors.secondary),
                                tooltip: 'Copiar Resumen para WhatsApp',
                                onPressed: () => _copyCourseAttendanceSummary(course),
                              ),
                              Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.primary, size: 20),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (isExpanded) ...[
                    const Divider(height: 1),

                    // A. CANTIDAD TOTAL DE ASISTENCIAS POR SESIÓN (DESGLOSE FECHA A FECHA)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ASISTENCIA POR SESIÓN (${sessionsList.length} dictadas)',
                                style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                              Text(
                                'Toca una tarjeta para ver detalle',
                                style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.secondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          if (sessionStats.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'No se han registrado sesiones aún para este curso.',
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary, fontStyle: FontStyle.italic),
                              ),
                            )
                          else
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: sessionStats.map<Widget>((s) {
                                  final pct = s['pct'] as int? ?? 0;
                                  final isGood = pct >= 80;
                                  return InkWell(
                                    onTap: () => _showSessionDetailsDialog(course, s),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 140,
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isGood ? const Color(0xFFCBD5E1) : AppColors.error.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${s['date']}',
                                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                              ),
                                              Text(
                                                '$pct%',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: isGood ? const Color(0xFF16A34A) : AppColors.error,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.check_circle, size: 12, color: Color(0xFF16A34A)),
                                              const SizedBox(width: 4),
                                              Text('${s['present']} Asistieron', style: const TextStyle(fontSize: 9.5)),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(Icons.cancel, size: 12, color: AppColors.error),
                                              const SizedBox(width: 4),
                                              Text('${s['absent']} Faltaron', style: const TextStyle(fontSize: 9.5)),
                                            ],
                                          ),
                                          if ((s['justified'] as int? ?? 0) > 0) ...[
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                const Icon(Icons.description, size: 12, color: Color(0xFFD97706)),
                                                const SizedBox(width: 4),
                                                Text('${s['justified']} Justif.', style: const TextStyle(fontSize: 9.5)),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // B. SÁBANA CONSOLIDADA DE ASISTENCIAS
                    Padding(
                      padding: const EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'SÁBANA CONSOLIDADA DE ALUMNOS',
                          style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ),

                    if (students.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          'No hay alumnos matriculados en este curso.',
                          style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.secondary, fontStyle: FontStyle.italic),
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(10),
                        child: DataTable(
                          headingRowHeight: 36,
                          dataRowMinHeight: 38,
                          dataRowMaxHeight: 44,
                          columnSpacing: 14,
                          columns: [
                            const DataColumn(label: Text('Estudiante', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                            const DataColumn(label: Text('Asist %', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                            const DataColumn(label: Text('Faltas', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                            const DataColumn(label: Text('Estado', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                            ...sessionsList.map((sDate) => DataColumn(
                                  label: Text('$sDate', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                                )),
                          ],
                          rows: students.map<DataRow>((st) {
                            final int totalSess = sessionsList.length;
                            final attPct = st['attendancePercentage'] ?? 0;
                            final totalAbsences = st['totalAbsences'] ?? 0;
                            final maxAllowed = st['maxAllowed'] ?? 0;
                            final isExceeded = st['isExceeded'] == true;
                            final isDisapproved = st['status'] == 'desaprobado_inasistencias';
                            final sessions = st['sessions'] as Map;

                            return DataRow(
                              cells: [
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(st['name'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      Text('DNI: ${st['dni']}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    totalSess == 0 ? '0%' : '$attPct%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: totalSess == 0 ? Colors.grey : (attPct >= 80 ? const Color(0xFF16A34A) : AppColors.error),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    totalSess == 0 ? '-' : '$totalAbsences / $maxAllowed',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: isExceeded ? FontWeight.bold : FontWeight.normal,
                                      color: isExceeded ? AppColors.error : Colors.black87,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (isDisapproved || isExceeded)
                                          ? AppColors.error.withValues(alpha: 0.12)
                                          : const Color(0xFF16A34A).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isDisapproved
                                          ? 'Desap. Faltas'
                                          : (isExceeded ? 'Excedido' : 'Regular'),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: (isDisapproved || isExceeded) ? AppColors.error : const Color(0xFF16A34A),
                                      ),
                                    ),
                                  ),
                                ),
                                ...sessionsList.map((sDate) {
                                  final status = sessions[sDate];
                                  Color bColor = Colors.grey;
                                  String label = 'S/R';
                                  if (status == 'presente') {
                                    bColor = const Color(0xFF16A34A);
                                    label = 'Asistió';
                                  } else if (status == 'ausente') {
                                    bColor = AppColors.error;
                                    label = 'Ausente';
                                  } else if (status == 'justificado') {
                                    bColor = const Color(0xFFD97706);
                                    label = 'Justif.';
                                  }

                                  return DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: bColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: bColor)),
                                    ),
                                  );
                                }),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // SUBVIEW 2: Reporte de Asistencias por Redes (Matriculados vs No Matriculados)
  Widget _buildNetworksReportView() {
    if (_networkReportData.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No se encontró información de redes para el ciclo $_attendanceCycle.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary),
          ),
        ),
      );
    }

    int totalChurchMembers = 0;
    int totalEnrolledMembers = 0;
    for (final net in _networkReportData) {
      totalChurchMembers += (net['total'] as int? ?? 0);
      totalEnrolledMembers += ((net['enrolled'] as List?)?.length ?? 0);
    }
    final totalNotEnrolled = totalChurchMembers - totalEnrolledMembers;
    final totalCoverage = totalChurchMembers > 0 ? ((totalEnrolledMembers / totalChurchMembers) * 100).round() : 0;

    // Filtered networks list based on chip
    final filteredNets = _selectedNetworkFilter == 'todas'
        ? _networkReportData
        : _networkReportData.where((n) => n['id'] == _selectedNetworkFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pastoral Coverage Summary
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.groups, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Seguimiento Ministerial por Redes',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Identifica a los hermanos matriculados y a quiénes motivar pastoralmente en este ciclo.',
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDarkKpi('Membresía', '$totalChurchMembers', Colors.white),
                  ),
                  Expanded(
                    child: _buildDarkKpi('Matriculados', '$totalEnrolledMembers ($totalCoverage%)', const Color(0xFF4ADE80)),
                  ),
                  Expanded(
                    child: _buildDarkKpi('Por Matricular', '$totalNotEnrolled', const Color(0xFFF87171)),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Networks filter horizontal chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildNetworkFilterChip('todas', 'Todas las Redes'),
              ..._networkReportData.map((n) => _buildNetworkFilterChip(n['id'], n['label'])),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Networks cards list
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredNets.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final net = filteredNets[index];
            final netId = net['id'] as String;
            final isExpanded = _expandedNetworkId == netId;
            final enrolledList = (net['enrolled'] as List?) ?? [];
            final notEnrolledList = (net['notEnrolled'] as List?) ?? [];
            final coveragePct = net['coveragePct'] as int? ?? 0;
            final avgAtt = net['avgAttendance'] as int? ?? 0;
            final total = net['total'] as int? ?? 0;

            return Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _expandedNetworkId = isExpanded ? null : netId;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(_getNetworkIcon(net['icon']), color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      net['label'],
                                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                    Text(
                                      '$total miembros registrados en la iglesia',
                                      style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.secondary),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (avgAtt >= 80 ? const Color(0xFF16A34A) : const Color(0xFFD97706)).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$avgAtt% Asist.',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: avgAtt >= 80 ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.primary, size: 20),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Progress Bar
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: total > 0 ? (enrolledList.length / total) : 0,
                                    minHeight: 6,
                                    backgroundColor: const Color(0xFFE2E8F0),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${enrolledList.length}/$total ($coveragePct%)',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (isExpanded) ...[
                    const Divider(height: 1),

                    // Toggle: Matriculados vs No Matriculados
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => setState(() => _networkMemberView = 'matriculados'),
                              icon: const Icon(Icons.check_circle_outline, size: 14),
                              label: Text('Matriculados (${enrolledList.length})', style: const TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: _networkMemberView == 'matriculados' ? const Color(0xFF16A34A).withValues(alpha: 0.1) : Colors.transparent,
                                side: BorderSide(
                                  color: _networkMemberView == 'matriculados' ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                                ),
                                foregroundColor: _networkMemberView == 'matriculados' ? const Color(0xFF16A34A) : AppColors.secondary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => setState(() => _networkMemberView = 'no_matriculados'),
                              icon: const Icon(Icons.person_add_outlined, size: 14),
                              label: Text('No Matriculados (${notEnrolledList.length})', style: const TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: _networkMemberView == 'no_matriculados' ? AppColors.error.withValues(alpha: 0.1) : Colors.transparent,
                                side: BorderSide(
                                  color: _networkMemberView == 'no_matriculados' ? AppColors.error : const Color(0xFFCBD5E1),
                                ),
                                foregroundColor: _networkMemberView == 'no_matriculados' ? AppColors.error : AppColors.secondary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_networkMemberView == 'matriculados') ...[
                      if (enrolledList.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No hay miembros de esta red matriculados en el ciclo $_attendanceCycle.',
                            style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.secondary, fontStyle: FontStyle.italic),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          itemCount: enrolledList.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final m = enrolledList[index];
                            final phone = m['phone']?.toString() ?? '';
                            final courses = (m['courses'] as List?)?.join(', ') ?? 'Curso activo';
                            final att = m['avgAttendance'] ?? 0;

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.12),
                                    child: Text(
                                      m['name'].toString().isNotEmpty ? m['name'].toString().substring(0, 1).toUpperCase() : 'A',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m['name'],
                                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                        Text(
                                          courses,
                                          style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.secondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (att >= 80 ? const Color(0xFF16A34A) : AppColors.error).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$att%',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: att >= 80 ? const Color(0xFF16A34A) : AppColors.error,
                                      ),
                                    ),
                                  ),
                                  if (phone.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(Icons.chat, size: 16, color: Color(0xFF16A34A)),
                                      tooltip: 'Escribir por WhatsApp',
                                      onPressed: () => _openWhatsAppMessage(phone, m['name'], _attendanceCycle),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                    ] else ...[
                      // NO MATRICULADOS
                      if (notEnrolledList.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '¡Excelente! Todos los miembros de esta red están matriculados.',
                            style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF16A34A), fontWeight: FontWeight.bold),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          itemCount: notEnrolledList.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final m = notEnrolledList[index];
                            final phone = m['phone']?.toString() ?? '';
                            final dni = m['dni']?.toString() ?? '';

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.error.withValues(alpha: 0.1),
                                    child: Text(
                                      m['name'].toString().isNotEmpty ? m['name'].toString().substring(0, 1).toUpperCase() : 'H',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m['name'],
                                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                        if (dni.isNotEmpty)
                                          Text(
                                            'DNI: $dni ${phone.isNotEmpty ? '• Cel: $phone' : ''}',
                                            style: GoogleFonts.inter(fontSize: 10, color: AppColors.secondary),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (phone.isNotEmpty)
                                    ElevatedButton.icon(
                                      onPressed: () => _openWhatsAppMessage(phone, m['name'], _attendanceCycle),
                                      icon: const Icon(Icons.chat, size: 13),
                                      label: const Text('Motivar', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        backgroundColor: const Color(0xFF16A34A),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    )
                                  else
                                    const Text('Sin teléfono', style: TextStyle(fontSize: 9.5, color: Colors.grey)),
                                ],
                              ),
                            );
                          },
                        ),
                    ],

                    const SizedBox(height: 10),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNetworkFilterChip(String id, String label) {
    final isSelected = _selectedNetworkFilter == id;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          if (val) setState(() => _selectedNetworkFilter = id);
        },
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildMetricKpiCard(String label, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                ),
                Text(
                  subtitle ?? label,
                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDarkKpi(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFF94A3B8))),
      ],
    );
  }

  IconData _getNetworkIcon(dynamic iconName) {
    switch (iconName?.toString()) {
      case 'favorite': return Icons.favorite_outline;
      case 'shield': return Icons.shield_outlined;
      case 'bolt': return Icons.bolt;
      case 'wb_sunny': return Icons.wb_sunny_outlined;
      case 'people': return Icons.people_outline;
      case 'elderly': return Icons.elderly;
      case 'star': return Icons.star_border;
      case 'explore': return Icons.explore_outlined;
      case 'child_care': return Icons.child_care;
      default: return Icons.person_outline;
    }
  }

  Future<void> _openWhatsAppMessage(String phone, String name, String cycle) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) return;
    final intlPhone = cleanPhone.startsWith('+') ? cleanPhone : '+51$cleanPhone';
    final text = 'Hola $name, te saludamos con mucho cariño de la Iglesia Alianza Chaclacayo. Te animamos a participar de la Academia ABC en este Ciclo $cycle. ¡Hay cursos presenciales y virtuales con cupos disponibles para ti!';
    final encoded = Uri.encodeComponent(text);
    final url = Uri.parse('https://api.whatsapp.com/send?phone=$intlPhone&text=$encoded');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('No se pudo abrir WhatsApp: $e')),
        );
      }
    }
  }

  void _copyCourseAttendanceSummary(Map<String, dynamic> course) {
    final buffer = StringBuffer();
    buffer.writeln('📋 *CONSOLIDADO DE ASISTENCIAS: ${course['title']} (${course['code']})*');
    buffer.writeln('👨‍🏫 Docente: ${course['teacherName']}');
    buffer.writeln('👥 Alumnos Matriculados: ${(course['students'] as List).length}');
    buffer.writeln('📈 Asistencia Promedio: ${course['avgAttendance']}%');
    buffer.writeln('📅 Sesiones Realizadas: ${(course['sessionsList'] as List).length}');
    buffer.writeln('');
    buffer.writeln('*ASISTENCIA POR SESIÓN:*');
    for (final s in (course['sessionStats'] as List)) {
      buffer.writeln('• ${s['date']}: ${s['present']} Asistieron (${s['pct']}%) | ${s['absent']} Faltaron | ${s['justified']} Justif.');
    }
    buffer.writeln('');
    buffer.writeln('*ESTADO DE ALUMNOS:*');
    for (final st in (course['students'] as List)) {
      final state = st['isExceeded'] == true ? '⚠️ FALTAS EXCEDIDAS' : '✅ Regular';
      buffer.writeln('• ${st['name']}: ${st['attendancePercentage']}% (${st['totalAbsences']}/${st['maxAllowed']} faltas) - $state');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF16A34A),
        content: Text('¡Resumen de asistencia copiado al portapapeles!'),
      ),
    );
  }

  void _showSessionDetailsDialog(Map<String, dynamic> course, Map<String, dynamic> session) {
    final present = (session['presentStudents'] as List?) ?? [];
    final absent = (session['absentStudents'] as List?) ?? [];
    final justified = (session['justifiedStudents'] as List?) ?? [];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sesión: ${session['date']}', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text('${course['title']}', style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.secondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Session summary KPI banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSessionMetricColumn('Presentes', '${session['present']}', const Color(0xFF16A34A)),
                      _buildSessionMetricColumn('Ausentes', '${session['absent']}', AppColors.error),
                      _buildSessionMetricColumn('Justificados', '${session['justified']}', const Color(0xFFD97706)),
                      _buildSessionMetricColumn('Efectividad', '${session['pct']}%', AppColors.primary),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (absent.isNotEmpty) ...[
                  Text('Ausentes (${absent.length})', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error)),
                  const SizedBox(height: 6),
                  ...absent.map((st) => _buildSessionStudentTile(st, Icons.close, AppColors.error)),
                  const SizedBox(height: 12),
                ],

                if (justified.isNotEmpty) ...[
                  Text('Justificados (${justified.length})', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFD97706))),
                  const SizedBox(height: 6),
                  ...justified.map((st) => _buildSessionStudentTile(st, Icons.description_outlined, const Color(0xFFD97706))),
                  const SizedBox(height: 12),
                ],

                Text('Presentes (${present.length})', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A))),
                const SizedBox(height: 6),
                if (present.isEmpty)
                  Text('Ninguno registrado', style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary, fontStyle: FontStyle.italic))
                else
                  ...present.map((st) => _buildSessionStudentTile(st, Icons.check, const Color(0xFF16A34A))),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionMetricColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.secondary)),
      ],
    );
  }

  Widget _buildSessionStudentTile(dynamic st, IconData icon, Color color) {
    final name = st['name']?.toString() ?? 'Alumno';
    final dni = st['dni']?.toString() ?? '';
    final phone = st['phone']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (dni.isNotEmpty)
            Text('DNI: $dni', style: GoogleFonts.inter(fontSize: 9.5, color: Colors.grey)),
          if (phone.isNotEmpty) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
                final intlPhone = cleanPhone.startsWith('+') ? cleanPhone : '+51$cleanPhone';
                launchUrl(Uri.parse('https://api.whatsapp.com/send?phone=$intlPhone'), mode: LaunchMode.externalApplication);
              },
              child: const Icon(Icons.chat, size: 15, color: Color(0xFF16A34A)),
            ),
          ],
        ],
      ),
    );
  }

  void _showCriticalStudentsModal() {
    final critical = (_attendanceGeneralSummary['criticalStudents'] as List?) ?? [];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Alumnos en Riesgo Crítico (${critical.length})',
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: critical.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('¡Excelente! No hay alumnos en riesgo de inasistencias en este ciclo.')),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: critical.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final st = critical[index];
                    final phone = st['phone']?.toString() ?? '';
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  st['studentName'],
                                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${st['attendancePct']}% Asist.',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Curso: ${st['courseTitle']}',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Faltas: ${st['totalAbsences']} de máx ${st['maxAllowed']} permitidas',
                            style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.error),
                          ),
                          if (phone.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
                                  final intlPhone = cleanPhone.startsWith('+') ? cleanPhone : '+51$cleanPhone';
                                  final msg = Uri.encodeComponent('Hola ${st['studentName']}, te saludamos de la Academia ABC. Queremos coordinar contigo respecto a tu asistencia al curso ${st['courseTitle']}.');
                                  launchUrl(Uri.parse('https://api.whatsapp.com/send?phone=$intlPhone&text=$msg'), mode: LaunchMode.externalApplication);
                                },
                                icon: const Icon(Icons.chat, size: 14, color: Color(0xFF16A34A)),
                                label: const Text('Contactar por WhatsApp', style: TextStyle(fontSize: 11, color: Color(0xFF16A34A))),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  side: const BorderSide(color: Color(0xFF16A34A)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido')),
        ],
      ),
    );
  }

  void _showStudentAttendanceHistoryDialog(String courseId, String courseTitle) async {
    final client = Supabase.instance.client;
    final user = ref.read(authStateProvider).userProfile;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.history_edu, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Mi Asistencia: $courseTitle',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<dynamic>>(
            future: Future.wait([
              client.from('courses').select('max_absences, is_active').eq('id', courseId).maybeSingle(),
              client.from('academy_attendance').select('student_id, session_date, status, marked_at').eq('course_id', courseId).order('session_date', ascending: false),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error al cargar historial: ${snapshot.error}', style: const TextStyle(color: AppColors.error)),
                );
              }

              final courseData = snapshot.data?[0] as Map<String, dynamic>? ?? {};
              final allCourseAtt = (snapshot.data?[1] as List?) ?? [];

              final distinctSessions = allCourseAtt.map((a) => a['session_date'].toString()).toSet().toList()..sort((a, b) => b.compareTo(a));
              final totalSessions = distinctSessions.length;
              final customMax = courseData['max_absences'];
              final maxAllowed = getMaxAllowedAbsences(totalSessions, customMax);

              final myMap = <String, Map<String, dynamic>>{};
              for (final a in allCourseAtt) {
                if (a['student_id']?.toString() == user.id) {
                  myMap[a['session_date'].toString()] = Map<String, dynamic>.from(a);
                }
              }

              int attended = 0;
              int absent = 0;
              int justified = 0;

              for (final sDate in distinctSessions) {
                final myRow = myMap[sDate];
                final st = myRow?['status']?.toString();
                if (st == 'presente') {
                  attended++;
                } else if (st == 'justificado') {
                  justified++;
                  attended++;
                } else {
                  absent++;
                }
              }

              final pct = totalSessions > 0 ? ((attended / totalSessions) * 100).round() : 0;
              final isExceeded = totalSessions > 0 && absent > maxAllowed;

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isExceeded ? AppColors.error.withValues(alpha: 0.08) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isExceeded ? AppColors.error.withValues(alpha: 0.3) : const Color(0xFFBBF7D0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text('Clases Dictadas', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  Text('$totalSessions', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text('Asistencias', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  Text(
                                    '$attended${justified > 0 ? " ($justified just.)" : ""}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text('Inasistencias', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  Text('$absent', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isExceeded ? AppColors.error : Colors.grey[800])),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text('Porcentaje', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  Text(
                                    totalSessions == 0 ? '0%' : '$pct%',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: pct >= 80 ? const Color(0xFF16A34A) : AppColors.error),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(isExceeded ? Icons.warning_amber_rounded : Icons.info_outline, size: 14, color: isExceeded ? AppColors.error : AppColors.secondary),
                              const SizedBox(width: 4),
                              Text(
                                'Máximo inasistencias permitidas: $maxAllowed',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isExceeded ? AppColors.error : AppColors.secondary),
                              ),
                            ],
                          ),
                          if (isExceeded)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '⚠️ Has superado el límite de faltas permitidas.',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.error),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Sesiones Dictadas:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    if (distinctSessions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: Text('Aún no se han dictado sesiones en este curso.', style: TextStyle(fontSize: 11, color: Colors.grey))),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: distinctSessions.length,
                        separatorBuilder: (_, _) => const Divider(height: 8),
                        itemBuilder: (context, idx) {
                          final sDate = distinctSessions[idx];
                          final myRow = myMap[sDate];
                          final status = myRow?['status']?.toString() ?? 'ausente';
                          final markedAt = myRow?['marked_at']?.toString();

                          Color color = AppColors.error;
                          String label = 'Ausente';
                          IconData icon = Icons.cancel;
                          if (status == 'presente') {
                            color = const Color(0xFF16A34A);
                            label = 'Presente';
                            icon = Icons.check_circle;
                          } else if (status == 'justificado') {
                            color = const Color(0xFFD97706);
                            label = 'Justificado';
                            icon = Icons.access_time;
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(icon, size: 18, color: color),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Sesión: $sDate', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      if (markedAt != null)
                                        Text('Marcado: ${DateFormat('hh:mm a').format(DateTime.tryParse(markedAt) ?? DateTime.now())}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showCourseAttendanceReportDialog(Map<String, dynamic> course) async {
    final client = Supabase.instance.client;
    final courseId = course['id'].toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.assessment, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Reporte: ${course['code']}: ${course['title']}',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<dynamic>>(
            future: Future.wait([
              client.from('enrollments').select('student_id, final_grade, attendance_percentage, status, is_approved, disapproval_reason, profiles:student_id(id, first_name, last_name, dni)').eq('course_id', courseId),
              client.from('academy_attendance').select('student_id, session_date, status').eq('course_id', courseId).order('session_date', ascending: true),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final enrollments = (snapshot.data?[0] as List?) ?? [];
              final attendances = (snapshot.data?[1] as List?) ?? [];

              final uniqueDates = attendances.map((a) => a['session_date'].toString()).toSet().toList()..sort();
              final totalSessions = uniqueDates.length;
              final maxAllowed = getMaxAllowedAbsences(totalSessions, course['max_absences']);

              if (enrollments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('No hay alumnos matriculados en este curso.')),
                );
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Clases Dictadas: $totalSessions', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('Máx Inasistencias: $maxAllowed', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowHeight: 36,
                        dataRowMinHeight: 38,
                        dataRowMaxHeight: 46,
                        columnSpacing: 14,
                        columns: [
                          const DataColumn(label: Text('Alumno', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('Asist %', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('Faltas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('Estado', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                          ...uniqueDates.map((d) => DataColumn(label: Text(d, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)))),
                        ],
                        rows: enrollments.map<DataRow>((e) {
                          final p = e['profiles'];
                          final stId = e['student_id']?.toString() ?? '';
                          final name = p != null ? '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim() : 'Alumno';
                          final dni = p?['dni'] ?? '';

                          final stAtts = attendances.where((a) => a['student_id']?.toString() == stId).toList();
                          final attended = stAtts.where((a) => a['status'] == 'presente' || a['status'] == 'justificado').length;
                          final absent = stAtts.where((a) => a['status'] == 'ausente').length;
                          final unrecorded = totalSessions - (attended + absent);
                          final totalAbsences = absent + (unrecorded > 0 ? unrecorded : 0);

                          final pct = totalSessions > 0 ? ((attended / totalSessions) * 100).round() : 0;
                          final isExceeded = totalSessions > 0 && totalAbsences > maxAllowed;
                          final isDisapproved = e['status'] == 'desaprobado_inasistencias';

                          return DataRow(
                            cells: [
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    if (dni.isNotEmpty) Text('DNI: $dni', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  totalSessions == 0 ? '0%' : '$pct%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: totalSessions == 0 ? Colors.grey : (pct >= 80 ? const Color(0xFF16A34A) : AppColors.error),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  totalSessions == 0 ? '-' : '$totalAbsences / $maxAllowed',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isExceeded ? FontWeight.bold : FontWeight.normal,
                                    color: isExceeded ? AppColors.error : Colors.black87,
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isDisapproved || isExceeded)
                                        ? AppColors.error.withValues(alpha: 0.12)
                                        : const Color(0xFF16A34A).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isDisapproved
                                        ? 'Desap. Faltas'
                                        : (isExceeded ? 'Excedido' : 'Regular'),
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: (isDisapproved || isExceeded) ? AppColors.error : const Color(0xFF16A34A),
                                    ),
                                  ),
                                ),
                              ),
                              ...uniqueDates.map((d) {
                                final match = stAtts.firstWhere((a) => a['session_date']?.toString() == d, orElse: () => {});
                                final st = match['status']?.toString();
                                Color bColor = Colors.grey;
                                String label = '-';
                                if (st == 'presente') {
                                  bColor = const Color(0xFF16A34A);
                                  label = 'P';
                                } else if (st == 'ausente') {
                                  bColor = AppColors.error;
                                  label = 'F';
                                } else if (st == 'justificado') {
                                  bColor = const Color(0xFFD97706);
                                  label = 'J';
                                }
                                return DataCell(
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: bColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: bColor)),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
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

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.secondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
