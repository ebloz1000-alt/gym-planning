import 'package:flutter_test/flutter_test.dart';
import 'package:gym_booking_app/core/utils/report_export.dart';
import 'package:gym_booking_app/models/app_models.dart';

void main() {
  test('builds excel content with report rows', () {
    final rows = [
      const ReportRow(
        title: 'Daily revenue',
        metric: 'KES 74,200',
        change: '+12%',
        status: 'Ready',
      ),
    ];

    final excelContent = ReportExporter.buildExcelContent('Monthly', rows);

    expect(excelContent, contains('Report Name,Monthly'));
    expect(excelContent, contains('Title,Metric,Change,Status'));
    expect(excelContent, contains('Daily revenue'));
  });

  test('builds excel workbook bytes for a report export', () {
    final rows = [
      const ReportRow(
        title: 'Membership growth',
        metric: '126 active',
        change: '+16%',
        status: 'Ready',
      ),
    ];

    final workbookBytes = ReportExporter.buildExcelWorkbookBytes('Monthly', rows);

    expect(workbookBytes, isNotEmpty);
  });

  test('builds pdf bytes for a report export', () async {
    final rows = [
      const ReportRow(
        title: 'Membership growth',
        metric: '126 active',
        change: '+16%',
        status: 'Ready',
      ),
    ];

    final pdfBytes = await ReportExporter.buildPdfBytes('Monthly', rows);

    expect(pdfBytes, isNotEmpty);
  });
}
