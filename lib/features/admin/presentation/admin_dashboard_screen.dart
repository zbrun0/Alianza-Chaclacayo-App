import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_provider.dart';
import 'admin_members_screen.dart';
import 'admin_treasury_screen.dart';
import 'admin_attendance_screen.dart';
import 'admin_culto_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _loading = true;
  int _totalMembers = 0;
  int _baptizedCount = 0;
  int _baptizedPercentage = 0;
  int _cellAttendance = 0;
  int _academyStudents = 0;

  final Map<String, int> _networkCounts = {
    'kids': 0,
    'next': 0,
    'free': 0,
    'legado': 0,
    'dunamis': 0,
    'maravillosos': 0,
    'mujeres': 0,
    'varones': 0,
    'matrimonios': 0,
  };

  final Map<String, String> _networkLabels = {
    'kids': 'Generación Kids',
    'next': 'NEXT (Pre-adolescentes)',
    'free': 'Free (Adolescentes)',
    'legado': 'Legado (Jóvenes)',
    'dunamis': 'Dunamis (Jóvenes Adultos)',
    'maravillosos': 'Años Maravillosos',
    'mujeres': 'Red de Mujeres',
    'varones': 'Red de Varones',
    'matrimonios': 'Red de Matrimonios',
  };

  final TextEditingController _youtubeUrlController = TextEditingController();
  bool _savingYoutube = false;
  bool _youtubeSavedSuccess = false;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  @override
  void dispose() {
    _youtubeUrlController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _loading = true);
    final client = Supabase.instance.client;

    try {
      // 1. Fetch member statistics
      final membersRes = await client
          .from('profiles')
          .select('is_approved, is_baptized, assigned_network')
          .eq('is_approved', true);

      final membersList = List<Map<String, dynamic>>.from(membersRes);
      final total = membersList.length;
      final baptized = membersList.where((m) => m['is_baptized'] == true).length;
      final baptizedPct = total > 0 ? ((baptized / total) * 100).round() : 0;

      // Reset network counts
      _networkCounts.updateAll((key, value) => 0);
      for (final m in membersList) {
        final net = m['assigned_network']?.toString().toLowerCase();
        if (net != null && _networkCounts.containsKey(net)) {
          _networkCounts[net] = (_networkCounts[net] ?? 0) + 1;
        }
      }

      // 2. Fetch academy enrollments count
      final enrollCountRes = await client
          .from('enrollments')
          .count(CountOption.exact);

      // 3. Fetch latest cell attendance
      final attRes = await client
          .from('group_attendance')
          .select('present_count');

      int cellAttTotal = 0;
      for (final item in attRes) {
        cellAttTotal += (item['present_count'] as num?)?.toInt() ?? 0;
      }

      // 4. Fetch YouTube live URL setting
      final settingRes = await client
          .from('church_settings')
          .select('value')
          .eq('key', 'youtube_live_url')
          .maybeSingle();

      if (settingRes != null && settingRes['value'] != null) {
        _youtubeUrlController.text = settingRes['value'].toString();
      }

      if (mounted) {
        setState(() {
          _totalMembers = total;
          _baptizedCount = baptized;
          _baptizedPercentage = baptizedPct;
          _academyStudents = enrollCountRes;
          _cellAttendance = cellAttTotal;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveYoutubeUrl() async {
    final rawUrl = _youtubeUrlController.text.trim();
    if (rawUrl.isEmpty) return;

    setState(() {
      _savingYoutube = true;
      _youtubeSavedSuccess = false;
    });

    final client = Supabase.instance.client;
    try {
      String formattedUrl = rawUrl;
      if (formattedUrl.contains('youtube.com/watch?v=')) {
        final vidId = formattedUrl.split('v=')[1].split('&')[0];
        formattedUrl = 'https://www.youtube.com/embed/$vidId';
      } else if (formattedUrl.contains('youtu.be/')) {
        final vidId = formattedUrl.split('youtu.be/')[1].split('?')[0];
        formattedUrl = 'https://www.youtube.com/embed/$vidId';
      } else if (formattedUrl.contains('youtube.com/live/')) {
        final vidId = formattedUrl.split('youtube.com/live/')[1].split('?')[0];
        formattedUrl = 'https://www.youtube.com/embed/$vidId';
      }

      await client.from('church_settings').upsert({
        'key': 'youtube_live_url',
        'value': formattedUrl,
      });

      if (mounted) {
        setState(() {
          _savingYoutube = false;
          _youtubeSavedSuccess = true;
          _youtubeUrlController.text = formattedUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF16A34A),
            content: Text('¡Enlace de transmisión de YouTube actualizado con éxito!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _savingYoutube = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error al guardar URL: $e')),
        );
      }
    }
  }

  String _getFormattedDate() {
    try {
      final now = DateTime.now();
      final text = DateFormat("EEEE d 'de' MMMM, yyyy", 'es').format(now);
      return text[0].toUpperCase() + text.substring(1);
    } catch (_) {
      final now = DateTime.now();
      return '${now.day}/${now.month}/${now.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.userProfile;
    final formattedDate = _getFormattedDate();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              height: 32,
              width: 32,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SvgPicture.asset(
                'assets/images/logo.svg',
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.church, color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Panel Pastoral - Backoffice',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user != null ? '${user.name} • ${user.roleTranslated}' : 'Administración',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.onPrimaryContainer,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Sincronizar métricas',
            onPressed: _loading ? null : _fetchDashboardData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard Intro Banner
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DASHBOARD GENERAL',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'En Tiempo Real',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quick Module Links Grid
              Text(
                'MÓDULOS DE GESTIÓN',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.6,
                children: [
                  if (user != null && user.isPastor)
                    _buildModuleTile(
                      icon: Icons.groups,
                      iconColor: const Color(0xFF1E40AF),
                      iconBg: const Color(0xFFDBEAFE),
                      title: 'Directorio Miembros',
                      subtitle: 'Aprobaciones y roles',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminMembersScreen()),
                      ),
                    ),
                  if (user != null && (user.isPastor || user.isTreasuryAdmin))
                    _buildModuleTile(
                      icon: Icons.payments,
                      iconColor: const Color(0xFF047857),
                      iconBg: const Color(0xFFD1FAE5),
                      title: 'Tesorería Reservada',
                      subtitle: 'Revisión de vouchers',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminTreasuryScreen()),
                      ),
                    ),
                  if (user != null && (user.isPastor || user.isGroupLeader))
                    _buildModuleTile(
                      icon: Icons.how_to_reg,
                      iconColor: const Color(0xFF7C3AED),
                      iconBg: const Color(0xFFEDE9FE),
                      title: 'Control Asistencias',
                      subtitle: 'Reporte de células',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminAttendanceScreen()),
                      ),
                    ),
                  if (user != null && (user.isPastor || user.isCultoAdmin))
                    _buildModuleTile(
                      icon: Icons.church,
                      iconColor: const Color(0xFFB45309),
                      iconBg: const Color(0xFFFEF3C7),
                      title: 'Conteo de Culto',
                      subtitle: 'Asistencia dominical',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminCultoScreen()),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // KPI Metrics Grid
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                Text(
                  'INDICADORES CLAVE (KPI)',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.35,
                  children: [
                    _buildKpiCard(
                      icon: Icons.groups,
                      iconColor: const Color(0xFF1E40AF),
                      title: 'Membresía Total',
                      value: '$_totalMembers',
                      subtitle: 'Miembros autorizados',
                    ),
                    _buildKpiCard(
                      icon: Icons.water_drop,
                      iconColor: const Color(0xFF0284C7),
                      title: '% Bautizados',
                      value: '$_baptizedPercentage%',
                      subtitle: '$_baptizedCount de $_totalMembers bautizados',
                    ),
                    _buildKpiCard(
                      icon: Icons.pin_drop,
                      iconColor: const Color(0xFF047857),
                      title: 'Asistencia Células',
                      value: '$_cellAttendance',
                      subtitle: 'Asistentes acumulados',
                    ),
                    _buildKpiCard(
                      icon: Icons.school,
                      iconColor: const Color(0xFF7C3AED),
                      title: 'Alumnos ABC',
                      value: '$_academyStudents',
                      subtitle: 'Inscritos en cursos',
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // YouTube Live Stream Setting Container
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
                        children: [
                          const Icon(Icons.live_tv, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Transmisión de Culto en Vivo (YouTube)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Actualiza el enlace del video o transmisión en vivo que verán los miembros en el inicio.',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _youtubeUrlController,
                        decoration: InputDecoration(
                          hintText: 'https://www.youtube.com/watch?v=...',
                          labelText: 'URL de Video / Transmisión de YouTube',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _savingYoutube ? null : _saveYoutubeUrl,
                        icon: _savingYoutube
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save, size: 16),
                        label: Text(_savingYoutube ? 'Guardando...' : 'Guardar Enlace para la App'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 42),
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      if (_youtubeSavedSuccess) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '¡Enlace actualizado en tiempo real!',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Network Breakdown Section
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
                        'INTEGRANTES POR REDES MINISTERIALES',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 14),

                      ..._networkCounts.entries.map((entry) {
                        final label = _networkLabels[entry.key] ?? entry.key;
                        final count = entry.value;
                        final maxVal = _networkCounts.values.fold(1, (max, v) => v > max ? v : max);
                        final pct = maxVal > 0 ? (count / maxVal) : 0.0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    label,
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                  ),
                                  Text(
                                    '$count miembros',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 8,
                                  backgroundColor: AppColors.surfaceContainerLow,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryContainer),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 10, color: AppColors.secondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Icon(icon, color: iconColor, size: 18),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.secondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
