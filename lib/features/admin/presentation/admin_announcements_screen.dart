import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';

const List<String> announcementCategories = [
  'General',
  'Culto Central',
  'Jóvenes Legado',
  'Adolescentes Free',
  'Niños Kids',
  'Mujeres de Fe',
  'Varones Valientes',
  'Matrimonios',
  'Oración',
  'Campaña Especial',
];

double getAnnouncementAspectRatio(String? size) {
  switch (size) {
    case '1080x1440':
    case 'tall':
    case 'vertical':
      return 1080 / 1440; // 0.75 (3:4)
    case '1000x1000':
    case 'square':
      return 1.0; // 1:1
    case '1920x1080':
    case 'normal':
    case 'horizontal':
    default:
      return 1920 / 1080; // 16:9 (~1.777)
  }
}

class AdminAnnouncementsScreen extends ConsumerStatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  ConsumerState<AdminAnnouncementsScreen> createState() => _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends ConsumerState<AdminAnnouncementsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _announcements = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('announcements')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _announcements = List<Map<String, dynamic>>.from(res);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar anuncios: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteAnnouncement(String id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Anuncio'),
        content: Text('¿Estás seguro de eliminar el anuncio "$title"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await Supabase.instance.client
          .from('announcements')
          .delete()
          .eq('id', id)
          .select();
      if ((res as List).isEmpty) {
        throw Exception('No se pudo eliminar el anuncio en el servidor. Verifica tus permisos.');
      }
      setState(() {
        _announcements.removeWhere((a) => a['id'].toString() == id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anuncio eliminado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Widget _buildRawImage(String imageUrl, {BoxFit fit = BoxFit.cover}) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final commaIdx = imageUrl.indexOf(',');
        final base64Str = commaIdx != -1 ? imageUrl.substring(commaIdx + 1) : imageUrl;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: fit,
          errorBuilder: (_, _, _) => const Center(child: Icon(Icons.broken_image, color: AppColors.secondary)),
        );
      } catch (_) {
        return const Center(child: Icon(Icons.broken_image, color: AppColors.secondary));
      }
    }

    return Image.network(
      imageUrl,
      fit: fit,
      errorBuilder: (_, _, _) => const Center(child: Icon(Icons.broken_image, color: AppColors.secondary)),
    );
  }

  Widget _buildImageWidget(String? imageUrl, {String? imageSize}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        height: 130,
        color: AppColors.primary.withValues(alpha: 0.1),
        child: const Center(
          child: Icon(Icons.campaign, color: AppColors.primary, size: 32),
        ),
      );
    }

    final ratio = getAnnouncementAspectRatio(imageSize);

    return Container(
      width: double.infinity,
      color: const Color(0xFF0A192F),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 480),
          child: AspectRatio(
            aspectRatio: ratio,
            child: _buildRawImage(imageUrl, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  void _showFormDialog([Map<String, dynamic>? existing]) {
    final isEditing = existing != null;
    final titleCtrl = TextEditingController(text: existing?['title'] ?? '');
    final dateCtrl = TextEditingController(text: existing?['date_label'] ?? existing?['date'] ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] ?? '');
    final urlCtrl = TextEditingController(text: existing?['image_url'] ?? '');

    String selectedCategory = existing?['category'] ?? 'General';
    String selectedImageSize = existing?['image_size']?.toString() ?? '1920x1080';
    if (selectedImageSize == 'tall') selectedImageSize = '1080x1440';
    if (selectedImageSize == 'normal') selectedImageSize = '1920x1080';
    if (selectedImageSize == 'square') selectedImageSize = '1000x1000';
    bool keepForever = existing?['keep_forever'] == true;
    XFile? pickedImage;
    Uint8List? pickedImageBytes;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Editar Anuncio' : 'Nuevo Anuncio / Novedad',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Título
                    TextField(
                      controller: titleCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Título del Anuncio *',
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Categoría Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: announcementCategories.contains(selectedCategory)
                          ? selectedCategory
                          : announcementCategories.first,
                      decoration: InputDecoration(
                        labelText: 'Categoría *',
                        prefixIcon: const Icon(Icons.category_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      items: announcementCategories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13.5))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Fecha o Horario a Mostrar
                    TextField(
                      controller: dateCtrl,
                      decoration: InputDecoration(
                        labelText: 'Texto de Fecha u Horario',
                        hintText: 'Ej: Domingos 10:00 AM / Próximamente',
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Descripción
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Descripción / Detalles',
                        hintText: 'Información para los miembros...',
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 40),
                          child: Icon(Icons.notes),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Selector de Formato y Proporción del Marco
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.aspect_ratio, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Formato y Proporción del Marco *',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Selecciona las dimensiones del arte para ajustar el marco del anuncio:',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setModalState(() => selectedImageSize = '1920x1080'),
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: selectedImageSize == '1920x1080'
                                        ? AppColors.primary.withValues(alpha: 0.08)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selectedImageSize == '1920x1080'
                                          ? AppColors.primary
                                          : const Color(0xFFE2E8F0),
                                      width: selectedImageSize == '1920x1080' ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.panorama_horizontal_outlined,
                                        size: 20,
                                        color: selectedImageSize == '1920x1080'
                                            ? AppColors.primary
                                            : AppColors.secondary,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '1920x1080',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: selectedImageSize == '1920x1080'
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          color: selectedImageSize == '1920x1080'
                                              ? AppColors.primary
                                              : AppColors.onSurface,
                                        ),
                                      ),
                                      Text(
                                        '16:9 Panorámico',
                                        style: GoogleFonts.inter(
                                          fontSize: 9.5,
                                          color: selectedImageSize == '1920x1080'
                                              ? AppColors.primary
                                              : AppColors.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () => setModalState(() => selectedImageSize = '1080x1440'),
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: selectedImageSize == '1080x1440'
                                        ? AppColors.primary.withValues(alpha: 0.08)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selectedImageSize == '1080x1440'
                                          ? AppColors.primary
                                          : const Color(0xFFE2E8F0),
                                      width: selectedImageSize == '1080x1440' ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.portrait_outlined,
                                        size: 20,
                                        color: selectedImageSize == '1080x1440'
                                            ? AppColors.primary
                                            : AppColors.secondary,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '1080x1440',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: selectedImageSize == '1080x1440'
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          color: selectedImageSize == '1080x1440'
                                              ? AppColors.primary
                                              : AppColors.onSurface,
                                        ),
                                      ),
                                      Text(
                                        '3:4 Vertical',
                                        style: GoogleFonts.inter(
                                          fontSize: 9.5,
                                          color: selectedImageSize == '1080x1440'
                                              ? AppColors.primary
                                              : AppColors.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () => setModalState(() => selectedImageSize = '1000x1000'),
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: selectedImageSize == '1000x1000'
                                        ? AppColors.primary.withValues(alpha: 0.08)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selectedImageSize == '1000x1000'
                                          ? AppColors.primary
                                          : const Color(0xFFE2E8F0),
                                      width: selectedImageSize == '1000x1000' ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.crop_square_outlined,
                                        size: 20,
                                        color: selectedImageSize == '1000x1000'
                                            ? AppColors.primary
                                            : AppColors.secondary,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '1000x1000',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: selectedImageSize == '1000x1000'
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          color: selectedImageSize == '1000x1000'
                                              ? AppColors.primary
                                              : AppColors.onSurface,
                                        ),
                                      ),
                                      Text(
                                        '1:1 Cuadrado',
                                        style: GoogleFonts.inter(
                                          fontSize: 9.5,
                                          color: selectedImageSize == '1000x1000'
                                              ? AppColors.primary
                                              : AppColors.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Selector de Imagen de Banner y Previsualización del Marco
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Vista del Marco ($selectedImageSize)',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  final picker = ImagePicker();
                                  final picked = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    maxWidth: 2048,
                                    maxHeight: 2048,
                                    imageQuality: 90,
                                  );
                                  if (picked != null) {
                                    final bytes = await picked.readAsBytes();
                                    setModalState(() {
                                      pickedImage = picked;
                                      pickedImageBytes = bytes;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.photo_library_outlined, size: 16),
                                label: const Text('Elegir Foto', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 220, maxWidth: 360),
                              child: AspectRatio(
                                aspectRatio: getAnnouncementAspectRatio(selectedImageSize),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0A192F),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                    ),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        if (pickedImageBytes != null)
                                          Image.memory(
                                            pickedImageBytes!,
                                            fit: BoxFit.cover,
                                            filterQuality: FilterQuality.high,
                                          )
                                        else if (urlCtrl.text.trim().isNotEmpty)
                                          _buildRawImage(urlCtrl.text.trim(), fit: BoxFit.cover)
                                        else
                                          Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  selectedImageSize == '1080x1440'
                                                      ? Icons.portrait
                                                      : selectedImageSize == '1000x1000'
                                                          ? Icons.crop_square
                                                          : Icons.panorama,
                                                  size: 34,
                                                  color: Colors.white30,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'Marco: $selectedImageSize',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: Colors.white70,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'El arte se ajustará a esta proporción',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    color: Colors.white38,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.65),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              selectedImageSize,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: urlCtrl,
                            onChanged: (_) => setModalState(() {}),
                            decoration: InputDecoration(
                              hintText: 'O pega la URL de una imagen en web...',
                              hintStyle: const TextStyle(fontSize: 12),
                              isDense: true,
                              prefixIcon: const Icon(Icons.link, size: 18),
                              suffixIcon: urlCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        urlCtrl.clear();
                                        setModalState(() {});
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Switch Mantener siempre visible
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Mantener siempre visible',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        keepForever
                            ? 'El anuncio no expirará automáticamente'
                            : 'Expirará automáticamente tras 7 días',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.secondary),
                      ),
                      value: keepForever,
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) => setModalState(() => keepForever = val),
                    ),
                    const SizedBox(height: 20),

                    // Botón Guardar
                    ElevatedButton(
                      onPressed: isUploading
                          ? null
                          : () async {
                              final title = titleCtrl.text.trim();
                              if (title.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Ingresa un título para el anuncio')),
                                );
                                return;
                              }

                              setModalState(() => isUploading = true);

                              try {
                                String finalImageUrl = urlCtrl.text.trim();

                                // If picked a local file, convert directly to Base64 data URL (Web/Mobile fully compatible)
                                if (pickedImageBytes != null && pickedImage != null) {
                                  final ext = pickedImage!.name.split('.').last.toLowerCase();
                                  final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
                                  final base64String = base64Encode(pickedImageBytes!);
                                  finalImageUrl = 'data:$mimeType;base64,$base64String';
                                }

                                final now = DateTime.now();
                                final expiresAt = keepForever
                                    ? null
                                    : now.add(const Duration(days: 7)).toIso8601String();

                                final payload = {
                                  'title': title,
                                  'category': selectedCategory,
                                  'date_label': dateCtrl.text.trim().isNotEmpty ? dateCtrl.text.trim() : 'Próximamente',
                                  'description': descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : title,
                                  'image_url': finalImageUrl.isNotEmpty ? finalImageUrl : null,
                                  'image_size': selectedImageSize,
                                  'keep_forever': keepForever,
                                  'expires_at': expiresAt,
                                };

                                final client = Supabase.instance.client;
                                if (isEditing) {
                                  await client
                                      .from('announcements')
                                      .update(payload)
                                      .eq('id', existing['id']);
                                } else {
                                  await client.from('announcements').insert(payload);
                                }

                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                                _fetchAnnouncements();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isEditing ? 'Anuncio actualizado con éxito' : 'Anuncio publicado con éxito',
                                      ),
                                      backgroundColor: const Color(0xFF059669),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isUploading = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error al guardar anuncio: $e'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isUploading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              isEditing ? 'Guardar Cambios' : 'Publicar Anuncio',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _searchQuery.isEmpty
        ? _announcements
        : _announcements.where((a) {
            final t = (a['title'] ?? '').toString().toLowerCase();
            final c = (a['category'] ?? '').toString().toLowerCase();
            final q = _searchQuery.toLowerCase();
            return t.contains(q) || c.contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestión de Anuncios',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Novedades y Avisos de la Iglesia',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Nuevo Anuncio',
            onPressed: () => _showFormDialog(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAnnouncements,
        color: AppColors.primary,
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surfaceContainerLowest,
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Buscar por título o categoría...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            ),

            const Divider(height: 1),

            // List of announcements
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.campaign_outlined, size: 48, color: AppColors.secondary),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isEmpty ? 'No hay anuncios registrados' : 'No se encontraron resultados',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _showFormDialog(),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Crear Primer Anuncio'),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final ann = filtered[index];
                            final id = ann['id'].toString();
                            final title = ann['title']?.toString() ?? 'Sin título';
                            final category = ann['category']?.toString() ?? 'General';
                            final dateLabel = ann['date_label']?.toString() ?? 'Próximamente';
                            final imageUrl = ann['image_url']?.toString();
                            final imageSize = ann['image_size']?.toString();
                            final keepForever = ann['keep_forever'] == true;

                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildImageWidget(imageUrl, imageSize: imageSize),
                                  Padding(
                                    padding: const EdgeInsets.all(14),
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
                                                category.toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Icon(
                                                  keepForever ? Icons.all_inclusive : Icons.timer_outlined,
                                                  size: 13,
                                                  color: AppColors.secondary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  keepForever ? 'Permanente' : dateLabel,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.secondary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          title,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        if (ann['description'] != null &&
                                            ann['description'].toString().isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            ann['description'].toString(),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: AppColors.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              onPressed: () => _showFormDialog(ann),
                                              icon: const Icon(Icons.edit_outlined, size: 16),
                                              label: const Text('Editar', style: TextStyle(fontSize: 12)),
                                            ),
                                            const SizedBox(width: 8),
                                            TextButton.icon(
                                              onPressed: () => _deleteAnnouncement(id, title),
                                              icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                                              label: const Text(
                                                'Eliminar',
                                                style: TextStyle(fontSize: 12, color: AppColors.error),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Anuncio'),
      ),
    );
  }
}
