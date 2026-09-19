import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_provider.dart';
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
  CurriculumSubject(code: 'A01', title: 'Mi nueva Alianza con Dios', level: 'inicial', prerequisites: [], duration: '4 meses'),
  CurriculumSubject(code: 'A02', title: 'Comprometidos con Cristo y su iglesia', level: 'inicial', prerequisites: ['A01'], duration: '2 meses'),
  CurriculumSubject(code: 'A03', title: 'Comunión profunda', level: 'inicial', prerequisites: ['A02'], duration: '2 meses'),
  CurriculumSubject(code: 'B01', title: 'Evangelismo personal', level: 'basico', prerequisites: ['A03'], duration: '2 meses'),
  CurriculumSubject(code: 'B02', title: 'Discipulado de GP 1', level: 'basico', prerequisites: ['B01'], duration: '2 meses'),
  CurriculumSubject(code: 'B03', title: 'Discipulado de GP 2', level: 'basico', prerequisites: ['B02'], duration: '2 meses'),
  CurriculumSubject(code: 'B04', title: 'Descubriendo mis dones espirituales', level: 'basico', prerequisites: ['B03'], duration: '2 meses'),
  CurriculumSubject(code: 'B05', title: 'Panorama bíblico', level: 'basico', prerequisites: ['B04'], duration: '2 meses'),
  CurriculumSubject(code: 'C01', title: '¿Cómo estudiar la biblia?', level: 'intermedio', prerequisites: ['B05'], duration: '2 meses'),
  CurriculumSubject(code: 'C02', title: 'Sectas', level: 'intermedio', prerequisites: ['C01'], duration: '2 meses'),
  CurriculumSubject(code: 'C03', title: 'Espíritu Santo', level: 'intermedio', prerequisites: ['C02'], duration: '2 meses'),
  CurriculumSubject(code: 'C04', title: 'Efesios - 1 Parte', level: 'intermedio', prerequisites: ['C03'], duration: '2 meses'),
  CurriculumSubject(code: 'C05', title: 'Efesios – 2 Parte', level: 'intermedio', prerequisites: ['C04'], duration: '2 meses'),
  CurriculumSubject(code: 'C06', title: 'Mayordomía Cristiana', level: 'intermedio', prerequisites: ['C05'], duration: '2 meses'),
  CurriculumSubject(code: 'C07', title: 'Bases bíblica de la misión', level: 'intermedio', prerequisites: ['C06'], duration: '2 meses'),
  CurriculumSubject(code: 'C08', title: '1 Corintios – 1 Parte', level: 'intermedio', prerequisites: ['C07'], duration: '2 meses'),
  CurriculumSubject(code: 'C09', title: '1 Corintios – 2 Parte', level: 'intermedio', prerequisites: ['C08'], duration: '2 meses'),
  CurriculumSubject(code: 'C10', title: 'Romanos', level: 'intermedio', prerequisites: ['C09'], duration: '2 meses'),
  CurriculumSubject(code: 'D01', title: 'ETE 1', level: 'avanzado', prerequisites: ['C10'], duration: '3 meses'),
  CurriculumSubject(code: 'D02', title: 'ETE 2', level: 'avanzado', prerequisites: ['D01'], duration: '3 meses'),
  CurriculumSubject(code: 'D03', title: 'ETE 3', level: 'avanzado', prerequisites: ['D02'], duration: '3 meses'),
  CurriculumSubject(code: 'D04', title: 'ETE 4', level: 'avanzado', prerequisites: ['D03'], duration: '3 meses'),
  CurriculumSubject(code: 'D05', title: 'ETE 5', level: 'avanzado', prerequisites: ['D04'], duration: '3 meses'),
  CurriculumSubject(code: 'D06', title: 'ETE 6', level: 'avanzado', prerequisites: ['D05'], duration: '3 meses'),
  CurriculumSubject(code: 'D07', title: 'Viajes de Pablo 1', level: 'avanzado', prerequisites: ['D06'], duration: '3 meses'),
  CurriculumSubject(code: 'D08', title: 'Viajes de Pablo 2', level: 'avanzado', prerequisites: ['D07'], duration: '3 meses'),
  CurriculumSubject(code: 'D09', title: 'Viajes de Pablo 3', level: 'avanzado', prerequisites: ['D08'], duration: '3 meses'),
  CurriculumSubject(code: 'D10', title: 'Hebreos', level: 'avanzado', prerequisites: ['D09'], duration: '3 meses'),
  CurriculumSubject(code: 'D12', title: 'Pentateuco I', level: 'avanzado', prerequisites: ['D10'], duration: '3 meses'),
  CurriculumSubject(code: 'D13', title: 'Pentateuco II', level: 'avanzado', prerequisites: ['D12'], duration: '3 meses'),
];

