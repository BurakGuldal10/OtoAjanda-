import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/vehicle.dart';

class ExportService {
  static final _currencyFormat =
      NumberFormat.currency(locale: 'tr_TR', symbol: 'TL');
  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _kmFormat = NumberFormat('#,##0', 'tr_TR');

  // ── Excel ─────────────────────────────────────────────────────────

  static Future<String> exportVehiclesToExcel(
      List<Vehicle> vehicles) async {
    final excel = Excel.createExcel();
    try { excel.delete('Sheet1'); } catch (_) {}
    final sheet = excel['Araç Listesi'];
    final now = DateTime.now();
    const colCount = 13;

    // ── Satır 0: Ana başlık (birleştirilmiş) ────────────────────────
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: colCount - 1, rowIndex: 0),
    );
    _setCell(sheet, 0, 0,
      value: TextCellValue('GaleriPro — Araç Listesi'),
      style: CellStyle(
        bold: true,
        fontSize: 16,
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: ExcelColor.fromHexString('#1E40AF'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      ),
    );
    sheet.setRowHeight(0, 36);

    // ── Satır 1: Alt bilgi (tarih + araç sayısı) ─────────────────────
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: colCount - 1, rowIndex: 1),
    );
    _setCell(sheet, 0, 1,
      value: TextCellValue(
        'Oluşturma Tarihi: ${DateFormat('dd/MM/yyyy HH:mm').format(now)}'
        '   |   Toplam Araç: ${vehicles.length}'),
      style: CellStyle(
        italic: true,
        fontSize: 10,
        fontColorHex: ExcelColor.fromHexString('#1E40AF'),
        backgroundColorHex: ExcelColor.fromHexString('#DBEAFE'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      ),
    );
    sheet.setRowHeight(1, 22);

    // ── Satır 2: Sütun başlıkları ────────────────────────────────────
    const hRow = 2;
    final headers = [
      'No', 'Plaka', 'Marka', 'Model', 'Yıl', 'Renk',
      'Kilometre', 'Alış Fiyatı', 'Alış Tarihi',
      'Satış Fiyatı', 'Satış Tarihi', 'Brüt Kâr', 'Durum',
    ];

    final hBorderMed = Border(
      borderStyle: BorderStyle.Medium,
      borderColorHex: ExcelColor.fromHexString('#1E40AF'),
    );
    final hBorderThin = Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString('#3B82F6'),
    );

    for (var i = 0; i < headers.length; i++) {
      _setCell(sheet, i, hRow,
        value: TextCellValue(headers[i]),
        style: CellStyle(
          bold: true,
          fontSize: 10,
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
          backgroundColorHex: ExcelColor.fromHexString('#2563EB'),
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
          topBorder: hBorderMed,
          bottomBorder: hBorderMed,
          leftBorder: hBorderThin,
          rightBorder: hBorderThin,
        ),
      );
    }
    sheet.setRowHeight(hRow, 26);

    // ── Veri satırları ───────────────────────────────────────────────
    double toplamAlis = 0, toplamSatis = 0, toplamKar = 0;
    const borderColor = '#D1D5DB';

    for (var idx = 0; idx < vehicles.length; idx++) {
      final v = vehicles[idx];
      final rowIdx = hRow + 1 + idx;
      final rowBgHex = idx % 2 == 0 ? '#FFFFFF' : '#EFF6FF';

      toplamAlis += v.alisFiyati;
      toplamSatis += v.satisFiyati ?? 0;
      toplamKar += v.kar ?? 0;

      // Durum rengi
      final (durumBgHex, durumFgHex) = switch (v.durum) {
        'satildi' => ('#D1FAE5', '#065F46'),
        'rezerve' => ('#FEF3C7', '#92400E'),
        _          => ('#DBEAFE', '#1E40AF'),
      };

      // Kâr rengi
      final karPos = (v.kar ?? 0) >= 0;
      final karBgHex = karPos ? '#DCFCE7' : '#FEE2E2';
      final karFgHex = karPos ? '#166534' : '#991B1B';

      final kmStr = v.kilometre != null
          ? '${_kmFormat.format(v.kilometre)} km'
          : '-';

      final cells = <(CellValue, CellStyle)>[
        (TextCellValue('${idx + 1}'),
            _dataStyle(rowBgHex, HorizontalAlign.Center, borderColor: borderColor)),
        (TextCellValue(v.plaka),
            _dataStyle(rowBgHex, HorizontalAlign.Center,
                bold: true, fgHex: '#1E40AF', borderColor: borderColor)),
        (TextCellValue(v.marka),
            _dataStyle(rowBgHex, HorizontalAlign.Left, borderColor: borderColor)),
        (TextCellValue(v.model),
            _dataStyle(rowBgHex, HorizontalAlign.Left, borderColor: borderColor)),
        (TextCellValue(v.yil?.toString() ?? '-'),
            _dataStyle(rowBgHex, HorizontalAlign.Center, borderColor: borderColor)),
        (TextCellValue(v.renk ?? '-'),
            _dataStyle(rowBgHex, HorizontalAlign.Center, borderColor: borderColor)),
        (TextCellValue(kmStr),
            _dataStyle(rowBgHex, HorizontalAlign.Right, borderColor: borderColor)),
        (TextCellValue(_currencyFormat.format(v.alisFiyati)),
            _dataStyle(rowBgHex, HorizontalAlign.Right, borderColor: borderColor)),
        (TextCellValue(v.alisTarihi != null ? _dateFormat.format(v.alisTarihi!) : '-'),
            _dataStyle(rowBgHex, HorizontalAlign.Center, borderColor: borderColor)),
        (TextCellValue(v.satisFiyati != null
            ? _currencyFormat.format(v.satisFiyati!)
            : '-'),
            _dataStyle(rowBgHex, HorizontalAlign.Right, borderColor: borderColor)),
        (TextCellValue(v.satisTarihi != null ? _dateFormat.format(v.satisTarihi!) : '-'),
            _dataStyle(rowBgHex, HorizontalAlign.Center, borderColor: borderColor)),
        (TextCellValue(v.kar != null ? _currencyFormat.format(v.kar!) : '-'),
            _dataStyle(karBgHex, HorizontalAlign.Right,
                bold: true, fgHex: karFgHex, borderColor: '#A7F3D0')),
        (TextCellValue(_durumLabel(v.durum)),
            _dataStyle(durumBgHex, HorizontalAlign.Center,
                bold: true, fgHex: durumFgHex, borderColor: borderColor)),
      ];

      for (var col = 0; col < cells.length; col++) {
        _setCell(sheet, col, rowIdx,
            value: cells[col].$1, style: cells[col].$2);
      }
      sheet.setRowHeight(rowIdx, 20);
    }

    // ── Toplam satırı ────────────────────────────────────────────────
    if (vehicles.isNotEmpty) {
      final tRow = hRow + 1 + vehicles.length;

      // Col 0–6: birleştirilmiş "TOPLAM" etiketi
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: tRow),
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: tRow),
      );
      final tBorderMed = Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#1E40AF'),
      );
      _setCell(sheet, 0, tRow,
        value: TextCellValue('TOPLAM — ${vehicles.length} araç'),
        style: CellStyle(
          bold: true,
          fontSize: 10,
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
          backgroundColorHex: ExcelColor.fromHexString('#1E40AF'),
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
          topBorder: tBorderMed,
          bottomBorder: tBorderMed,
        ),
      );

      final karTotalPos = toplamKar >= 0;

      // Toplam Alış (col 7)
      _setCell(sheet, 7, tRow,
        value: TextCellValue(_currencyFormat.format(toplamAlis)),
        style: _totalStyle('#FEF9C3'),
      );
      // Alış Tarihi boş (col 8)
      _setCell(sheet, 8, tRow, style: _totalStyle('#FEF9C3'));
      // Toplam Satış (col 9)
      _setCell(sheet, 9, tRow,
        value: TextCellValue(_currencyFormat.format(toplamSatis)),
        style: _totalStyle('#FEF9C3'),
      );
      // Satış Tarihi boş (col 10)
      _setCell(sheet, 10, tRow, style: _totalStyle('#FEF9C3'));
      // Toplam Kâr (col 11)
      _setCell(sheet, 11, tRow,
        value: TextCellValue(_currencyFormat.format(toplamKar)),
        style: _totalStyle(
          karTotalPos ? '#DCFCE7' : '#FEE2E2',
          fgHex: karTotalPos ? '#166534' : '#991B1B',
        ),
      );
      // Durum boş (col 12)
      _setCell(sheet, 12, tRow, style: _totalStyle('#FEF9C3'));

      sheet.setRowHeight(tRow, 24);
    }

    // ── Sütun genişlikleri (A4 yatay baskıya uygun) ─────────────────
    sheet.setColumnWidth(0,  5);  // No
    sheet.setColumnWidth(1,  12); // Plaka
    sheet.setColumnWidth(2,  14); // Marka
    sheet.setColumnWidth(3,  15); // Model
    sheet.setColumnWidth(4,  7);  // Yıl
    sheet.setColumnWidth(5,  11); // Renk
    sheet.setColumnWidth(6,  15); // Kilometre
    sheet.setColumnWidth(7,  18); // Alış Fiyatı
    sheet.setColumnWidth(8,  13); // Alış Tarihi
    sheet.setColumnWidth(9,  18); // Satış Fiyatı
    sheet.setColumnWidth(10, 13); // Satış Tarihi
    sheet.setColumnWidth(11, 18); // Brüt Kâr
    sheet.setColumnWidth(12, 12); // Durum

    final bytes = excel.save();
    if (bytes == null) throw Exception('Excel oluşturulamadı');

    final path = _buildSavePath('GaleriPro_Araclar', 'xlsx');
    File(path).writeAsBytesSync(bytes);
    return path;
  }

  // ── Excel yardımcıları ────────────────────────────────────────────

  static void _setCell(
    Sheet sheet,
    int col,
    int row, {
    CellValue? value,
    CellStyle? style,
  }) {
    final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    if (value != null) cell.value = value;
    if (style != null) cell.cellStyle = style;
  }

  static CellStyle _dataStyle(
    String bgHex,
    HorizontalAlign align, {
    bool bold = false,
    String? fgHex,
    String borderColor = '#E5E7EB',
  }) {
    final b = Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString(borderColor),
    );
    return CellStyle(
      bold: bold,
      fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString(bgHex),
      fontColorHex: ExcelColor.fromHexString(fgHex ?? '#1F2937'),
      horizontalAlign: align,
      verticalAlign: VerticalAlign.Center,
      topBorder: b,
      bottomBorder: b,
      leftBorder: b,
      rightBorder: b,
    );
  }

  static CellStyle _totalStyle(String bgHex, {String? fgHex}) {
    final bMed = Border(
      borderStyle: BorderStyle.Medium,
      borderColorHex: ExcelColor.fromHexString('#6B7280'),
    );
    final bThin = Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString('#6B7280'),
    );
    return CellStyle(
      bold: true,
      fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString(bgHex),
      fontColorHex: ExcelColor.fromHexString(fgHex ?? '#1F2937'),
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      topBorder: bMed,
      bottomBorder: bMed,
      leftBorder: bThin,
      rightBorder: bThin,
    );
  }

  // ── PDF ───────────────────────────────────────────────────────────

  static Future<void> exportStatsToPdf({
    required Map<String, dynamic> stats,
    required List<Vehicle> soldVehicles,
    required Map<String, double> vehicleExpenses,
  }) async {
    // Türkçe karakter desteği için Google Fonts'tan NotoSans yükle
    final fontRegular = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        header: (ctx) => _pdfHeader(ctx, fontBold, now),
        footer: (ctx) => _pdfFooter(ctx, fontRegular),
        build: (ctx) => [
          _pdfSummarySection(stats, fontBold, fontRegular),
          pw.SizedBox(height: 24),
          _pdfSalesTable(
              soldVehicles, vehicleExpenses, fontBold, fontRegular),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'GaleriPro_Rapor_${DateFormat('yyyyMMdd').format(now)}.pdf',
    );
  }

  static pw.Widget _pdfHeader(
      pw.Context ctx, pw.Font fontBold, DateTime now) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.blue700, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'GaleriPro — Satış Raporu',
            style: pw.TextStyle(
                font: fontBold,
                fontSize: 16,
                color: PdfColors.blue700),
          ),
          pw.Text(
            DateFormat('dd MMMM yyyy').format(now),
            style: pw.TextStyle(
                fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfFooter(pw.Context ctx, pw.Font fontRegular) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('GaleriPro',
              style: pw.TextStyle(
                  fontSize: 9, color: PdfColors.grey500)),
          pw.Text('Sayfa ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: pw.TextStyle(
                  fontSize: 9, color: PdfColors.grey500)),
        ],
      ),
    );
  }

  static pw.Widget _pdfSummarySection(Map<String, dynamic> stats,
      pw.Font fontBold, pw.Font fontRegular) {
    final items = [
      ('Toplam Araç', '${stats['toplamArac'] ?? 0}'),
      ('Stokta', '${stats['stoktaAdet'] ?? 0}'),
      ('Rezerve', '${stats['rezerveAdet'] ?? 0}'),
      ('Satılan', '${stats['satilanAdet'] ?? 0}'),
      ('Brüt Kâr',
          _currencyFormat.format(stats['brutKar'] ?? 0)),
      ('Toplam Gider',
          _currencyFormat.format(stats['toplamGider'] ?? 0)),
      ('Net Kâr',
          _currencyFormat.format(stats['toplamKar'] ?? 0)),
      ('Stok Yatırımı',
          _currencyFormat.format(stats['toplamYatirim'] ?? 0)),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Özet İstatistikler',
            style: pw.TextStyle(
                font: fontBold,
                fontSize: 13,
                color: PdfColors.grey800)),
        pw.SizedBox(height: 10),
        pw.Wrap(
          spacing: 12,
          runSpacing: 8,
          children: items.map((item) {
            return pw.Container(
              width: 180,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(item.$1,
                      style: pw.TextStyle(
                          fontSize: 9, color: PdfColors.grey600)),
                  pw.SizedBox(height: 4),
                  pw.Text(item.$2,
                      style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 12,
                          color: PdfColors.grey800)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static pw.Widget _pdfSalesTable(
      List<Vehicle> soldVehicles,
      Map<String, double> vehicleExpenses,
      pw.Font fontBold,
      pw.Font fontRegular) {
    if (soldVehicles.isEmpty) {
      return pw.Text('Henüz satış yapılmamış.',
          style: pw.TextStyle(color: PdfColors.grey500));
    }

    final headers = [
      'Araç',
      'Plaka',
      'Satış Tarihi',
      'Alış',
      'Satış',
      'Gider',
      'Net Kâr',
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Satış Geçmişi',
            style: pw.TextStyle(
                font: fontBold,
                fontSize: 13,
                color: PdfColors.grey800)),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(
              color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1.2),
            2: const pw.FlexColumnWidth(1.2),
            3: const pw.FlexColumnWidth(1.4),
            4: const pw.FlexColumnWidth(1.4),
            5: const pw.FlexColumnWidth(1.2),
            6: const pw.FlexColumnWidth(1.4),
          },
          children: [
            // Başlık satırı
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                  color: PdfColors.blue700),
              children: headers
                  .map((h) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6, vertical: 5),
                        child: pw.Text(h,
                            style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 8,
                                color: PdfColors.white)),
                      ))
                  .toList(),
            ),
            // Veri satırları
            ...soldVehicles.asMap().entries.map((entry) {
              final v = entry.value;
              final gider = vehicleExpenses[v.id] ?? 0;
              final netKar = (v.kar ?? 0) - gider;
              final isEven = entry.key % 2 == 0;

              return pw.TableRow(
                decoration: pw.BoxDecoration(
                    color: isEven ? PdfColors.white : PdfColors.grey50),
                children: [
                  _pdfCell('${v.marka} ${v.model}', fontRegular),
                  _pdfCell(v.plaka, fontBold,
                      color: PdfColors.blue700),
                  _pdfCell(
                      v.satisTarihi != null
                          ? _dateFormat.format(v.satisTarihi!)
                          : '-',
                      fontRegular),
                  _pdfCell(
                      _currencyFormat.format(v.alisFiyati), fontRegular),
                  _pdfCell(
                      _currencyFormat.format(v.satisFiyati ?? 0),
                      fontRegular),
                  _pdfCell(_currencyFormat.format(gider), fontRegular,
                      color: PdfColors.orange700),
                  _pdfCell(_currencyFormat.format(netKar), fontBold,
                      color: netKar >= 0
                          ? PdfColors.green700
                          : PdfColors.red700),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _pdfCell(String text, pw.Font font,
      {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
            font: font, fontSize: 8, color: color ?? PdfColors.grey800),
      ),
    );
  }

  // ── Yardımcılar ───────────────────────────────────────────────────

  static String _buildSavePath(String name, String ext) {
    final home = Platform.environment['USERPROFILE'] ??
        Platform.environment['HOME'] ??
        '.';
    final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return '$home\\Downloads\\${name}_$ts.$ext';
  }

  static String _durumLabel(String durum) {
    switch (durum) {
      case 'satildi':
        return 'Satıldı';
      case 'rezerve':
        return 'Rezerve';
      default:
        return 'Stokta';
    }
  }
}
