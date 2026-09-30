import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CertificateGenerator {
  static Future<Uint8List> generatePdfBytes({
    required String studentName,
    required String courseTitle,
    String? subjectCode,
    dynamic grade,
    String? cycleCode,
  }) async {
    final pdf = pw.Document();

    final dateFormatted = DateFormat("d 'de' MMMM 'de' yyyy", 'es_PE').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('00173B'),
              borderRadius: pw.BorderRadius.circular(16),
              border: pw.Border.all(
                color: PdfColor.fromHex('DAE2FB'),
                width: 3,
              ),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 28),
            child: pw.Stack(
              children: [
                // Inner decorative border
                pw.Positioned.fill(
                  child: pw.Container(
                    margin: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColor.fromHex('475569'),
                        width: 1,
                      ),
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                  ),
                ),

                pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Header
                    pw.Column(
                      children: [
                        pw.Text(
                          'IGLESIA ALIANZA CRISTIANA Y MISIONERA DE CHACLACAYO',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'ACADEMIA BÍBLICA CRISTIANA (ABC)',
                          style: pw.TextStyle(
                            color: PdfColor.fromHex('DAE2FB'),
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 2,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 12),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('032B69'),
                            borderRadius: pw.BorderRadius.circular(8),
                            border: pw.Border.all(color: PdfColor.fromHex('DAE2FB'), width: 1),
                          ),
                          child: pw.Text(
                            'CERTIFICADO DE APROBACIÓN ACADÉMICA',
                            style: pw.TextStyle(
                              color: PdfColor.fromHex('DAE2FB'),
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Body
                    pw.Column(
                      children: [
                        pw.Text(
                          'Otorgado con honor y reconocimiento a:',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 12,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          studentName.toUpperCase(),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.Container(
                          margin: const pw.EdgeInsets.only(top: 4, bottom: 10),
                          width: 260,
                          height: 1.5,
                          color: PdfColor.fromHex('DAE2FB'),
                        ),
                        pw.Text(
                          'Por haber culminado y aprobado satisfactoriamente la materia curricular:',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 11,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          '"${courseTitle.toUpperCase()}"${subjectCode != null ? ' ($subjectCode)' : ''}',
                          style: pw.TextStyle(
                            color: PdfColor.fromHex('DAE2FB'),
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        if (grade != null) ...[
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Calificación Final Obtenida: $grade / 20',
                            style: pw.TextStyle(
                              color: PdfColor.fromHex('86EFAC'),
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Footer with signatures and date
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 30),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Container(
                                width: 140,
                                height: 1,
                                color: PdfColors.white,
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                'Pastor Principal',
                                style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
                              ),
                              pw.Text(
                                'IACyM Chaclacayo',
                                style: pw.TextStyle(color: PdfColor.fromHex('94A3B8'), fontSize: 8),
                              ),
                            ],
                          ),
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                              'Chaclacayo, $dateFormatted',
                              style: const pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 10,
                              ),
                            ),
                            if (cycleCode != null && cycleCode.isNotEmpty)
                              pw.Text(
                                'Ciclo Académico: $cycleCode',
                                style: pw.TextStyle(
                                  color: PdfColor.fromHex('DAE2FB'),
                                  fontSize: 8,
                                ),
                              ),
                          ],
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(right: 30),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Container(
                                width: 140,
                                height: 1,
                                color: PdfColors.white,
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                'Coordinación Académica',
                                style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
                              ),
                              pw.Text(
                                'Academia ABC',
                                style: pw.TextStyle(color: PdfColor.fromHex('94A3B8'), fontSize: 8),
                              ),
                            ],
                          ),
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
    );

    return pdf.save();
  }

  static Future<void> shareOrPrintCertificate({
    required String studentName,
    required String courseTitle,
    String? subjectCode,
    dynamic grade,
    String? cycleCode,
  }) async {
    final pdfBytes = await generatePdfBytes(
      studentName: studentName,
      courseTitle: courseTitle,
      subjectCode: subjectCode,
      grade: grade,
      cycleCode: cycleCode,
    );

    final cleanTitle = courseTitle.replaceAll(RegExp(r'\s+'), '_');
    final filename = 'Certificado_$cleanTitle.pdf';

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: filename,
    );
  }

  static Future<void> printPreviewCertificate({
    required String studentName,
    required String courseTitle,
    String? subjectCode,
    dynamic grade,
    String? cycleCode,
  }) async {
    final pdfBytes = await generatePdfBytes(
      studentName: studentName,
      courseTitle: courseTitle,
      subjectCode: subjectCode,
      grade: grade,
      cycleCode: cycleCode,
    );

    final cleanTitle = courseTitle.replaceAll(RegExp(r'\s+'), '_');

    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'Certificado_$cleanTitle',
    );
  }
}
