import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart' as xls;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ── data passed from the participant screen ─────────────────────────────────
class ExportFlight {
  final String pigeonName;
  final String landingLabel; // e.g. "12:30 PM"
  final int durationSeconds;
  ExportFlight({required this.pigeonName, required this.landingLabel, required this.durationSeconds});
}

class ExportDay {
  final String date; // "2026-10-15"
  final int? avgSeconds;
  final int returnedCount;
  final List<ExportFlight> flights;
  ExportDay({required this.date, this.avgSeconds, required this.returnedCount, required this.flights});
}

class ParticipantExportData {
  final String participantName;
  final int rank;
  final int? overallAvgSeconds;
  final int overallReturnedCount;
  final List<ExportDay> days;
  ParticipantExportData({
    required this.participantName,
    required this.rank,
    this.overallAvgSeconds,
    required this.overallReturnedCount,
    required this.days,
  });
}

String _dur(int? s) {
  final v = s ?? 0;
  if (v <= 0) return '—';
  final h = v ~/ 3600, m = (v % 3600) ~/ 60, sec = v % 60;
  if (h > 0) return '${h}h ${m}m ${sec}s';
  if (m > 0) return '${m}m ${sec}s';
  return '${sec}s';
}

/// Generates and shares a participant's record as Text / Excel / PDF / Image.
class RecordExporter {
  static String _safeName(String s) => s.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');

  // ── Text summary (copy + share) ───────────────────────────────────────────
  static String buildText(ParticipantExportData d) {
    final b = StringBuffer();
    b.writeln('🕊️ ${d.participantName} — Race Record');
    b.writeln('Rank #${d.rank} · ${d.overallReturnedCount} landed · Overall avg ${_dur(d.overallAvgSeconds)}');
    b.writeln('');
    for (final day in d.days) {
      b.writeln('📅 ${day.date} — ${day.returnedCount} landed · avg ${_dur(day.avgSeconds)}');
      for (final f in day.flights) {
        b.writeln('   • ${f.pigeonName} — landed ${f.landingLabel} · ${_dur(f.durationSeconds)}');
      }
      b.writeln('');
    }
    b.writeln('Shared from PigeonFly');
    return b.toString();
  }

  static Future<void> shareText(ParticipantExportData d) async {
    final text = buildText(d);
    await Clipboard.setData(ClipboardData(text: text));
    await Share.share(text, subject: "${d.participantName}'s race record");
  }

  // ── Excel (.xlsx) ─────────────────────────────────────────────────────────
  static Future<void> shareExcel(ParticipantExportData d) async {
    final excel = xls.Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet() ?? 'Record'];
    sheet.appendRow([xls.TextCellValue('${d.participantName} — Rank #${d.rank} · Overall avg ${_dur(d.overallAvgSeconds)}')]);
    sheet.appendRow([xls.TextCellValue('')]);
    for (final day in d.days) {
      sheet.appendRow([xls.TextCellValue('Day ${day.date} — ${day.returnedCount} landed · avg ${_dur(day.avgSeconds)}')]);
      sheet.appendRow([xls.TextCellValue('Pigeon'), xls.TextCellValue('Landing'), xls.TextCellValue('Duration')]);
      for (final f in day.flights) {
        sheet.appendRow([
          xls.TextCellValue(f.pigeonName),
          xls.TextCellValue(f.landingLabel),
          xls.TextCellValue(_dur(f.durationSeconds)),
        ]);
      }
      sheet.appendRow([xls.TextCellValue('')]);
    }
    final bytes = excel.save();
    if (bytes == null) return;
    final path = await _write('${_safeName(d.participantName)}_record.xlsx', bytes);
    await Share.shareXFiles([XFile(path)], subject: "${d.participantName}'s record");
  }

  // ── PDF (.pdf) ────────────────────────────────────────────────────────────
  static Future<void> sharePdf(ParticipantExportData d) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Header(level: 0, child: pw.Text('${d.participantName} — Race Record', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
          pw.Text('Rank #${d.rank}  ·  ${d.overallReturnedCount} landed  ·  Overall avg ${_dur(d.overallAvgSeconds)}'),
          pw.SizedBox(height: 12),
          for (final day in d.days) ...[
            pw.SizedBox(height: 8),
            pw.Text('Day ${day.date}  —  ${day.returnedCount} landed · avg ${_dur(day.avgSeconds)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: ['Pigeon', 'Landing', 'Duration'],
              data: day.flights.map((f) => [f.pigeonName, f.landingLabel, _dur(f.durationSeconds)]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ],
          pw.SizedBox(height: 16),
          pw.Text('Shared from PigeonFly', style: const pw.TextStyle(color: PdfColors.grey)),
        ],
      ),
    );
    final bytes = await doc.save();
    final path = await _write('${_safeName(d.participantName)}_record.pdf', bytes);
    await Share.shareXFiles([XFile(path)], subject: "${d.participantName}'s record");
  }

  // ── Image card (.png) ─────────────────────────────────────────────────────
  static Future<void> shareImage(ParticipantExportData d) async {
    const w = 1080.0;
    final lines = <String>[
      'Rank #${d.rank}  ·  ${d.overallReturnedCount} landed',
      'Overall average   ${_dur(d.overallAvgSeconds)}',
      '',
      ...d.days.expand((day) => [
            '${day.date} — avg ${_dur(day.avgSeconds)}',
            ...day.flights.take(8).map((f) => '   ${f.pigeonName}   ${f.landingLabel}   ${_dur(f.durationSeconds)}'),
          ]),
    ];
    final h = 360.0 + lines.length * 46.0 + 80.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));
    // background gradient
    final bg = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF2D3A8C), Color(0xFF4F63D2)])
          .createShader(Rect.fromLTWH(0, 0, w, 320));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, 320), bg);
    canvas.drawRect(Rect.fromLTWH(0, 320, w, h - 320), Paint()..color = const Color(0xFFF4F6FB));

    void text(String s, double x, double y, double size, Color color, {bool bold = false}) {
      final tp = TextPainter(
        text: TextSpan(text: s, style: TextStyle(color: color, fontSize: size, fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: w - 120);
      tp.paint(canvas, Offset(x, y));
    }

    text('🕊️  PigeonFly', 60, 60, 40, Colors.white70);
    text(d.participantName, 60, 140, 72, Colors.white, bold: true);
    text('Race record', 60, 232, 40, Colors.white70);

    double y = 360;
    for (final l in lines) {
      text(l, 60, y, l.startsWith('   ') ? 34 : 40, l.startsWith('   ') ? const Color(0xFF5A6478) : const Color(0xFF151A2E),
          bold: !l.startsWith('   ') && l.isNotEmpty);
      y += 46;
    }

    final img = await recorder.endRecording().toImage(w.toInt(), h.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;
    final path = await _write('${_safeName(d.participantName)}_record.png', bytes.buffer.asUint8List());
    await Share.shareXFiles([XFile(path)], subject: "${d.participantName}'s record");
  }

  // ── tournament-level link helpers ─────────────────────────────────────────
  static Future<void> shareLink(String url, {String? subject}) => Share.share(url, subject: subject);
  static Future<void> copyLink(String url) => Clipboard.setData(ClipboardData(text: url));

  static Future<String> _write(String name, List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
