import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

class AdminAttendanceScreen extends ConsumerStatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  ConsumerState<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends ConsumerState<AdminAttendanceScreen> {
  bool _loading = true;
  String _selectedSessionFilter = 'all'; // 'all', 'semanal', 'central'
  
  List<Map<String, dynamic>> _cellsList = [];
  List<Map<String, dynamic>> _attendanceList = [];
  Map<String, List<Map<String, dynamic>>> _groupedReports = {};
  int _totalCells = 0;
  int _reportedCells = 0;
  int _totalPresent = 0;

  static const Map<String, String> networkCategoryNames = {
    'kids': 'Generación Kids',
    'free': 'Red Free',
    'legado': 'Red Legado',
    'dunamis': 'Red Dunamis',
    'mujeres': 'Red de Mujeres',
    'varones': 'Red de Varones',
    'matrimonios': 'Red de Matrimonios',
    'maravillosos': 'Años Maravillosos',
  };

  static const List<String> networkKeysOrder = [
    'kids',
    'free',
    'legado',
    'dunamis',
    'mujeres',
    'varones',
    'matrimonios',
    'maravillosos',
  ];

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData();
  }

  Future<void> _fetchAttendanceData() async {
    setState(() => _loading = true);
    final client = Supabase.instance.client;

    try {
      final cellsRes = await client
          .from('cell_groups')
          .select('*, leader:leader_id(first_name, last_name, email)');

      final attendanceRes = await client
          .from('group_attendance')
          .select()
          .order('session_date', ascending: false);

      _cellsList = List<Map<String, dynamic>>.from(cellsRes);
      _attendanceList = List<Map<String, dynamic>>.from(attendanceRes);

      _processAttendanceGrouping();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error al cargar asistencias: $e')),
        );
      }
    }
  }

  void _processAttendanceGrouping() {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    int total = 0;
    int reported = 0;
    int presentSum = 0;

    for (final cell in _cellsList) {
      final cellId = cell['id'];
      
      // Filter attendance records by session filter if specified
      final cellAtts = _attendanceList.where((a) {
        if (a['cell_id'] != cellId) return false;
        final type = a['attendance_type']?.toString().toLowerCase();
        if (_selectedSessionFilter == 'central') {
          return type == 'central';
        } else if (_selectedSessionFilter == 'semanal') {
          return type == 'semanal' || type == 'gp' || type == null;
        }
        return true;
      }).toList();

      final latestAtt = cellAtts.isNotEmpty ? cellAtts.first : null;

      final leader = cell['leader'];
      final leaderName = leader != null
          ? '${leader['first_name'] ?? ''} ${leader['last_name'] ?? ''}'.trim()
          : 'Líder no asignado';
      final email = leader?['email'] ?? '';

      final netKey = (cell['network'] ?? 'dunamis').toString().toLowerCase();
      final isReported = latestAtt != null;

      total++;
      if (isReported) {
        reported++;
        final p = (latestAtt['present_count'] as num?)?.toInt() ?? 0;
        presentSum += p;
      }

      final reportItem = {
        'id': cellId,
        'name': cell['name'] ?? 'Célula',
        'leaderName': leaderName,
        'email': email,
        'assignedCount': latestAtt?['total_assigned'] ?? cell['member_count'] ?? 0,
        'presentCount': latestAtt?['present_count'],
        'isReported': isReported,
        'lastSessionDate': latestAtt?['session_date'],
        'attendanceType': latestAtt?['attendance_type'] ?? 'semanal',
      };

      if (!groups.containsKey(netKey)) {
        groups[netKey] = [];
      }
      groups[netKey]!.add(reportItem);
    }

    if (mounted) {
      setState(() {
        _totalCells = total;
        _reportedCells = reported;
        _totalPresent = presentSum;
        _groupedReports = groups;
        _loading = false;
      });
    }
  }

  String _formatSessionDate(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr.toString());
      return DateFormat("d 'de' MMMM", 'es').format(date);
    } catch (_) {
      return dateStr.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Control de Asistencias',
          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Sincronizar',
            onPressed: _loading ? null : _fetchAttendanceData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAttendanceData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Session Type Filter Tabs
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          _buildSessionFilterTab('all', 'Todas', Icons.dashboard_outlined),
                          _buildSessionFilterTab('semanal', 'Reunión GP', Icons.groups_outlined),
                          _buildSessionFilterTab('central', 'Culto Central', Icons.church_outlined),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Summary Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedSessionFilter == 'central'
                                      ? 'Sesión: Culto Central'
                                      : _selectedSessionFilter == 'semanal'
                                          ? 'Sesión: Grupos Pequeños (GP)'
                                          : 'Resumen Global de Sesiones',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$_totalPresent asistentes registrados en reporte.',
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$_reportedCells / $_totalCells',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                                Text('Reportados', style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.secondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Grouped List by Network (without ages)
                    ...networkKeysOrder.map((netKey) {
                      final list = _groupedReports[netKey] ?? [];
                      if (list.isEmpty) return const SizedBox.shrink();

                      final netTitle = networkCategoryNames[netKey] ?? netKey.toUpperCase();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  netTitle,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text('${list.length} células', style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary)),
                              ],
                            ),
                            const SizedBox(height: 10),

                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: list.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = list[index];
                                final isReported = item['isReported'] == true;
                                final present = item['presentCount'];
                                final assigned = item['assignedCount'] ?? 0;
                                final sessionDateFormatted = _formatSessionDate(item['lastSessionDate']);
                                final isCentral = item['attendanceType'] == 'central';

                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerLowest,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: !isReported ? const Color(0xFFFBBF24) : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    item['name'],
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 13.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ),
                                                if (isReported) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: isCentral
                                                          ? const Color(0xFFFEF3C7)
                                                          : const Color(0xFFE0E7FF),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      isCentral ? 'Culto' : 'GP',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                        color: isCentral
                                                            ? const Color(0xFF92400E)
                                                            : const Color(0xFF3730A3),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Líder: ${item['leaderName']}',
                                              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.secondary),
                                            ),
                                            if (sessionDateFormatted.isNotEmpty)
                                              Text(
                                                'Fecha sesión: $sessionDateFormatted',
                                                style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.onSurfaceVariant),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isReported
                                              ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                                              : const Color(0xFFD97706).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              isReported ? '$present / $assigned' : 'Pendiente',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isReported ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                              ),
                                            ),
                                            Text(
                                              isReported ? 'Asistencia' : 'Sin reporte',
                                              style: GoogleFonts.inter(
                                                fontSize: 9,
                                                color: isReported ? const Color(0xFF16A34A) : const Color(0xFFD97706),
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
                        ),
                      );
                    }),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSessionFilterTab(String key, String title, IconData icon) {
    final isSelected = _selectedSessionFilter == key;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedSessionFilter = key;
            _processAttendanceGrouping();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
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
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
