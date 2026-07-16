
import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/report_export.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_cards.dart';
import '../../core/widgets/app_charts.dart';
import '../../core/widgets/status_badge.dart';
import '../../providers_or_bloc/app_state.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _range = 'Monthly';
  final List<_ReportExport> _exports = [];

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.watch(context).repository;
    return FeaturePage(
      title: 'Reports',
      subtitle:
          'Daily, monthly, revenue, trainer, equipment, membership, and feedback reports.',
      children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'Daily', label: Text('Daily')),
            ButtonSegment(value: 'Monthly', label: Text('Monthly')),
            ButtonSegment(value: 'Custom', label: Text('Custom')),
          ],
          selected: {_range},
          onSelectionChanged: (value) => setState(() => _range = value.first),
        ),
        const SizedBox(height: 12),
        AppCard(child: AppBarChart(points: repo.revenueTrend)),
        AppCard(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AppButton(
                label: 'Export PDF',
                icon: Icons.picture_as_pdf_outlined,
                onPressed: () => _exportReport('PDF'),
              ),
              AppButton(
                label: 'Export Excel',
                icon: Icons.table_chart_outlined,
                onPressed: () => _exportReport('Excel'),
              ),
              AppButton(
                label: 'Preview',
                icon: Icons.visibility_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: () => _showPreview(context),
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'Report preview'),
        ...repo.reportRows.map(
          (row) => AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.summarize_outlined),
              title: Text(row.title),
              subtitle: Text('${row.metric} - ${row.change}'),
              trailing: StatusBadge(label: row.status, compact: true),
            ),
          ),
        ),
        const SectionHeader(title: 'Download history'),
        if (_exports.isEmpty)
          const AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.download_done_outlined),
              title: Text('Monthly revenue report'),
              subtitle: Text('PDF and Excel generated for admin review'),
              trailing: StatusBadge(label: 'Ready', compact: true),
            ),
          )
        else
          ..._exports.map(
            (export) => AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  export.format == 'PDF'
                      ? Icons.picture_as_pdf_outlined
                      : Icons.table_chart_outlined,
                ),
                title: Text('${export.range} ${export.format} report'),
                subtitle: Text(formatDate(export.createdAt)),
                trailing: const StatusBadge(label: 'Ready', compact: true),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _exportReport(String format) async {
    final uri = Uri.parse('http://localhost:8000/api/exports/reports/?format=${format.toLowerCase()}&range=${Uri.encodeComponent(_range)}');
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        final body = resp.body.isNotEmpty ? resp.body : 'status ${resp.statusCode}';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $body')));
        return;
      }

      final docsDir = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${docsDir.path}/reports');
      if (!await exportDir.exists()) await exportDir.create(recursive: true);

      // derive extension from content-type
      final contentType = resp.headers['content-type'] ?? '';
      final extension = contentType.contains('pdf') ? 'pdf' : 'xlsx';
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      final fileName = '${_range.toLowerCase()}_$timestamp.$extension';
      final file = File('${exportDir.path}/$fileName');
      await file.writeAsBytes(resp.bodyBytes);

      if (!mounted) return;
      await OpenFile.open(file.path);

      setState(() {
        _exports.insert(0, _ReportExport(format: format, range: _range, createdAt: DateTime.now()));
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$format export saved to ${file.path}')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  void _showPreview(BuildContext context) {
    final rows = AppScope.read(context).repository.reportRows;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$_range report preview'),
        content: SizedBox(
          width: 420,
          child: ListView(
            shrinkWrap: true,
            children: rows
                .map(
                  (row) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.summarize_outlined),
                    title: Text(row.title),
                    subtitle: Text('${row.metric} - ${row.change}'),
                    trailing: StatusBadge(label: row.status, compact: true),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ReportExport {
  const _ReportExport({
    required this.format,
    required this.range,
    required this.createdAt,
  });

  final String format;
  final String range;
  final DateTime createdAt;
}
