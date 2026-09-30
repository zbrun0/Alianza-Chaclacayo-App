import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_provider.dart';
import '../../admin/presentation/admin_announcements_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final Function(dynamic)? onTabChange;

  const HomeScreen({super.key, this.onTabChange});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Map<String, dynamic>> _announcements = [];
  bool _loading = true;
  String _youtubeUrl = 'https://www.youtube.com/watch?v=48D6zayWSDg';
  String _youtubeTitle = 'DOM 27/09 | UNA RELACIÓN QUE FORTALECE EL CRECIMIENTO ESPIRITUAL | Ef. 1:15-23 pr. Gary Ortiz';
  String _youtubeThumbnail = 'https://i.ytimg.com/vi/48D6zayWSDg/hqdefault.jpg';
  String _youtubePublished = '';
  RealtimeChannel? _announcementsChannel;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _initRealtime();
  }

  void _initRealtime() {
    try {
      final client = ref.read(supabaseClientProvider);
      _announcementsChannel = client
          .channel('public:announcements_home')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'announcements',
            callback: (_) {
              if (mounted) {
                _fetchAnnouncementsOnly();
              }
            },
          )
          .subscribe();
    } catch (_) {}
  }

  Future<void> _fetchAnnouncementsOnly() async {
    try {
      final client = ref.read(supabaseClientProvider);
      final res = await client
          .from('announcements')
          .select()
          .order('created_at', ascending: false)
          .limit(10);
      if (mounted) {
        setState(() {
          _announcements = List<Map<String, dynamic>>.from(res);
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _announcementsChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final client = ref.read(supabaseClientProvider);
    try {
      final res = await client
          .from('announcements')
          .select()
          .order('created_at', ascending: false)
          .limit(10);

      // 1. Fetch saved church settings from Supabase
      try {
        final settingsRes = await client.from('church_settings').select();
        final settingsMap = {for (var item in (settingsRes as List)) item['key']: item['value']};
        if (mounted) {
          setState(() {
            if (settingsMap['youtube_live_url'] != null && (settingsMap['youtube_live_url'] as String).isNotEmpty) {
              _youtubeUrl = settingsMap['youtube_live_url'];
            }
            if (settingsMap['youtube_live_title'] != null && (settingsMap['youtube_live_title'] as String).isNotEmpty) {
              _youtubeTitle = settingsMap['youtube_live_title'];
            }
            if (settingsMap['youtube_live_thumbnail'] != null && (settingsMap['youtube_live_thumbnail'] as String).isNotEmpty) {
              _youtubeThumbnail = settingsMap['youtube_live_thumbnail'];
            }
            if (settingsMap['youtube_live_published_at'] != null) {
              _youtubePublished = settingsMap['youtube_live_published_at'];
            }
          });
        }
      } catch (_) {}

      // 2. Fetch live latest video from YouTube Channel RSS Feed via HTTP
      Future.microtask(() async {
        try {
          final feedUrl = Uri.parse(
            'https://api.allorigins.win/raw?url=https://www.youtube.com/feeds/videos.xml?channel_id=UCQqeXqwPVgGuNsnxaTKVj1Q',
          );
          final response = await http.get(feedUrl).timeout(const Duration(seconds: 8));
          if (response.statusCode == 200 && response.body.contains('<entry>')) {
            final body = response.body;
            final entryStart = body.indexOf('<entry>');
            final entryEnd = body.indexOf('</entry>', entryStart);
            if (entryStart != -1 && entryEnd != -1) {
              final entry = body.substring(entryStart, entryEnd);

              // Extract Video ID
              final videoIdMatch = RegExp(r'<yt:videoId>(.*?)</yt:videoId>').firstMatch(entry);
              final titleMatch = RegExp(r'<title>(.*?)</title>').firstMatch(entry);
              final thumbMatch = RegExp(r'<media:thumbnail url="(.*?)"').firstMatch(entry);
              final publishedMatch = RegExp(r'<published>(.*?)</published>').firstMatch(entry);

              final videoId = videoIdMatch?.group(1);
              final rawTitle = titleMatch?.group(1);
              final rawThumb = thumbMatch?.group(1);
              final rawPub = publishedMatch?.group(1);

              if (videoId != null && mounted) {
                final newUrl = 'https://www.youtube.com/watch?v=$videoId';
                final newTitle = rawTitle != null
                    ? rawTitle.replaceAll('&amp;', '&').replaceAll('&quot;', '"').replaceAll('&#39;', "'")
                    : _youtubeTitle;
                final newThumb = (rawThumb != null && rawThumb.isNotEmpty)
                    ? rawThumb
                    : 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';

                setState(() {
                  _youtubeUrl = newUrl;
                  _youtubeTitle = newTitle;
                  _youtubeThumbnail = newThumb;
                  if (rawPub != null) _youtubePublished = rawPub;
                });

                // Update church_settings in database
                try {
                  await client.from('church_settings').upsert([
                    {'key': 'youtube_live_url', 'value': newUrl, 'updated_at': DateTime.now().toIso8601String()},
                    {'key': 'youtube_live_title', 'value': newTitle, 'updated_at': DateTime.now().toIso8601String()},
                    {'key': 'youtube_live_thumbnail', 'value': newThumb, 'updated_at': DateTime.now().toIso8601String()},
                    if (rawPub != null) {'key': 'youtube_live_published_at', 'value': rawPub, 'updated_at': DateTime.now().toIso8601String()},
                  ]);
                } catch (_) {}
              }
            }
          }
        } catch (_) {}
      });

      if (mounted) {
        setState(() {
          _announcements = List<Map<String, dynamic>>.from(res);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openYouTube() async {
    final uri = Uri.parse(_youtubeUrl.contains('youtube.com') ? _youtubeUrl : 'https://www.youtube.com/@alianzadechaclacayo/live');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.userProfile;
    final hasRealEmail = user != null &&
        user.email.isNotEmpty &&
        !user.email.contains('@temp.') &&
        !user.email.contains('@alianzachaclacayo.pe');

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner recordatorio de vincular correo electrónico si aún no tiene
            if (user != null && !hasRealEmail) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined, color: Color(0xFFB45309), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vincula tu correo electrónico',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Agrégalo desde tu perfil para recuperar tu contraseña y recibir comunicados.',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        widget.onTabChange?.call(4);
                      },
                      child: const Text('Vincular', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],

            // Novedades & Anuncios Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'NOVEDADES & ANUNCIOS',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${_announcements.length} avisos',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.secondary,
                      ),
                    ),
                    if (user != null && user.hasAdminAccess) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminAnnouncementsScreen()),
                          );
                          _fetchData();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.edit_note, size: 14, color: AppColors.primary),
                              SizedBox(width: 3),
                              Text(
                                'Gestionar',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Carrusel de Anuncios Horizontal
            _buildAnnouncementsCarousel(),

            const SizedBox(height: 24),

            // YouTube Live Stream Card (Último Culto)
            _buildLiveStreamCard(),

            const SizedBox(height: 20),

            // Banner para Instalar Aplicación (Android / iOS PWA / Web)
            _buildInstallAppBanner(),

            const SizedBox(height: 24),

            // Accesos Rápidos Header
            Text(
              'ACCESOS RÁPIDOS',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            // Quick Access Grid
            _buildQuickAccessGrid(user),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStreamCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 540;

        if (isWide) {
          // Horizontal Compact Card for Web / Tablet / Desktop
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryContainer.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Miniatura con ancho fijo y proporción 16:9 perfecta
                GestureDetector(
                  onTap: _openYouTube,
                  child: SizedBox(
                    width: 210,
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: _youtubeThumbnail.isNotEmpty
                                ? Image.network(
                                    _youtubeThumbnail,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: AppColors.primaryContainer,
                                      child: const Icon(Icons.church_rounded, color: Colors.white54, size: 36),
                                    ),
                                  )
                                : Container(color: AppColors.primaryContainer),
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626).withValues(alpha: 0.92),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Contenido Informativo y Botón
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDC2626),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ÚLTIMO CULTO / EN VIVO',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _youtubeTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                          height: 1.25,
                        ),
                      ),
                      if (_youtubePublished.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Publicado: ${_youtubePublished.split('T').first}',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary),
                        ),
                      ],
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _openYouTube,
                        icon: const Icon(Icons.open_in_new, size: 14),
                        label: const Text('Ver Transmisión en YouTube', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile Compact Card (Evita que la imagen sea gigante en pantallas móviles)
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryContainer.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDC2626),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'ÚLTIMO CULTO / EN VIVO',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_circle, color: Colors.white, size: 11),
                        const SizedBox(width: 4),
                        Text(
                          'YouTube',
                          style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _openYouTube,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: _youtubeThumbnail.isNotEmpty
                                ? Image.network(
                                    _youtubeThumbnail,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: AppColors.primaryContainer,
                                      child: const Center(
                                        child: Icon(Icons.church_rounded, color: Colors.white54, size: 40),
                                      ),
                                    ),
                                  )
                                : Container(color: AppColors.primaryContainer),
                          ),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626).withValues(alpha: 0.92),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _youtubeTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                  height: 1.25,
                ),
              ),
              if (_youtubePublished.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  'Publicado: ${_youtubePublished.split('T').first}',
                  style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.secondary),
                ),
              ],
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _openYouTube,
                icon: const Icon(Icons.open_in_new, size: 15),
                label: const Text('Ver Transmisión en YouTube', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnnouncementsCarousel() {
    if (_loading) {
      return SizedBox(
        height: 220,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 2,
          separatorBuilder: (context, index) => const SizedBox(width: 14),
          itemBuilder: (context, index) => Container(
            width: 280,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      );
    }

    if (_announcements.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'No hay anuncios publicados en este momento.',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.secondary,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _announcements.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final ann = _announcements[index];
          final title = ann['title'] ?? 'Anuncio';
          final category = ann['category'] ?? 'General';
          final description = ann['description'] ?? '';
          final dateLabel = ann['date_label'] ?? '';
          final imageUrl = ann['image_url'];
          final imageSize = ann['image_size']?.toString();
          final isVertical = (imageSize == '1080x1440' || imageSize == 'tall' || imageSize == 'vertical');

          // Vertical announcement card (1080x1440): Complete vertical poster without letterboxing or blurred filler
          if (isVertical && imageUrl != null && imageUrl.toString().isNotEmpty) {
            return InkWell(
              onTap: () => _showAnnouncementDetailDialog(ann),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 215,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A192F),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryContainer.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildAnnouncementImage(imageUrl.toString(), fit: BoxFit.cover),
                      // Elegant gradient overlay at bottom for text readability
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.85),
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      category,
                                      style: GoogleFonts.inter(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  if (dateLabel.isNotEmpty)
                                    Text(
                                      dateLabel,
                                      style: GoogleFonts.inter(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white70,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (description.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  description,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.fullscreen, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Horizontal announcement card (1920x1080 / default)
          return InkWell(
            onTap: () => _showAnnouncementDetailDialog(ann),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 290,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryContainer.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Container(
                      height: 145,
                      width: double.infinity,
                      color: const Color(0xFF0A192F),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildAnnouncementImage(imageUrl?.toString(), fit: BoxFit.cover),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.fullscreen, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                category,
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            if (dateLabel.isNotEmpty)
                              Text(
                                dateLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          description,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAnnouncementDetailDialog(Map<String, dynamic> ann) {
    final title = ann['title'] ?? 'Anuncio';
    final category = ann['category'] ?? 'General';
    final description = ann['description'] ?? '';
    final dateLabel = ann['date_label'] ?? '';
    final imageUrl = ann['image_url']?.toString();
    final imageSize = ann['image_size']?.toString();
    final ratio = getAnnouncementAspectRatio(imageSize);

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 550, maxHeight: 700),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with Close
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageUrl != null && imageUrl.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              color: const Color(0xFF0A192F),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 460),
                                child: AspectRatio(
                                  aspectRatio: ratio,
                                  child: InteractiveViewer(
                                    maxScale: 3.5,
                                    child: _buildAnnouncementFullImage(imageUrl),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        if (dateLabel.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.event, size: 16, color: Color(0xFFC5875A)),
                              const SizedBox(width: 6),
                              Text(
                                dateLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFC5875A),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Text(
                            description,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              color: AppColors.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnnouncementFullImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final commaIdx = imageUrl.indexOf(',');
        final base64Str = commaIdx != -1 ? imageUrl.substring(commaIdx + 1) : imageUrl;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, _, _) => _buildPlaceholderImage(),
        );
      } catch (_) {
        return _buildPlaceholderImage();
      }
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
    );
  }

  Widget _buildAnnouncementImage(String? imageUrl, {BoxFit fit = BoxFit.cover}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildPlaceholderImage();
    }

    if (imageUrl.startsWith('data:image')) {
      try {
        final commaIdx = imageUrl.indexOf(',');
        final base64Str = commaIdx != -1 ? imageUrl.substring(commaIdx + 1) : imageUrl;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: fit,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, _, _) => _buildPlaceholderImage(),
        );
      } catch (_) {
        return _buildPlaceholderImage();
      }
    }

    return Image.network(
      imageUrl,
      fit: fit,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppColors.primaryContainer,
      child: Center(
        child: Image.asset(
          'assets/images/11.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.campaign, color: Colors.white30, size: 36),
        ),
      ),
    );
  }

  Widget _buildQuickAccessGrid(dynamic user) {
    final hasAdminAccess = user?.hasAdminAccess ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final crossAxisCount = isWide ? 4 : 2;
        final childAspectRatio = isWide ? 1.45 : 1.35;

        final cards = hasAdminAccess
            ? [
                _buildAccessCard(
                  icon: Icons.volunteer_activism,
                  iconColor: const Color(0xFF1E40AF),
                  iconBgColor: const Color(0xFFDBEAFE),
                  title: 'Diezmos & Ofrendas',
                  subtitle: 'Vouchers y Cuentas',
                  onTap: () => widget.onTabChange?.call('diezmos'),
                ),
                _buildAccessCard(
                  icon: Icons.school,
                  iconColor: const Color(0xFF5B21B6),
                  iconBgColor: const Color(0xFFEDE9FE),
                  title: 'Academia ABC',
                  subtitle: 'Cursos e Inscripciones',
                  onTap: () => widget.onTabChange?.call('abc'),
                ),
                if (user?.isAdmin == true)
                  _buildAccessCard(
                    icon: Icons.groups,
                    iconColor: const Color(0xFF047857),
                    iconBgColor: const Color(0xFFD1FAE5),
                    title: 'Redes & Células',
                    subtitle: 'Directorio y Reporte',
                    onTap: () => widget.onTabChange?.call('redes'),
                  ),
                _buildAccessCard(
                  icon: Icons.wb_twilight,
                  iconColor: const Color(0xFF92400E),
                  iconBgColor: const Color(0xFFFEF3C7),
                  title: 'Mañanas de Oración',
                  subtitle: 'Zoom & Devocional',
                  onTap: () => widget.onTabChange?.call('oracion'),
                ),
              ]
            : [
                _buildAccessCard(
                  icon: Icons.school,
                  iconColor: const Color(0xFF5B21B6),
                  iconBgColor: const Color(0xFFEDE9FE),
                  title: 'Academia ABC',
                  subtitle: 'Cursos e Inscripciones',
                  onTap: () => widget.onTabChange?.call('abc'),
                ),
                _buildAccessCard(
                  icon: Icons.wb_twilight,
                  iconColor: const Color(0xFF92400E),
                  iconBgColor: const Color(0xFFFEF3C7),
                  title: 'Mañanas de Oración',
                  subtitle: 'Zoom & Devocional',
                  onTap: () => widget.onTabChange?.call('oracion'),
                ),
                _buildAccessCard(
                  icon: Icons.play_circle_fill,
                  iconColor: const Color(0xFFDC2626),
                  iconBgColor: const Color(0xFFFEE2E2),
                  title: 'Cultos en Vivo',
                  subtitle: 'Canal de YouTube',
                  onTap: _openYouTube,
                ),
                _buildAccessCard(
                  icon: Icons.badge_outlined,
                  iconColor: const Color(0xFF0369A1),
                  iconBgColor: const Color(0xFFE0F2FE),
                  title: 'Carnet Digital',
                  subtitle: 'Mi Perfil de Miembro',
                  onTap: () => widget.onTabChange?.call('perfil'),
                ),
              ];

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
          children: cards,
        );
      },
    );
  }

  Widget _buildAccessCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryContainer.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallAppBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00173B), Color(0xFF0C387A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00173B).withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: const Center(
              child: Icon(Icons.install_mobile_rounded, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instalar la Aplicación',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Android, iPhone (PWA) o PC',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showInstallModal(context),
            icon: const Icon(Icons.download_rounded, size: 16),
            label: Text(
              'Instalar',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFBBF24),
              foregroundColor: const Color(0xFF0F172A),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInstallModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return DefaultTabController(
          length: 3,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(modalContext).size.height * 0.82,
              maxWidth: 520,
            ),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modal Handle
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.get_app_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Instalar Alianza Chaclacayo',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'Guía rápida de instalación paso a paso',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.secondary),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Tab Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.onSurfaceVariant,
                    labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                    unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
                    tabs: const [
                      Tab(icon: Icon(Icons.android_rounded, size: 18), text: 'Android'),
                      Tab(icon: Icon(Icons.apple_rounded, size: 18), text: 'iPhone / iOS'),
                      Tab(icon: Icon(Icons.computer_rounded, size: 18), text: 'PC / Web'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Tab Views
                Flexible(
                  child: TabBarView(
                    children: [
                      _buildAndroidInstallTab(),
                      _buildInstallStepList([
                        'Abre esta página en el navegador Safari desde tu iPhone o iPad.',
                        'Toca el botón Compartir (icono cuadrado con flecha hacia arriba ⎋ / 📤) en la barra inferior.',
                        'Desliza hacia abajo y presiona "Agregar al inicio" (Add to Home Screen ➕).',
                        'Toca "Agregar" en la esquina superior derecha y listo.',
                      ], Icons.apple_rounded, const Color(0xFF64748B)),
                      _buildInstallStepList([
                        'Abre la web en Google Chrome, Edge o Brave en tu laptop o PC.',
                        'En la barra de direcciones (al lado de favoritos), haz clic en el icono de Instalar (💻 / ⊕).',
                        'Haz clic en "Instalar" para tener la aplicación en tu escritorio.',
                      ], Icons.computer_rounded, const Color(0xFF3B82F6)),
                    ],
                  ),
                ),

                // Copy URL Footer
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: 'https://alianza-chaclacayo.web.app'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '¡Enlace copiado al portapapeles! Compartelo o ábrelo en tu navegador.',
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: Text(
                      'Copiar enlace de la App (alianza-chaclacayo.web.app)',
                      style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.outlineVariant),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAndroidInstallTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shrinkWrap: true,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.android_rounded, color: Color(0xFF15803D), size: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Instalador APK para Android',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF14532D),
                          ),
                        ),
                        Text(
                          'Descarga e instala la app directamente',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: const Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        const downloadUrl = 'https://nnsqxguuefqixscmrrwd.supabase.co/storage/v1/object/public/app-downloads/alianza-chaclacayo.apk?download=alianza-chaclacayo.apk';
                        final uri = Uri.parse(downloadUrl);
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: Text(
                        'Descargar APK Oficial (38 MB)',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(
                          text: 'https://nnsqxguuefqixscmrrwd.supabase.co/storage/v1/object/public/app-downloads/alianza-chaclacayo.apk?download=alianza-chaclacayo.apk',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('¡Enlace directo del APK copiado al portapapeles!'),
                            backgroundColor: Color(0xFF16A34A),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.link_rounded, size: 14, color: Color(0xFF15803D)),
                      label: Text(
                        'Copiar enlace directo de descarga APK',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'O agrega como acceso rápido Web / PWA',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 10),
        for (final item in [
          'Abre esta página en Google Chrome desde tu celular Android.',
          'Toca el menú de los 3 puntos (⋮) en la esquina superior derecha.',
          'Selecciona "Instalar aplicación" o "Agregar a pantalla principal".',
          '¡Listo! Tendrás el acceso directo con el icono oficial de la iglesia.',
        ].asMap().entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${item.key + 1}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.value,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.onSurface,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInstallStepList(List<String> steps, IconData icon, Color color) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shrinkWrap: true,
      children: [
        for (int i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    steps[i],
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.onSurface,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
