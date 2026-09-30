import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/resend_email_service.dart';
import '../../auth/data/auth_provider.dart';

class BookReading {
  final String name;
  final int startChapter;
  final int chapters;
  final String bibleGatewayName;

  const BookReading({
    required this.name,
    required this.startChapter,
    required this.chapters,
    required this.bibleGatewayName,
  });
}

const List<BookReading> readingPlanBooks = [
  BookReading(name: 'Salmos', startChapter: 121, chapters: 30, bibleGatewayName: 'Salmos'),
  BookReading(name: 'Proverbios', startChapter: 1, chapters: 31, bibleGatewayName: 'Proverbios'),
  BookReading(name: 'Eclesiastés', startChapter: 1, chapters: 12, bibleGatewayName: 'Eclesiastes'),
  BookReading(name: 'Cantares', startChapter: 1, chapters: 8, bibleGatewayName: 'Cantares'),
  BookReading(name: 'Isaías', startChapter: 1, chapters: 66, bibleGatewayName: 'Isaias'),
  BookReading(name: 'Jeremías', startChapter: 1, chapters: 52, bibleGatewayName: 'Jeremias'),
  BookReading(name: 'Lamentaciones', startChapter: 1, chapters: 5, bibleGatewayName: 'Lamentaciones'),
  BookReading(name: 'Ezequiel', startChapter: 1, chapters: 48, bibleGatewayName: 'Ezequiel'),
  BookReading(name: 'Daniel', startChapter: 1, chapters: 12, bibleGatewayName: 'Daniel'),
  BookReading(name: 'Oseas', startChapter: 1, chapters: 14, bibleGatewayName: 'Oseas'),
  BookReading(name: 'Joel', startChapter: 1, chapters: 3, bibleGatewayName: 'Joel'),
  BookReading(name: 'Amós', startChapter: 1, chapters: 9, bibleGatewayName: 'Amos'),
  BookReading(name: 'Abdías', startChapter: 1, chapters: 1, bibleGatewayName: 'Abdias'),
  BookReading(name: 'Jonás', startChapter: 1, chapters: 4, bibleGatewayName: 'Jonas'),
  BookReading(name: 'Miqueas', startChapter: 1, chapters: 7, bibleGatewayName: 'Miqueas'),
  BookReading(name: 'Nahúm', startChapter: 1, chapters: 3, bibleGatewayName: 'Nahum'),
  BookReading(name: 'Habacuc', startChapter: 1, chapters: 3, bibleGatewayName: 'Habacuc'),
  BookReading(name: 'Sofonías', startChapter: 1, chapters: 3, bibleGatewayName: 'Sofonias'),
  BookReading(name: 'Hageo', startChapter: 1, chapters: 2, bibleGatewayName: 'Hageo'),
  BookReading(name: 'Zacarías', startChapter: 1, chapters: 14, bibleGatewayName: 'Zacarias'),
  BookReading(name: 'Malaquías', startChapter: 1, chapters: 4, bibleGatewayName: 'Malaquias'),
  BookReading(name: 'Mateo', startChapter: 1, chapters: 28, bibleGatewayName: 'Mateo'),
  BookReading(name: 'Marcos', startChapter: 1, chapters: 16, bibleGatewayName: 'Marcos'),
];

class OracionScreen extends ConsumerStatefulWidget {
  const OracionScreen({super.key});

  @override
  ConsumerState<OracionScreen> createState() => _OracionScreenState();
}

class _OracionScreenState extends ConsumerState<OracionScreen> {
  bool _isRead = false;
  bool _isFormOpen = false;
  final _prayerController = TextEditingController();
  bool _isPrivate = true;
  bool _isSubmitting = false;
  bool _submittedSuccess = false;
  List<Map<String, dynamic>> _requests = [];
  bool _loadingRequests = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  @override
  void dispose() {
    _prayerController.dispose();
    super.dispose();
  }

