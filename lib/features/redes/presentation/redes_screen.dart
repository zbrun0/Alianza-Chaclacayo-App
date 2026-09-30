import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_provider.dart';
import 'asistencia_celula_screen.dart';

class ChurchNetworkInfo {
  final String id;
  final String name;
  final String ageBracket;
  final String description;
  final String meetingTime;
  final String location;
  final Color themeColor;

  const ChurchNetworkInfo({
    required this.id,
    required this.name,
    required this.ageBracket,
    required this.description,
    required this.meetingTime,
    required this.location,
    required this.themeColor,
  });
}

const List<ChurchNetworkInfo> officialNetworks = [
  ChurchNetworkInfo(
    id: 'kids',
    name: 'GENERACIÓN KIDS',
    ageBracket: '1 a 12 Años',
    description: 'Espacio de edificación bíblica y aprendizaje lúdico para niños.',
    meetingTime: 'Domingos 10:00 AM',
    location: 'Aula Infantil - Templo Central',
    themeColor: Color(0xFFDC2626),
  ),
  ChurchNetworkInfo(
    id: 'free',
    name: 'FREE',
    ageBracket: '13 a 17 Años',
    description: 'Red de adolescentes con pasión por Cristo y amistad cristiana.',
    meetingTime: 'Sábados 5:00 PM',
    location: 'Auditorio Juvenil',
    themeColor: Color(0xFFEA580C),
  ),
  ChurchNetworkInfo(
    id: 'legado',
    name: 'LEGADO',
    ageBracket: '18 a 27 Años',
    description: 'Jóvenes universitarios y profesionales formando carácter e impacto.',
    meetingTime: 'Sábados 7:30 PM',
    location: 'Auditorio Principal',
    themeColor: Color(0xFF065F46),
  ),
  ChurchNetworkInfo(
    id: 'dunamis',
    name: 'DUNAMIS',
    ageBracket: '28 a 45 Años',
    description: 'Jóvenes adultos, fuerza y poder espiritual para transformar la sociedad.',
    meetingTime: 'Viernes 8:00 PM',
    location: 'Salón Multiusos',
    themeColor: Color(0xFF2563EB),
  ),
  ChurchNetworkInfo(
    id: 'mujeres',
    name: 'MUJERES DE FE',
    ageBracket: 'Damas',
    description: 'Mujeres de oración, sabiduría doméstica y edificación espiritual.',
    meetingTime: 'Jueves 4:00 PM',
    location: 'Templo Central',
    themeColor: Color(0xFFDB2777),
  ),
  ChurchNetworkInfo(
    id: 'varones',
    name: 'VARONES VALIENTES',
    ageBracket: 'Varones',
    description: 'Hombres de Dios, sacerdotes del hogar e intercesores.',
    meetingTime: 'Sábados 7:00 AM',
    location: 'Capilla Chaclacayo',
    themeColor: Color(0xFF1E1B4B),
  ),
  ChurchNetworkInfo(
    id: 'matrimonios',
    name: 'MATRIMONIOS UNIDOS',
    ageBracket: 'Parejas y Esposos',
    description: 'Construyendo familias sólidas sobre la roca de la Palabra.',
    meetingTime: '1er y 3er Viernes 8:00 PM',
    location: 'Salón Principal',
    themeColor: Color(0xFF991B1B),
  ),
  ChurchNetworkInfo(
    id: 'maravillosos',
    name: 'AÑOS MARAVILLOSOS',
    ageBracket: 'Adultos Mayores',
    description: 'Plenitud, consejería y sabiduría en la etapa dorada.',
    meetingTime: 'Miércoles 3:30 PM',
    location: 'Salón de Usos Múltiples',
    themeColor: Color(0xFF0284C7),
  ),
];

class RedesScreen extends ConsumerStatefulWidget {
  const RedesScreen({super.key});

  @override
  ConsumerState<RedesScreen> createState() => _RedesScreenState();
}

class _RedesScreenState extends ConsumerState<RedesScreen> {
  Map<String, dynamic>? _userCell;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyCell();
  }

  Future<void> _fetchMyCell() async {
    final user = ref.read(authStateProvider).userProfile;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final client = Supabase.instance.client;

      // 1. Check if user has cell_id in profile
      final profileRes = await client
          .from('profiles')
          .select('cell_id')
          .eq('id', user.id)
          .maybeSingle();

      final userCellId = profileRes?['cell_id'];

      if (userCellId != null) {
        final cellRes = await client
            .from('cell_groups')
            .select('*, profiles:leader_id(first_name, last_name, phone)')
            .eq('id', userCellId)
            .maybeSingle();
        if (cellRes != null) {
          _userCell = cellRes;
        }
      }

      // 2. Or if user is the leader of a cell group
      if (_userCell == null) {
        final ledCellRes = await client
            .from('cell_groups')
            .select('*, profiles:leader_id(first_name, last_name, phone)')
            .eq('leader_id', user.id)
            .maybeSingle();
        if (ledCellRes != null) {
          _userCell = ledCellRes;
        }
      }

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openMap(String location) async {
    final query = Uri.encodeComponent('$location, Chaclacayo, Lima, Perú');
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).userProfile;
    final assignedNetworkId = user?.assignedNetwork ?? 'dunamis';

    final currentNet = officialNetworks.firstWhere(
      (n) => n.id == assignedNetworkId,
      orElse: () => officialNetworks[0],
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: _fetchMyCell,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tarjeta Principal de la Red Asignada
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [currentNet.themeColor, currentNet.themeColor.withValues(alpha: 0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: currentNet.themeColor.withValues(alpha: 0.3),
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
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'MI RED ASIGNADA • ${currentNet.ageBracket.toUpperCase()}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentNet.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentNet.description,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Información Detallada de Reuniones (Sin encargado)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DATOS DE LA REUNIÓN',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildInfoRow(Icons.schedule, 'Horario de Reunión', currentNet.meetingTime),
                    const Divider(height: 16),
                    _buildInfoRow(Icons.place, 'Lugar de Encuentro', currentNet.location),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Mi Célula / Grupo Pequeño (Solo la propia)
              Text(
                'MI CÉLULA / GRUPO PEQUEÑO',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),

              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_userCell == null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.groups_outlined, size: 40, color: AppColors.secondary),
                      const SizedBox(height: 10),
                      Text(
                        'Aún no tienes una célula asignada',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Para integrarte a un grupo pequeño en tu zona, coordina con el liderazgo de tu red o secretaría.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary),
                      ),
                    ],
                  ),
                )
              else
                _buildMyCellCard(_userCell!),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyCellCard(Map<String, dynamic> cell) {
    final name = cell['name'] ?? 'Mi Célula';
    final zone = cell['zone'] ?? 'Chaclacayo';
    final schedule = cell['meeting_schedule'] ?? 'Viernes 8:00 PM';
    final leaderProfile = cell['profiles'];
    final leaderName = leaderProfile != null
        ? '${leaderProfile['first_name'] ?? ''} ${leaderProfile['last_name'] ?? ''}'.trim()
        : (cell['leader_name'] ?? 'Líder de Célula');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Activa',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF065F46),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildDetailItem(Icons.person, 'Líder: $leaderName'),
          const SizedBox(height: 4),
          _buildDetailItem(Icons.schedule, 'Horario: $schedule'),
          const SizedBox(height: 4),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AsistenciaCelulaScreen(
                          cellId: cell['id'].toString(),
                          cellName: name,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.how_to_reg, size: 16),
                  label: const Text('Tomar Asistencia'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _openMap(zone),
                icon: const Icon(Icons.location_searching, size: 15),
                label: const Text('Mapa'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.secondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
