import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_provider.dart';

class AdminCultoScreen extends ConsumerStatefulWidget {
  const AdminCultoScreen({super.key});

  @override
  ConsumerState<AdminCultoScreen> createState() => _AdminCultoScreenState();
}

class _AdminCultoScreenState extends ConsumerState<AdminCultoScreen> {
  final TextEditingController _titleController = TextEditingController(text: 'Culto Dominical Principal');
  final TextEditingController _inRoomCountController = TextEditingController();
  final TextEditingController _serversCountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _youtubeUrlController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;
  bool _isSaved = false;
  bool _savingYoutube = false;
  bool _loadingHistory = true;
  List<Map<String, dynamic>> _countHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchSettingsAndHistory();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _inRoomCountController.dispose();
    _serversCountController.dispose();
    _notesController.dispose();
    _youtubeUrlController.dispose();
    super.dispose();
  }

  Future<void> _fetchSettingsAndHistory() async {
    final client = Supabase.instance.client;
    try {
      final setting = await client
          .from('church_settings')
          .select('value')
          .eq('key', 'youtube_live_url')
          .maybeSingle();

      if (setting != null && setting['value'] != null && mounted) {
        _youtubeUrlController.text = setting['value'].toString();
      }

      // Fetch past central counts
      final historyRes = await client
          .from('group_attendance')
          .select()
          .eq('attendance_type', 'central')
          .order('session_date', ascending: false)
          .limit(10);

      if (mounted) {
        setState(() {
          _countHistory = List<Map<String, dynamic>>.from(historyRes);
          _loadingHistory = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingHistory = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'PE'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveYoutube() async {
    final raw = _youtubeUrlController.text.trim();
    if (raw.isEmpty) return;

    setState(() => _savingYoutube = true);
    final client = Supabase.instance.client;
    try {
      String formatted = raw;
      if (formatted.contains('youtube.com/watch?v=')) {
        final vidId = formatted.split('v=')[1].split('&')[0];
        formatted = 'https://www.youtube.com/embed/$vidId';
      } else if (formatted.contains('youtu.be/')) {
        final vidId = formatted.split('youtu.be/')[1].split('?')[0];
        formatted = 'https://www.youtube.com/embed/$vidId';
      } else if (formatted.contains('youtube.com/live/')) {
        final vidId = formatted.split('youtube.com/live/')[1].split('?')[0];
        formatted = 'https://www.youtube.com/embed/$vidId';
      }

      await client.from('church_settings').upsert({
        'key': 'youtube_live_url',
        'value': formatted,
      });

      if (mounted) {
        setState(() {
          _savingYoutube = false;
          _youtubeUrlController.text = formatted;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF16A34A),
            content: Text('¡Enlace de transmisión de YouTube actualizado!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _savingYoutube = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    final title = _titleController.text.trim().isEmpty ? 'Culto Dominical Principal' : _titleController.text.trim();
    final inRoomStr = _inRoomCountController.text.trim();
    final serversStr = _serversCountController.text.trim();
    final notes = _notesController.text.trim();

    final inRoom = int.tryParse(inRoomStr) ?? 0;
    final servers = int.tryParse(serversStr) ?? 0;

    if (inRoomStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa la cantidad de asistentes en sala')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final client = Supabase.instance.client;
    final user = ref.read(authStateProvider).userProfile;
    final formattedDate = _selectedDate.toIso8601String().split('T')[0];

    try {
      final totalAttendees = inRoom + servers;

      if (user != null) {
        await client.from('group_attendance').insert({
          'session_date': formattedDate,
          'present_count': totalAttendees,
          'total_assigned': totalAttendees,
          'recorded_by': user.id,
          'attendance_type': 'central',
          'attendance_details': {
            'title': title,
            'in_room': inRoom,
            'servers': servers,
            'notes': notes,
          },
        });
      }

      // Add to local history list
      final newRecord = {
        'id': UniqueKey().toString(),
        'session_date': formattedDate,
        'present_count': totalAttendees,
        'total_assigned': totalAttendees,
        'attendance_type': 'central',
        'attendance_details': {
          'title': title,
          'in_room': inRoom,
          'servers': servers,
          'notes': notes,
        },
      };

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSaved = true;
          _countHistory.insert(0, newRecord);
          _inRoomCountController.clear();
          _serversCountController.clear();
          _notesController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF16A34A),
            content: Text('¡Conteo dominical registrado con éxito para el reporte pastoral!'),
          ),
        );

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _isSaved = false);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error al guardar conteo: $e')),
        );
      }
    }
  }

  String _formatDisplayDate(DateTime date) {
    try {
      return DateFormat("EEEE, d 'de' MMMM yyyy", 'es').format(date);
    } catch (_) {
      return '${date.day}/${date.month}/${date.year}';
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
          'Registro de Culto Central',
          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Recargar',
            onPressed: _fetchSettingsAndHistory,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONTADOR DE ASISTENCIA PRESENCIAL',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _titleController.text.isEmpty ? 'Culto Dominical Principal' : _titleController.text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, color: Colors.white70, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        _formatDisplayDate(_selectedDate),
                        style: GoogleFonts.inter(fontSize: 11.5, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Form Inputs
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Datos de la Sesión / Culto',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 14),

                  // Title Field
                  TextField(
                    controller: _titleController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Título o Nombre del Culto *',
                      hintText: 'Ej. Culto Dominical Principal',
                      prefixIcon: const Icon(Icons.edit_note, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Date Picker Selector
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Fecha del Culto', style: GoogleFonts.inter(fontSize: 10, color: AppColors.secondary)),
                                Text(
                                  _formatDisplayDate(_selectedDate),
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: AppColors.secondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Attendees count
                  TextField(
                    controller: _inRoomCountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Cantidad de Asistentes en Sala *',
                      hintText: 'Ej. 245',
                      prefixIcon: const Icon(Icons.groups, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Servers count
                  TextField(
                    controller: _serversCountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Cantidad de Servidores en Función (Opcional)',
                      hintText: 'Ej. 35',
                      prefixIcon: const Icon(Icons.volunteer_activism, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Notes
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Observaciones / Novedades del Culto',
                      hintText: 'Culto especial con bautismos o delegaciones invitadas...',
                      alignLabelWithHint: true,
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 18),

                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    icon: _isSubmitting
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(_isSaved ? Icons.check : Icons.send, size: 18),
                    label: Text(_isSubmitting ? 'Enviando...' : (_isSaved ? '¡Conteo Registrado!' : 'Guardar y Enviar Conteo')),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 46),
                      backgroundColor: _isSaved ? const Color(0xFF16A34A) : AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // History of Counts Section
            Container(
              padding: const EdgeInsets.all(18),
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
                        'HISTORIAL DE CONTEOS REGISTRADOS',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '${_countHistory.length} registros',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_loadingHistory)
                    const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                  else if (_countHistory.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No hay registros de conteo previos.',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _countHistory.length,
                      separatorBuilder: (context, index) => const Divider(height: 16, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, index) {
                        final item = _countHistory[index];
                        final dateStr = item['session_date']?.toString() ?? '';
                        final total = (item['present_count'] as num?)?.toInt() ?? 0;
                        final details = item['attendance_details'] is Map ? item['attendance_details'] as Map : {};
                        final title = details['title']?.toString() ?? 'Culto Central';
                        final inRoom = details['in_room'] ?? total;
                        final servers = details['servers'] ?? 0;
                        final notes = details['notes']?.toString() ?? '';

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.church, color: AppColors.primary, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                  Text(
                                    'Fecha: $dateStr • Sala: $inRoom • Servidores: $servers',
                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary),
                                  ),
                                  if (notes.isNotEmpty)
                                    Text(
                                      'Nota: $notes',
                                      style: GoogleFonts.inter(fontSize: 10.5, fontStyle: FontStyle.italic, color: AppColors.onSurfaceVariant),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$total pers.',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Stream Setting Card
            Container(
              padding: const EdgeInsets.all(18),
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
                      const Icon(Icons.live_tv, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Transmisión en Vivo (YouTube)',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pega el enlace de la transmisión dominical que se reproducirá en la aplicación.',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _youtubeUrlController,
                    decoration: InputDecoration(
                      hintText: 'https://www.youtube.com/watch?v=...',
                      labelText: 'Enlace del video / Live',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: _savingYoutube ? null : _saveYoutube,
                    icon: _savingYoutube
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save, size: 16),
                    label: Text(_savingYoutube ? 'Guardando...' : 'Actualizar Transmisión'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 42),
                      backgroundColor: AppColors.primaryContainer,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