  int _getDayOfYear() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, 1, 1);
    return now.difference(firstDay).inDays + 1;
  }

  Map<String, dynamic> _getReadingForDay(int day) {
    int currentDay = 1;
    for (final book in readingPlanBooks) {
      if (day >= currentDay && day < currentDay + book.chapters) {
        final chapterOffset = day - currentDay;
        return {
          'book': book.name,
          'chapter': book.startChapter + chapterOffset,
          'bibleGatewayName': book.bibleGatewayName,
        };
      }
      currentDay += book.chapters;
    }
    return {'book': 'Ezequiel', 'chapter': 33, 'bibleGatewayName': 'Ezequiel'};
  }

  Future<void> _fetchRequests() async {
    final user = ref.read(authStateProvider).userProfile;
    if (user == null || !user.isPrayerAdmin) {
      if (mounted) setState(() => _loadingRequests = false);
      return;
    }

    setState(() => _loadingRequests = true);
    try {
      final res = await Supabase.instance.client
          .from('prayer_requests')
          .select('id, content, is_private, created_at, user_id, profiles:user_id(first_name, last_name)')
          .order('created_at', ascending: false)
          .limit(30);

      if (mounted) {
        setState(() {
          _requests = List<Map<String, dynamic>>.from(res);
          _loadingRequests = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingRequests = false);
    }
  }

  Future<void> _openZoom() async {
    const url = 'https://us02web.zoom.us/j/89951090415?pwd=ZWpNbHpGVlhZdnhYY0FVL2xjY1ViQT09';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openBible(String bookName, int chapter) async {
    final url = 'https://www.biblegateway.com/passage/?search=$bookName+$chapter&version=RVR1960';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _submitPrayerRequest() async {
    final content = _prayerController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);
    final user = ref.read(authStateProvider).userProfile;

    try {
      await Supabase.instance.client.from('prayer_requests').insert({
        'user_id': user?.id,
        'content': content,
        'is_private': _isPrivate,
      });

      if (user != null && user.email.isNotEmpty) {
        ResendEmailService.sendPrayerRequestConfirmation(
          to: user.email,
          authorName: user.name,
          title: content.length > 50 ? '${content.substring(0, 50)}...' : content,
          category: _isPrivate ? 'Petición Confidencial Pastoral' : 'Muro de Intercesión General',
        );
      }

      if (mounted) {
        setState(() {
          _submittedSuccess = true;
          _prayerController.clear();
          _isPrivate = true;
          _isSubmitting = false;
        });
        _fetchRequests();

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _submittedSuccess = false;
              _isFormOpen = false;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar petición: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatDateClean(String? dateStr) {
    if (dateStr == null) return '';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return '';
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Set', 'Oct', 'Nov', 'Dic'];
    final mName = months[dt.month - 1];
    final hr = dt.hour.toString().padLeft(2, '0');
    final mn = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $mName, $hr:$mn';
  }

  @override
  Widget build(BuildContext context) {
    final dayOfYear = _getDayOfYear();
    final reading = _getReadingForDay(dayOfYear);
    final user = ref.watch(authStateProvider).userProfile;
    final isPrayerAdmin = user?.isPrayerAdmin ?? false;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: _fetchRequests,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Live Banner Zoom
              _buildZoomBanner(),
              const SizedBox(height: 18),

              // 2. Daily Scripture Card
              _buildDailyReadingCard(dayOfYear, reading),
              const SizedBox(height: 18),

              // 3. Prayer Request Box
              _buildPrayerBoxCard(isPrayerAdmin),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZoomBanner() {
    return Container(
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
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LUNES A VIERNES • 06:00 AM',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppColors.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Mañanas de Oración',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Únete a la disciplina de oración diaria de nuestra congregación a través de la sala virtual de Zoom.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _openZoom,
            icon: const Icon(Icons.video_call, color: AppColors.primary, size: 22),
            label: Text(
              'Unirse a la Sala Virtual (Zoom)',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyReadingCard(int dayOfYear, Map<String, dynamic> reading) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PLAN BÍBLICO DIARIO • DÍA $dayOfYear DE 365',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${reading['book']} ${reading['chapter']}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.menu_book_rounded,
                color: AppColors.primaryContainer,
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceContainer),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lectura de hoy: Todo el capítulo',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hoy nos corresponde leer el capítulo completo de ${reading['book']} ${reading['chapter']}. Para facilitar tu lectura, puedes abrirlo en la Biblia online.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _openBible(
              reading['bibleGatewayName'] as String,
              reading['chapter'] as int,
            ),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text(
              'Leer Capítulo Completo (Biblia Online)',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.secondaryContainer.withValues(alpha: 0.4),
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _isRead = !_isRead);
            },
            icon: Icon(
              _isRead ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18,
            ),
            label: Text(
              _isRead ? 'Lectura del Día Completada' : 'Marcar Lectura Completada',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              backgroundColor: _isRead ? AppColors.primaryContainer : Colors.white,
              foregroundColor: _isRead ? Colors.white : AppColors.primaryContainer,
              side: const BorderSide(color: AppColors.primaryContainer),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: _isRead ? 1 : 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerBoxCard(bool isPrayerAdmin) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.mail_outline, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buzón de Oración',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Envía tus peticiones de oración al equipo pastoral.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (!_isFormOpen)
            ElevatedButton.icon(
              onPressed: () => setState(() => _isFormOpen = true),
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                'Enviar Pedido de Oración',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
            )
          else ...[
            Text(
              'COLOQUE SU MOTIVO',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _prayerController,
              maxLines: 4,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Escribe tu motivo de oración aquí...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.secondary.withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tu petición es confidencial y solo será leída por el Equipo Pastoral y de Intercesión.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_submittedSuccess) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Text(
                  '✅ Petición enviada con éxito. Estaremos orando por ti.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF15803D),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isFormOpen = false;
                        _prayerController.clear();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitPrayerRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Enviar'),
                  ),
                ),
              ],
            ),
          ],

          // Lista de Peticiones: Solo para Pastor / Encargado de Oración
          if (isPrayerAdmin) ...[
            const SizedBox(height: 20),
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 12),

            Text(
              'BANDEJA PASTORAL • PETICIONES RECIBIDAS',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),

            if (_loadingRequests)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_requests.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No hay peticiones registradas.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.secondary,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _requests.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final req = _requests[index];
                  final profiles = req['profiles'] as Map<String, dynamic>?;
                  final senderName = profiles != null
                      ? '${profiles['first_name'] ?? ''} ${profiles['last_name'] ?? ''}'.trim()
                      : 'Anónimo';

                  final formattedDate = _formatDateClean(req['created_at']?.toString());

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.surfaceContainer),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.lock_outline,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  senderName,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              formattedDate,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '“${req['content'] ?? ''}”',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.onSurface,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}
