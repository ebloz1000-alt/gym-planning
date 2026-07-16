import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/app_models.dart';

class ReportExporter {
  static String buildExcelContent(String range, List<ReportRow> rows) {
    final buffer = StringBuffer();
    buffer.writeln('Report Name,$range');
    buffer.writeln('Generated At,${DateTime.now().toIso8601String()}');
    buffer.writeln('Title,Metric,Change,Status');
    for (final row in rows) {
      buffer.writeln(
        '${_escapeCsv(row.title)},${_escapeCsv(row.metric)},${_escapeCsv(row.change)},${_escapeCsv(row.status)}',
      );
    }
    return buffer.toString();
  }

  static Uint8List buildExcelWorkbookBytes(String range, List<ReportRow> rows) {
    final rowsXml = <String>[];
    rowsXml.add(_buildExcelRow(['Report Name', range]));
    rowsXml.add(_buildExcelRow(['Generated At', DateTime.now().toIso8601String()]));
    rowsXml.add(_buildExcelRow(['Title', 'Metric', 'Change', 'Status']));
    for (final row in rows) {
      rowsXml.add(
        _buildExcelRow([row.title, row.metric, row.change, row.status]),
      );
    }

    final sheetXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <sheetData>${rowsXml.join()}</sheetData>
</worksheet>''';

    final archive = Archive();
    archive.addFile(
      ArchiveFile(
        '[Content_Types].xml',
        utf8.encode('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
</Types>''').length,
        utf8.encode('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
</Types>'''),
      ),
    );
    archive.addFile(
      ArchiveFile(
        '_rels/.rels',
        utf8.encode('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''').length,
        utf8.encode('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>'''),
      ),
    );
    archive.addFile(
      ArchiveFile(
        'xl/workbook.xml',
        utf8.encode('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="Report" sheetId="1" r:id="rId1"/>
  </sheets>
</workbook>''').length,
        utf8.encode('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="Report" sheetId="1" r:id="rId1"/>
  </sheets>
</workbook>'''),
      ),
    );
    archive.addFile(
      ArchiveFile(
        'xl/_rels/workbook.xml.rels',
        utf8.encode('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''').length,
        utf8.encode('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>'''),
      ),
    );
    archive.addFile(
      ArchiveFile(
        'xl/worksheets/sheet1.xml',
        utf8.encode(sheetXml).length,
        utf8.encode(sheetXml),
      ),
    );
    archive.addFile(
      ArchiveFile(
        'xl/styles.xml',
        utf8.encode('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="1"><font><sz val="11"/><name val="Calibri"/></font></fonts>
  <fills count="1"><fill><patternFill patternType="none"/></fill></fills>
  <borders count="1"><border/></borders>
  <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
  <cellXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellXfs>
  <cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
</styleSheet>''').length,
        utf8.encode('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="1"><font><sz val="11"/><name val="Calibri"/></font></fonts>
  <fills count="1"><fill><patternFill patternType="none"/></fill></fills>
  <borders count="1"><border/></borders>
  <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
  <cellXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellXfs>
  <cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
</styleSheet>'''),
      ),
    );

    final encoder = ZipEncoder();
    final zipData = encoder.encode(archive);
    return Uint8List.fromList(zipData!);
  }

  static Future<Uint8List> buildPdfBytes(String range, List<ReportRow> rows) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Gym Booking Report', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Range: $range'),
            pw.Text('Generated: ${DateTime.now().toIso8601String()}'),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: ['Title', 'Metric', 'Change', 'Status'],
              data: [
                for (final row in rows)
                  [row.title, row.metric, row.change, row.status],
              ],
            ),
          ],
        ),
      ),
    );
    return pdf.save();
  }

  static Future<String> saveExportFile(
    String format,
    String range,
    List<ReportRow> rows,
  ) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${docsDir.path}/reports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final extension = format.toLowerCase() == 'pdf' ? 'pdf' : 'xlsx';
    final fileName = '${range.toLowerCase()}_$timestamp.$extension';
    final file = File('${exportDir.path}/$fileName');

    final bytes = format.toLowerCase() == 'pdf'
        ? await buildPdfBytes(range, rows)
        : buildExcelWorkbookBytes(range, rows);

    await file.writeAsBytes(bytes);
    return file.path;
  }

  static Future<void> openExportFile(String path) async {
    await OpenFile.open(path);
  }

  static String _buildExcelRow(List<String> values) {
    final safeValues = values.map((value) => _escapeXml(value)).toList();
    final cells = safeValues.map((value) {
      return '<c t="inlineStr"><is><t>$value</t></is></c>';
    }).join();
    return '<row>${cells}</row>';
  }

  static String _escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  static String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    if (escaped.contains(',') || escaped.contains('"') || escaped.contains('\n')) {
      return '"$escaped"';
    }
    return escaped;
  }
}