class AcademiaScreen extends ConsumerStatefulWidget {
  const AcademiaScreen({super.key});

  @override
  ConsumerState<AcademiaScreen> createState() => _AcademiaScreenState();
}

class _AcademiaScreenState extends ConsumerState<AcademiaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _activeCycle = '2026-III';
  List<Map<String, dynamic>> _offeredCourses = [];
  List<Map<String, dynamic>> _userEnrollments = [];
  List<Map<String, dynamic>> _approvedSubjects = [];
  List<Map<String, dynamic>> _studentAttendanceList = [];
  bool _loading = true;
  String? _selectedLevel;

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
  bool _savingMaterial = false;

  // Coordinator States
  List<Map<String, dynamic>> _allCycles = [];
  List<Map<String, dynamic>> _teachersList = [];
  List<Map<String, dynamic>> _allReportsList = [];
  String _coordSubTab = 'dashboard'; // 'dashboard', 'cycles', 'courses', 'grades'
  String _statsCycle = '2026-III';

  // Attendance Report Tab State
  String _attendanceCycle = '2026-III';
  List<Map<String, dynamic>> _attendanceReportData = [];
  bool _loadingAttendanceReport = false;
  String? _expandedAttendanceCourseId;

  final Map<String, String> _levelNames = const {
    'inicial': 'Nivel Inicial',
    'basico': 'Nivel Básico',
    'intermedio': 'Nivel Intermedio',
    'avanzado': 'Nivel Avanzado',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _gradeControllers.values) {
      c.dispose();
    }
    _materialTitleController.dispose();
    _materialUrlController.dispose();
    super.dispose();
  }

  bool _isUserEnrolledInActiveCycle() {
    return _userEnrollments.any((e) {
      final course = e['courses'];
      if (course == null) return false;
      return course['cycle'] == _activeCycle;
    });
  }

  Map<String, dynamic>? _getActiveEnrollment() {
    try {
      return _userEnrollments.firstWhere((e) {
        final course = e['courses'];
        if (course == null) return false;
        return course['cycle'] == _activeCycle;
      });
    } catch (_) {
      return null;
    }
  }

  int _calculateTabCount(dynamic user) {
    int count = 2; // (Mi Curso Actual OR Matrícula) + Mi Historial
    if (user != null) {
      if (user.isTeacher || user.isPastor) count++; // Panel Docente
      if (user.isAcademyCoordinator || user.isPastor) count++; // Coordinación
      if (user.isAcademyCoordinator || user.isPastor || user.rolesList.contains('apoyo_abc')) count++; // Reporte Asistencias
    }
    return count;
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
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
          orElse: () => _allCycles.first,
        );
        _activeCycle = openCycle['cycle'] ?? '2026-III';
        _statsCycle = _activeCycle;
        _attendanceCycle = _activeCycle;
      }

      // 2. Fetch opened courses for this cycle
      final coursesRes = await client
          .from('courses')
          .select('*, profiles:teacher_id(first_name, last_name)')
          .eq('cycle', _activeCycle);

      _offeredCourses = List<Map<String, dynamic>>.from(coursesRes);

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
            .select('course_id, session_date, status')
            .eq('student_id', user.id)
            .order('session_date', ascending: false);
        _studentAttendanceList = List<Map<String, dynamic>>.from(attRes);

        // Teacher courses
        if (user.isTeacher || user.isPastor) {
          final tCoursesRes = await client
              .from('courses')
              .select('id, code, title, level, schedule, cycle, materials')
              .eq('teacher_id', user.id)
              .eq('is_active', true)
              .eq('cycle', _activeCycle);
          _teacherCourses = List<Map<String, dynamic>>.from(tCoursesRes);
          if (_teacherCourses.isNotEmpty) {
            _selectedTeacherCourseId ??= _teacherCourses.first['id'];
            await _loadStudentsForTeacherCourse(_selectedTeacherCourseId!);
          }
        }

        // Coordinator & Support data
        if (user.isAcademyCoordinator || user.isPastor || user.rolesList.contains('apoyo_abc')) {
          final tListRes = await client
              .from('profiles')
              .select('id, first_name, last_name, role')
              .order('first_name');
          _teachersList = List<Map<String, dynamic>>.from(tListRes);

          await _fetchCoordinatorReports();
          await _fetchDetailedAttendanceReport(_attendanceCycle);
        }
      }

      // Default level selection
      final availableLevels = _getAvailableLevels();
      if (availableLevels.isNotEmpty) {
        _selectedLevel = availableLevels.first;
      } else {
        _selectedLevel = 'inicial';
      }

      final tabCount = _calculateTabCount(user);
      _tabController = TabController(length: tabCount, vsync: this);

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchCoordinatorReports() async {
    final client = Supabase.instance.client;
    try {
      final dbCourses = await client
          .from('courses')
          .select('id, code, title, level, cycle, is_active, profiles:teacher_id(first_name, last_name)')
          .order('cycle', ascending: false);

      final enrollments = await client
          .from('enrollments')
          .select('course_id, final_grade, attendance_percentage, profiles:student_id(id, first_name, last_name, dni, phone)');

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
                'studentId': p?['id'],
                'name': p != null ? '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim() : 'Estudiante',
                'dni': p?['dni'] ?? 'No registrado',
                'phone': p?['phone'] ?? '',
                'grade': e['final_grade'],
                'attendance': e['attendance_percentage'],
              };
            })
            .toList();

        mapped.add({
          'id': c['id'],
          'code': c['code'],
          'title': c['title'],
          'level': c['level'],
          'cycle': c['cycle'],
          'isActive': c['is_active'] ?? true,
          'teacherName': teacherName,
          'students': matchingStudents,
        });
      }

      _allReportsList = mapped;
    } catch (_) {}
  }

  Future<void> _fetchDetailedAttendanceReport(String targetCycle) async {
    setState(() => _loadingAttendanceReport = true);
    final client = Supabase.instance.client;
    try {
      final coursesRes = await client
          .from('courses')
          .select('id, code, title, level, profiles:teacher_id(first_name, last_name)')
          .eq('cycle', targetCycle);

      final courseIds = (coursesRes as List).map((c) => c['id'].toString()).toList();

      if (courseIds.isEmpty) {
        setState(() {
          _attendanceReportData = [];
          _loadingAttendanceReport = false;
        });
        return;
      }

      final enrollRes = await client
          .from('enrollments')
          .select('course_id, attendance_percentage, profiles:student_id(id, first_name, last_name, dni)')
          .inFilter('course_id', courseIds);

      final attRes = await client
          .from('academy_attendance')
          .select('course_id, student_id, session_date, status')
          .inFilter('course_id', courseIds)
          .order('session_date', ascending: true);

      final list = <Map<String, dynamic>>[];
      for (final c in coursesRes) {
        final cId = c['id'].toString();
        final teacher = c['profiles'];
        final teacherName = teacher != null
            ? '${teacher['first_name'] ?? ''} ${teacher['last_name'] ?? ''}'.trim()
            : 'Sin docente asignado';

        final courseAtt = (attRes as List).where((a) => a['course_id'].toString() == cId).toList();
        final uniqueDates = courseAtt.map((a) => a['session_date'].toString()).toSet().toList()..sort();

        final courseEnrolled = (enrollRes as List).where((e) => e['course_id'].toString() == cId).toList();

        final studentsList = courseEnrolled.map((e) {
          final p = e['profiles'];
          final stId = p?['id']?.toString() ?? '';
          final stName = p != null ? '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim() : 'Estudiante';
          final stDni = p?['dni']?.toString() ?? 'No registrado';

          final sessionsMap = <String, String>{};
          for (final a in courseAtt) {
            if (a['student_id'].toString() == stId) {
              sessionsMap[a['session_date'].toString()] = a['status'].toString();
            }
          }

          return {
            'id': stId,
            'name': stName,
            'dni': stDni,
            'attendancePercentage': e['attendance_percentage'] ?? 100,
            'sessions': sessionsMap,
          };
        }).toList();

        list.add({
          'id': cId,
          'code': c['code'],
          'title': c['title'],
          'level': c['level'],
          'teacherName': teacherName,
          'sessionsList': uniqueDates,
          'students': studentsList,
        });
      }

      setState(() {
        _attendanceReportData = list;
        _loadingAttendanceReport = false;
      });
    } catch (_) {
      setState(() => _loadingAttendanceReport = false);
    }
  }

  Future<void> _loadStudentsForTeacherCourse(String courseId) async {
    setState(() => _loadingStudents = true);
    final client = Supabase.instance.client;
    try {
      final res = await client
          .from('enrollments')
          .select('id, student_id, final_grade, attendance_percentage, profiles:student_id(id, first_name, last_name, dni, phone)')
          .eq('course_id', courseId);

      _courseStudents = List<Map<String, dynamic>>.from(res);
      for (final st in _courseStudents) {
        final stId = st['student_id']?.toString() ?? '';
        final grade = st['final_grade'];
        _gradeControllers[stId] ??= TextEditingController(
          text: grade != null ? grade.toString() : '',
        );
      }
      if (mounted) setState(() => _loadingStudents = false);
    } catch (e) {
      if (mounted) setState(() => _loadingStudents = false);
    }
  }

  Future<void> _saveAllGrades() async {
    if (_selectedTeacherCourseId == null || _courseStudents.isEmpty) return;
    setState(() => _savingGrades = true);
    final client = Supabase.instance.client;

    try {
      for (final st in _courseStudents) {
        final stId = st['student_id']?.toString() ?? '';
        final controller = _gradeControllers[stId];
        final textVal = controller?.text.trim() ?? '';
        final gradeNum = double.tryParse(textVal);

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

          if (isApproved) {
            final course = _teacherCourses.firstWhere((c) => c['id'] == _selectedTeacherCourseId);
            await client.from('academy_approved_subjects').upsert({
              'student_id': stId,
              'subject_code': course['code'],
              'subject_title': course['title'],
              'level': course['level'] ?? 'inicial',
              'grade': gradeNum,
              'cycle': _activeCycle,
              'approved_at': DateTime.now().toIso8601String(),
            }, onConflict: 'student_id,subject_code');
          }
        }
      }

      if (mounted) {
        setState(() => _savingGrades = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF16A34A),
            content: Text('¡Acta de notas guardada y sincronizada correctamente!'),
          ),
        );
        _loadStudentsForTeacherCourse(_selectedTeacherCourseId!);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _savingGrades = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error al guardar notas: $e')),
        );
      }
    }
  }

  Future<void> _addCourseMaterial() async {
    final title = _materialTitleController.text.trim();
    final url = _materialUrlController.text.trim();
    if (title.isEmpty || url.isEmpty || _selectedTeacherCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa el título y enlace del material')),
      );
      return;
    }

    setState(() => _savingMaterial = true);
    final client = Supabase.instance.client;

    try {
      final course = _teacherCourses.firstWhere((c) => c['id'] == _selectedTeacherCourseId);
      final List existingMaterials = course['materials'] != null && course['materials'] is List
          ? List.from(course['materials'])
          : [];

      existingMaterials.add({
        'name': title,
        'url': url,
        'created_at': DateTime.now().toIso8601String(),
      });

      await client
          .from('courses')
          .update({'materials': existingMaterials})
          .eq('id', _selectedTeacherCourseId!);

      course['materials'] = existingMaterials;
      _materialTitleController.clear();
      _materialUrlController.clear();

      if (mounted) {
        setState(() => _savingMaterial = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF16A34A),
            content: Text('¡Material de estudio agregado con éxito!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _savingMaterial = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error al agregar material: $e')),
        );
      }
    }
  }

  List<String> _getAvailableLevels() {
    final levels = <String>{};
    for (final c in _offeredCourses) {
      final lvl = c['level']?.toString();
      if (lvl != null && lvl.isNotEmpty) {
        levels.add(lvl);
      }
    }
    final order = ['inicial', 'basico', 'intermedio', 'avanzado'];
    return order.where((l) => levels.contains(l)).toList();
  }

  List<Map<String, dynamic>> _getEnrollableCourses() {
    final approvedCodes = _approvedSubjects.map((s) => s['subject_code']?.toString() ?? '').toSet();
    final hasApprovedAnyBasic = approvedCodes.contains('A01') || approvedCodes.contains('A02') || approvedCodes.contains('A03');

    return _offeredCourses.where((c) {
      if (_selectedLevel != null && c['level'] != _selectedLevel) {
        return false;
      }
      final code = c['code']?.toString() ?? '';
      if (approvedCodes.contains(code)) return false;

      final curriculumItem = abcCurriculum.firstWhere(
        (sub) => sub.code == code,
        orElse: () => CurriculumSubject(code: code, title: '', level: 'inicial', prerequisites: [], duration: ''),
      );

      if (curriculumItem.prerequisites.isEmpty) return true;
      if (curriculumItem.prerequisites.every((p) => approvedCodes.contains(p))) return true;
      if (hasApprovedAnyBasic && (c['level'] == 'basico' || c['level'] == 'intermedio')) return true;

      return false;
    }).toList();
  }

  Future<void> _enrollInCourse(Map<String, dynamic> course) async {
    final user = ref.read(authStateProvider).userProfile;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para matricularte.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmar Matrícula', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text('¿Deseas matricularte en "${course['code']} - ${course['title']}" para el ciclo $_activeCycle?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Sí, Matricularme'),
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
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16A34A),
            content: Text('¡Matrícula exitosa en ${course['title']}!'),
          ),
        );
        _loadData();
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
                      // Tab 1: If enrolled, show "Mi Curso Actual", else "Matrícula"
                      Tab(
                        icon: Icon(isEnrolled ? Icons.school : Icons.how_to_reg, size: 18),
                        text: isEnrolled ? 'Mi Curso Actual' : 'Matrícula ABC',
                      ),
                      // Tab 2: Mi Historial
                      const Tab(
                        icon: Icon(Icons.history_edu, size: 18),
                        text: 'Mi Historial',
                      ),
                      // Tab 3 (Conditional): Panel Docente
                      if (user != null && (user.isTeacher || user.isPastor))
                        const Tab(
                          icon: Icon(Icons.edit_note, size: 18),
                          text: 'Panel Docente',
                        ),
                      // Tab 4 (Conditional): Coordinación ABC
                      if (user != null && (user.isAcademyCoordinator || user.isPastor))
                        const Tab(
                          icon: Icon(Icons.admin_panel_settings, size: 18),
                          text: 'Coordinación ABC',
                        ),
                      // Tab 5 (Conditional): Reporte de Asistencias
                      if (user != null && (user.isAcademyCoordinator || user.isPastor || user.rolesList.contains('apoyo_abc')))
                        const Tab(
                          icon: Icon(Icons.assessment, size: 18),
                          text: 'Reporte Asistencias',
                        ),
                    ],
                  ),
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // TAB 1: Enrolled view OR Enrollment catalog
                      isEnrolled ? _buildActiveCourseView() : _buildEnrollmentTab(),

                      // TAB 2: History
                      _buildHistoryTab(),

                      // TAB 3: Teacher
                      if (user != null && (user.isTeacher || user.isPastor))
                        _buildTeacherPanelTab(),

                      // TAB 4: Coordinator
                      if (user != null && (user.isAcademyCoordinator || user.isPastor))
                        _buildCoordinatorTab(),

                      // TAB 5: Attendance Report
                      if (user != null && (user.isAcademyCoordinator || user.isPastor || user.rolesList.contains('apoyo_abc')))
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
    final enrollment = _getActiveEnrollment();
    if (enrollment == null) return const SizedBox.shrink();

    final course = enrollment['courses'];
    final teacher = course?['profiles'];
    final teacherName = teacher != null
        ? '${teacher['first_name'] ?? ''} ${teacher['last_name'] ?? ''}'.trim()
        : 'Docente asignado por Secretaría';

    final attendancePercentage = enrollment['attendance_percentage'];
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Matriculado en Ciclo $_activeCycle',
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

                // Metrics Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          'ASISTENCIA',
                          style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          attendancePercentage != null ? '$attendancePercentage%' : '100%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(height: 30, width: 1, color: Colors.white24),
                    Column(
                      children: [
                        Text(
                          'NOTA FINAL',
                          style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          grade != null ? '$grade / 20' : 'En Curso',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Schedule & Modality Card
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
                  'DETALLES DE LA CLASE',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.schedule, 'Horario: ${course?['schedule'] ?? "No especificado"}'),
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

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sesión: $date',
                            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary),
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
    final availableLevels = _getAvailableLevels();
    final enrollableCourses = _getEnrollableCourses();

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
                        'Selecciona tu nivel y matricúlate en el curso disponible para tu plan de discipulado.',
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

          // Level Filter Chips
          if (availableLevels.isNotEmpty) ...[
            Text(
              'NIVELES DISPONIBLES CON CURSOS ABIERTOS',
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
                children: availableLevels.map((lvl) {
                  final isSelected = _selectedLevel == lvl;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_levelNames[lvl] ?? lvl),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() => _selectedLevel = val ? lvl : null);
                      },
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceContainerLowest,
                      labelStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),
          ],

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
                      'No hay cursos disponibles para este nivel según tu historial académico.',
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
                final teacher = course['profiles'];
                final teacherName = teacher != null
                    ? '${teacher['first_name'] ?? ''} ${teacher['last_name'] ?? ''}'.trim()
                    : 'Docente asignado por Secretaría';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              course['code'] ?? '',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                          Text(
                            _levelNames[course['level']] ?? course['level'],
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600),
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
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.person_outline, 'Docente: $teacherName'),
                      const SizedBox(height: 4),
                      _buildDetailRow(Icons.schedule, 'Horario: ${course['schedule'] ?? ""}'),
                      const SizedBox(height: 4),
                      _buildDetailRow(
                        course['is_virtual'] == true ? Icons.devices : Icons.room,
                        course['is_virtual'] == true ? 'Modalidad: Virtual' : 'Aula: ${course['classroom'] ?? "Presencial"}',
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: () => _enrollInCourse(course),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Matricularme en este Curso'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 32),
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
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final sub = _approvedSubjects[index];
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
                            Text(
                              '${sub['subject_code']} - ${sub['subject_title'] ?? ""}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ciclo: ${sub['cycle'] ?? "Anterior"} • Nivel: ${_levelNames[sub['level']] ?? sub['level']}',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Nota: ${sub['grade'] ?? 20}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 32),
        ],
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
                'No tienes clases asignadas en el Ciclo $_activeCycle',
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
                Text(
                  'SELECCIONA TU CLASE ASIGNADA',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.primary,
                  ),
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
                    return DropdownMenuItem<String>(
                      value: c['id'],
                      child: Text(
                        '${c['code']}: ${c['title']} (${c['schedule']})',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
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

                // Button "Tomar Lista de Asistencia" (Open dedicated attendance taking screen)
                ElevatedButton.icon(
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
                  icon: const Icon(Icons.fact_check, size: 18),
                  label: const Text('Tomar Lista de Asistencia'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 46),
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                  ),
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
                            'Ingresa notas de 0 a 20 y guarda el acta.',
                            style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ),
                    if (_courseStudents.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: _savingGrades ? null : _saveAllGrades,
                        icon: _savingGrades
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save, size: 15),
                        label: Text(_savingGrades ? '...' : 'Guardar', style: const TextStyle(fontSize: 11.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
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
                      final att = st['attendance_percentage'] ?? 100;
                      final stId = st['student_id']?.toString() ?? '';
                      final controller = _gradeControllers[stId];

                      final isAttLow = att < 80;

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
                                    'DNI: $dni • Asistencia: $att%',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      color: isAttLow ? AppColors.error : AppColors.secondary,
                                      fontWeight: isAttLow ? FontWeight.bold : FontWeight.normal,
                                    ),
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
                                      '*Asistencia:* $att%\n\nBendiciones.';
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

          // Upload Course Materials Form
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
                  'AGREGAR MATERIAL O GUÍA DE ESTUDIO',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _materialTitleController,
                  decoration: InputDecoration(
                    labelText: 'Título del material / Guía de clase',
                    hintText: 'Ej. Guía de Estudio - Sesión 1',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _materialUrlController,
                  decoration: InputDecoration(
                    labelText: 'Enlace del archivo (PDF / Drive / Supabase)',
                    hintText: 'https://...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _savingMaterial ? null : _addCourseMaterial,
                  icon: _savingMaterial
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.upload_file, size: 16),
                  label: Text(_savingMaterial ? 'Guardando...' : 'Publicar Material'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 42),
                    backgroundColor: AppColors.primaryContainer,
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

  // TAB 4: Coordinación ABC (Subtabs: Dashboard, Ciclos, Cursos, Actas)
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
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubNavButton(String key, String title, IconData icon) {
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
          ],
        ),
      ),
    );
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
            Text(
              'CICLOS ACADÉMICOS REGISTRADOS',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AppColors.primary),
            ),
            ElevatedButton.icon(
              onPressed: _showCreateCycleDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Nuevo Ciclo', style: TextStyle(fontSize: 11.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c['cycle'] ?? '',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOpen ? const Color(0xFF16A34A).withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOpen ? 'Activo (Abierto)' : 'Cerrado',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isOpen ? const Color(0xFF16A34A) : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(isOpen ? Icons.lock : Icons.lock_open, size: 20, color: AppColors.primary),
                    tooltip: isOpen ? 'Cerrar ciclo' : 'Abrir ciclo',
                    onPressed: () async {
                      final client = Supabase.instance.client;
                      await client
                          .from('academy_cycles')
                          .update({'status': isOpen ? 'cerrado' : 'abierto'})
                          .eq('cycle', c['cycle']);
                      _loadData();
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _showCreateCycleDialog() {
    final cycleCodeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Crear Ciclo Académico', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: cycleCodeCtrl,
          decoration: const InputDecoration(
            labelText: 'Código del Ciclo',
            hintText: 'Ej. 2026-IV',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final code = cycleCodeCtrl.text.trim();
              if (code.isNotEmpty) {
                final client = Supabase.instance.client;
                await client.from('academy_cycles').insert({
                  'cycle': code,
                  'status': 'abierto',
                });
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  _loadData();
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordCourses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CURSOS DE ABC ($_statsCycle)',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AppColors.primary),
            ),
            ElevatedButton.icon(
              onPressed: _showCreateCourseDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Nuevo Curso', style: TextStyle(fontSize: 11.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _offeredCourses.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final c = _offeredCourses[index];
            final teacher = c['profiles'];
            final teacherName = teacher != null
                ? '${teacher['first_name'] ?? ''} ${teacher['last_name'] ?? ''}'.trim()
                : 'Sin docente asignado';
            final isActive = c['is_active'] ?? true;
            final isVirtual = c['is_virtual'] == true;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
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
                            Expanded(
                              child: Text(
                                '${c['code']} - ${c['title']}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Docente: $teacherName • ${c['schedule'] ?? ""}',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isActive,
                    activeThumbColor: const Color(0xFF16A34A),
                    onChanged: (val) async {
                      final client = Supabase.instance.client;
                      await client.from('courses').update({'is_active': val}).eq('id', c['id']);
                      _loadData();
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _showCreateCourseDialog() {
    String? selectedCurriculumCode;
    final codeCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final scheduleCtrl = TextEditingController(text: 'Domingo 09:45');
    final classroomCtrl = TextEditingController();
    final virtualPlatformCtrl = TextEditingController(text: 'Zoom');
    final virtualLinkCtrl = TextEditingController();
    final bookTitleCtrl = TextEditingController();
    final bookStoreCtrl = TextEditingController();
    String level = 'inicial';
    bool isVirtual = false;
    String? teacherId;

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
                  // Dropdown to pick a course from the curriculum
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
                                scheduleCtrl.text = 'Domingo 09:45';
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
                                scheduleCtrl.text = 'Jueves 20:00';
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Auto-calculated Schedule
                  TextField(
                    controller: scheduleCtrl,
                    decoration: InputDecoration(
                      labelText: isVirtual ? 'Horario Virtual (Jueves 20:00)' : 'Horario Presencial (Domingo 09:45)',
                      labelStyle: const TextStyle(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                  });
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                  if (mounted) {
                    _loadData();
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
    final filtered = _allReportsList.where((c) => c['cycle'] == _statsCycle).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACTAS DE NOTAS DE LOS CURSOS ($_statsCycle)',
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AppColors.primary),
        ),
        const SizedBox(height: 12),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final c = filtered[index];
            final students = c['students'] as List;

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
                          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${students.length} Alumnos', style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Docente: ${c['teacherName']}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary)),
                  if (students.isNotEmpty) ...[
                    const Divider(height: 16),
                    ...students.map((st) {
                      final grade = st['grade'];
                      final isApproved = grade != null && double.tryParse(grade.toString()) != null && double.parse(grade.toString()) >= 14;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(st['name'], style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                            Text(
                              grade != null ? 'Nota: $grade (${isApproved ? "Aprobado" : "Desaprobado"})' : 'Sin Nota',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: grade != null ? (isApproved ? const Color(0xFF16A34A) : AppColors.error) : AppColors.secondary,
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

  // TAB 5: Reporte Detallado de Asistencias (Para apoyo_abc, coordinador y pastor)
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
                      Text(
                        'Reporte Detallado de Asistencias',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'Desglose sesión por sesión para el ciclo.',
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

          const SizedBox(height: 14),

          if (_loadingAttendanceReport)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_attendanceReportData.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No hay cursos registrados en el ciclo $_attendanceCycle.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _attendanceReportData.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final course = _attendanceReportData[index];
                final isExpanded = _expandedAttendanceCourseId == course['id'];
                final sessionsList = course['sessionsList'] as List;
                final students = course['students'] as List;

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
                                    Text(
                                      '${course['code']}: ${course['title']}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Docente: ${course['teacherName']} • ${students.length} Alumnos',
                                      style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.secondary),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.primary, size: 20),
                            ],
                          ),
                        ),
                      ),

                      if (isExpanded) ...[
                        const Divider(height: 1),
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
                              dataRowMaxHeight: 42,
                              columnSpacing: 16,
                              columns: [
                                const DataColumn(label: Text('Estudiante', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                                const DataColumn(label: Text('Asist %', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold))),
                                ...sessionsList.map((sDate) => DataColumn(
                                      label: Text('Sem: $sDate', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                                    )),
                              ],
                              rows: students.map<DataRow>((st) {
                                final attPct = st['attendancePercentage'] ?? 100;
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
                                        '$attPct%',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: attPct >= 80 ? const Color(0xFF16A34A) : AppColors.error,
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

          const SizedBox(height: 32),
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
