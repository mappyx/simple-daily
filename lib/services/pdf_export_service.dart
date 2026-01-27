import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/note.dart';

class PdfExportService {
  /// Export a single note to PDF
  Future<void> exportNoteToPdf(Note note) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                note.title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Last modified: ${_formatDate(note.lastModified)}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                note.content.isEmpty ? 'No content' : note.content,
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          );
        },
      ),
    );

    // Save PDF
    await _savePdf(pdf, '${note.title}.pdf');
  }

  /// Export all notes to a single PDF
  Future<void> exportAllNotesToPdf(List<Note> notes) async {
    if (notes.isEmpty) {
      throw Exception('No notes to export');
    }

    final pdf = pw.Document();

    // Add cover page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'SimpleDaily Notes Export',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Total notes: ${notes.length}',
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Exported on: ${_formatDate(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Add each note as a separate page
    for (var note in notes) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  note.title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Last modified: ${_formatDate(note.lastModified)}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey,
                  ),
                ),
                pw.Divider(),
                pw.SizedBox(height: 12),
                pw.Text(
                  note.content.isEmpty ? 'No content' : note.content,
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            );
          },
        ),
      );
    }

    // Save PDF
    await _savePdf(pdf, 'SimpleDaily_All_Notes.pdf');
  }

  /// Save PDF to Downloads folder
  Future<void> _savePdf(pw.Document pdf, String filename) async {
    try {
      // Get Downloads directory
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        throw Exception('Could not access Downloads directory');
      }

      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(await pdf.save());
      
      print('PDF saved to: ${file.path}');
    } catch (e) {
      print('Error saving PDF: $e');
      rethrow;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
