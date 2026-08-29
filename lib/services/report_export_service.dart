import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'analytics_service.dart';
import 'admin_dashboard_service.dart';

class ReportExportService {
  Future<void> exportSystemReport({
    required AdminDashboardMetrics metrics,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'EduTrack PHS - System Audit Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Text('Generated Date: ${DateTime.now().toLocal()}'),
            pw.SizedBox(height: 18),
            pw.Text('Total Users: ${metrics.totalUsers}'),
            pw.Text('Pending User Approvals: ${metrics.pendingApprovals}'),
            pw.Text('ICT Assets: ${metrics.ictAssets}'),
            pw.Text('Maintenance Items: ${metrics.maintenanceItems}'),
            pw.Text('Active Borrowings: ${metrics.activeBorrowings}'),
            pw.SizedBox(height: 12),
            pw.Text('Users by Role'),
            for (final entry in metrics.usersByRole.entries)
              pw.Text('${entry.key}: ${entry.value}'),
          ],
        ),
      ),
    );
    final file = await _writeTempFile(
      filename:
          'edutrack_phs_system_audit_${DateTime.now().millisecondsSinceEpoch}.pdf',
      content: await pdf.save(),
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'EduTrack PHS system audit report',
      ),
    );
  }

  Future<void> exportSummary({
    required AnalyticsSummary summary,
    required String format,
  }) async {
    final normalizedFormat = format.trim().toUpperCase();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');

    if (normalizedFormat == 'CSV') {
      final csv = _buildCsv(summary);
      final file = await _writeTempFile(
        filename: 'edutrack_phs_report_$timestamp.csv',
        content: csv,
      );
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'EduTrack PHS report'),
      );
      return;
    }

    final pdfBytes = await _buildPdf(summary);
    final file = await _writeTempFile(
      filename: 'edutrack_phs_report_$timestamp.pdf',
      content: pdfBytes,
    );
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'EduTrack PHS PDF report'),
    );
  }

  String _buildCsv(AnalyticsSummary summary) {
    final buffer = StringBuffer();
    buffer.writeln('EduTrack PHS - Property Custodian Report');
    buffer.writeln('Generated Date,${DateTime.now().toLocal()}');
    buffer.writeln('Date Range,${summary.range.label}');
    buffer.writeln('');
    buffer.writeln('Metric,Value');
    buffer.writeln('Total Borrowed Items,${summary.totalBorrowings}');
    buffer.writeln(
      'On-Time Return Rate,${summary.onTimeReturnRate.toStringAsFixed(1)}%',
    );
    buffer.writeln(
      'Late Return Rate,${summary.overdueRate.toStringAsFixed(1)}%',
    );
    buffer.writeln('Active Borrowers,${summary.activeBorrowers}');
    buffer.writeln('Damaged/Replaced Items,${summary.damagedOrReplacedCount}');
    buffer.writeln('');
    buffer.writeln('Category,Share');
    for (final entry in summary.categoryDistribution.entries) {
      buffer.writeln('${entry.key},${(entry.value * 100).toStringAsFixed(1)}%');
    }
    buffer.writeln('');
    buffer.writeln('Return Type,Count');
    for (final entry in summary.resolutionBreakdown.entries) {
      if (entry.value > 0) {
        buffer.writeln('${entry.key},${entry.value}');
      }
    }
    buffer.writeln('');
    buffer.writeln('Resource,Count,Stock');
    for (final resource in summary.topResources) {
      buffer.writeln(
        '${resource.resourceName},${resource.borrowCount},${resource.stockLabel}',
      );
    }
    return buffer.toString();
  }

  Future<Uint8List> _buildPdf(AnalyticsSummary summary) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'EduTrack PHS - Property Custodian Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Text('Generated Date: ${DateTime.now().toLocal()}'),
            pw.Text('Date Range: ${summary.range.label}'),
            pw.SizedBox(height: 18),
            pw.Text('Total Borrowed Items: ${summary.totalBorrowings}'),
            pw.Text(
              'On-Time Return Rate: ${summary.onTimeReturnRate.toStringAsFixed(1)}%',
            ),
            pw.Text(
              'Late Return Rate: ${summary.overdueRate.toStringAsFixed(1)}%',
            ),
            pw.Text('Active Borrowers: ${summary.activeBorrowers}'),
            pw.SizedBox(height: 12),
            pw.Text('Category Distribution'),
            for (final entry in summary.categoryDistribution.entries)
              pw.Text(
                '${entry.key}: ${(entry.value * 100).toStringAsFixed(1)}%',
              ),
            pw.SizedBox(height: 12),
            pw.Text('Top Resources'),
            for (final resource in summary.topResources)
              pw.Text(
                '${resource.resourceName}: ${resource.borrowCount} borrow(s)',
              ),
          ],
        ),
      ),
    );
    return pdf.save();
  }

  Future<File> _writeTempFile({
    required String filename,
    required dynamic content,
  }) async {
    final tempDir = Directory.systemTemp.createTempSync('edutrack_reports');
    final file = File('${tempDir.path}/$filename');

    if (content is Uint8List) {
      await file.writeAsBytes(content);
    } else {
      await file.writeAsString(content.toString());
    }
    return file;
  }
}
