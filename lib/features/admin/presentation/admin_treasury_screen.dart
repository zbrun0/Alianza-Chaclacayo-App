import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

class AdminTreasuryScreen extends ConsumerStatefulWidget {
  const AdminTreasuryScreen({super.key});

  @override
  ConsumerState<AdminTreasuryScreen> createState() => _AdminTreasuryScreenState();
}

class _AdminTreasuryScreenState extends ConsumerState<AdminTreasuryScreen> {
  List<Map<String, dynamic>> _receipts = [];
  bool _loading = true;
  String _searchTerm = '';
  String _statusFilter = 'all'; // 'all', 'pendiente', 'verificado'
  String _selectedMonth = 'Todos';

  static const List<Map<String, String>> fundLabels = [
    {'id': 'diezmo', 'label': 'Diezmo'},
    {'id': 'misionera', 'label': 'Ofrenda Misionera'},
    {'id': 'protemplo', 'label': 'Ofrenda Pro-Templo'},
    {'id': 'amor', 'label': 'Ofrenda de Amor'},
    {'id': 'otro', 'label': 'Otro aporte especial'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchReceipts();
  }

  Future<void> _fetchReceipts() async {
    setState(() => _loading = true);
    final client = Supabase.instance.client;

    try {
      final res = await client
          .from('tithing_receipts')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _receipts = List<Map<String, dynamic>>.from(res);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error al cargar tesorería: $e')),
        );
      }
    }
  }

  Future<void> _toggleReceiptStatus(String receiptId, String currentStatus) async {
    final newStatus = currentStatus == 'verificado' ? 'pendiente' : 'verificado';
    final client = Supabase.instance.client;

    try {
      await client
          .from('tithing_receipts')
          .update({'status': newStatus})
          .eq('id', receiptId);

      setState(() {
        final idx = _receipts.indexWhere((r) => r['id'] == receiptId);
        if (idx != -1) {
          _receipts[idx]['status'] = newStatus;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: newStatus == 'verificado' ? const Color(0xFF16A34A) : const Color(0xFFD97706),
            content: Text(newStatus == 'verificado' ? '¡Comprobante marcado como Verificado!' : 'Comprobante marcado como Pendiente.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error al actualizar: $e')),
        );
      }
    }
  }

  void _viewReceiptImage(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: Colors.black,
                child: InteractiveViewer(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      padding: const EdgeInsets.all(32),
                      color: Colors.white,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.broken_image, color: AppColors.error, size: 48),
                          const SizedBox(height: 12),
                          const Text('No se pudo cargar la imagen del voucher'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                            child: const Text('Abrir en navegador'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _receipts.where((r) => r['status'] == 'pendiente').length;
    final verifiedCount = _receipts.where((r) => r['status'] == 'verificado').length;

    final uniqueMonths = {'Todos', ..._receipts.map((r) => r['period_month']?.toString() ?? '').where((m) => m.isNotEmpty)}.toList();

    final filtered = _receipts.where((r) {
      final name = (r['full_name'] ?? '').toString().toLowerCase();
      final dni = (r['dni'] ?? '').toString();
      final matchSearch = name.contains(_searchTerm.toLowerCase()) || dni.contains(_searchTerm);
      if (!matchSearch) return false;

      if (_statusFilter == 'pendiente' && r['status'] != 'pendiente') return false;
      if (_statusFilter == 'verificado' && r['status'] != 'verificado') return false;

      if (_selectedMonth != 'Todos' && r['period_month'] != _selectedMonth) return false;

      return true;
    }).toList();

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
          'Tesorería Reservada',
          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Recargar',
            onPressed: _loading ? null : _fetchReceipts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter & Search Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar por donante o DNI...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onChanged: (val) => setState(() => _searchTerm = val),
                ),
                const SizedBox(height: 12),

                // Status Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'Todos (${_receipts.length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip('pendiente', 'Pendientes ($pendingCount)', isAlert: pendingCount > 0),
                      const SizedBox(width: 8),
                      _buildFilterChip('verificado', 'Verificados ($verifiedCount)'),
                      if (uniqueMonths.length > 1) ...[
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: _selectedMonth,
                          underline: const SizedBox(),
                          items: uniqueMonths.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)))).toList(),
                          onChanged: (val) => setState(() => _selectedMonth = val ?? 'Todos'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Receipts List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No hay comprobantes de diezmos para mostrar.',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.secondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final isVerified = item['status'] == 'verificado';
                          final name = item['full_name'] ?? 'Donante';
                          final dni = item['dni'] ?? 'S/DNI';
                          final phone = item['phone'] ?? '';
                          final month = item['period_month'] ?? 'Mes actual';
                          final funds = item['funds'] is List ? List<String>.from(item['funds']) : <String>[];
                          final fileUrls = item['file_urls'] is List ? List<String>.from(item['file_urls']) : <String>[];
                          final notes = item['notes'] ?? '';

                          // Parse amount from notes if present
                          String parsedAmount = 'S/. 0.00';
                          if (notes.isNotEmpty) {
                            final match = RegExp(r'\[Monto:\s*S\/\.\s*([0-9.,]+)', caseSensitive: false).firstMatch(notes);
                            if (match != null && match.group(1) != null) {
                              parsedAmount = 'S/. ${match.group(1)}';
                            }
                          }

                          final fundNames = funds.map((f) {
                            final found = fundLabels.firstWhere((fl) => fl['id'] == f, orElse: () => {'label': f});
                            return found['label']!;
                          }).join(', ');

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: !isVerified ? const Color(0xFFFBBF24) : const Color(0xFFE2E8F0),
                                width: !isVerified ? 1.5 : 1.0,
                              ),
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
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isVerified
                                            ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                                            : const Color(0xFFD97706).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isVerified ? 'VERIFICADO' : 'PENDIENTE',
                                        style: GoogleFonts.inter(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: isVerified ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                Text('DNI: $dni • Tel: ${phone.isNotEmpty ? phone : "No registrado"} • Periodo: $month', style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.secondary)),
                                const SizedBox(height: 4),

                                Text('Concepto: ${fundNames.isNotEmpty ? fundNames : "Aporte general"}', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primary)),

                                if (parsedAmount != 'S/. 0.00') ...[
                                  const SizedBox(height: 4),
                                  Text('Monto Declarado: $parsedAmount', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF047857))),
                                ],

                                if (notes.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('Nota: $notes', style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.onSurfaceVariant)),
                                  ),
                                ],

                                const SizedBox(height: 12),

                                // Actions Bar: View Voucher & Toggle Verify
                                Row(
                                  children: [
                                    if (fileUrls.isNotEmpty)
                                      ElevatedButton.icon(
                                        onPressed: () => _viewReceiptImage(fileUrls.first),
                                        icon: const Icon(Icons.receipt_long, size: 16),
                                        label: const Text('Ver Voucher'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryContainer,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                      ),
                                    const Spacer(),
                                    ElevatedButton.icon(
                                      onPressed: () => _toggleReceiptStatus(item['id'], item['status'] ?? 'pendiente'),
                                      icon: Icon(isVerified ? Icons.undo : Icons.check_circle, size: 16),
                                      label: Text(isVerified ? 'Desmarcar' : 'Verificar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isVerified ? AppColors.secondary : const Color(0xFF16A34A),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label, {bool isAlert = false}) {
    final isSelected = _statusFilter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _statusFilter = filterKey);
      },
      selectedColor: isAlert ? const Color(0xFFFEF3C7) : AppColors.primary,
      backgroundColor: isAlert ? const Color(0xFFFEF3C7).withValues(alpha: 0.5) : AppColors.surfaceContainerLow,
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected
            ? (isAlert ? const Color(0xFF92400E) : Colors.white)
            : (isAlert ? const Color(0xFF92400E) : AppColors.secondary),
      ),
    );
  }
}
