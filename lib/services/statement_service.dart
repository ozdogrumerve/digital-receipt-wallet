import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/receipt_model.dart';

class StatementService {
  static Future<void> generateAndShare({
    required BuildContext context,
    required List<ReceiptModel> receipts,
    required DateTime month,
    double monthlyBudget = 0,
  }) async {
    final pdf = pw.Document();
    final monthLabel = DateFormat('MMMM yyyy').format(month);

    const primaryColor = PdfColor.fromInt(0xFF805AD5);
    const headerBg = PdfColor.fromInt(0xFF6B46C1);
    const rowEven = PdfColor.fromInt(0xFFF5F0FF);
    const rowOdd = PdfColors.white;
    const dividerColor = PdfColor.fromInt(0xFFD6BCFA);
    const textDark = PdfColor.fromInt(0xFF1A202C);
    const textMuted = PdfColor.fromInt(0xFF718096);

    final monthlyReceipts = receipts
        .where(
            (r) => r.date.year == month.year && r.date.month == month.month)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final double totalAmount =
        monthlyReceipts.fold(0.0, (sum, r) => sum + r.totalAmount);

    final Map<String, double> categoryTotals = {};
    for (var r in monthlyReceipts) {
      categoryTotals[r.category] =
          (categoryTotals[r.category] ?? 0) + r.totalAmount;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // TL sembolunun (lira isareti) pdf fontunda render edilmeme sorununu onlemek icin TL prefix kullaniyoruz
    String fmt(double amount) => 'TL ${amount.toStringAsFixed(2)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        build: (pw.Context ctx) => [
          // ── HEADER ──────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: headerBg,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Monthly Statement',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  monthLabel,
                  style: const pw.TextStyle(
                      fontSize: 13, color: PdfColors.white),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ── SUMMARY CARDS ────────────────────────────────────────
          pw.Row(
            children: [
              _summaryCard(
                  label: 'Total Spending',
                  value: fmt(totalAmount),
                  color: primaryColor),
              pw.SizedBox(width: 12),
              _summaryCard(
                  label: 'Transactions',
                  value: '${monthlyReceipts.length}',
                  color: const PdfColor.fromInt(0xFF9F7AEA)),
              if (monthlyBudget > 0) ...[
                pw.SizedBox(width: 12),
                _summaryCard(
                  label: 'Budget Used',
                  value: '%${((totalAmount / monthlyBudget) * 100).toStringAsFixed(1)}',
                  color: totalAmount > monthlyBudget
                      ? const PdfColor.fromInt(0xFFE53E3E)
                      : const PdfColor.fromInt(0xFF38A169),
                ),
              ],
            ],
          ),

          pw.SizedBox(height: 24),

          // ── CATEGORY SUMMARY ─────────────────────────────────────
          if (sortedCategories.isNotEmpty) ...[
            pw.Text(
              'Category Summary',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: textDark,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: dividerColor),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: sortedCategories.map((entry) {
                  final pct = totalAmount == 0
                      ? 0.0
                      : (entry.value / totalAmount) * 100;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 4,
                          child: pw.Text(entry.key,
                              style: const pw.TextStyle(
                                  fontSize: 10, color: textDark)),
                        ),
                        pw.SizedBox(width: 8),
                        pw.SizedBox(
                          width: 55,
                          child: pw.Text(
                            '%${pct.toStringAsFixed(1)}',
                            textAlign: pw.TextAlign.right,
                            style: const pw.TextStyle(
                                fontSize: 10, color: textMuted),
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.SizedBox(
                          width: 90,
                          child: pw.Text(
                            fmt(entry.value),
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            pw.SizedBox(height: 24),
          ],

          // ── TRANSACTION TABLE ─────────────────────────────────────
          pw.Text(
            'Transaction Details',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: textDark,
            ),
          ),
          pw.SizedBox(height: 8),

          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(3.5),
              2: const pw.FlexColumnWidth(2.5),
              3: const pw.FlexColumnWidth(2.2),
            },
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: primaryColor),
                children: ['Date', 'Store', 'Category', 'Amount']
                    .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8, vertical: 7),
                          child: pw.Text(
                            h,
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ))
                    .toList(),
              ),

              // Rows
              ...monthlyReceipts.asMap().entries.map((entry) {
                final i = entry.key;
                final r = entry.value;
                return pw.TableRow(
                  decoration:
                      pw.BoxDecoration(color: i.isEven ? rowEven : rowOdd),
                  children: [
                    _cell(DateFormat('dd MMM').format(r.date), textDark),
                    _cell(r.storeName, textDark),
                    _cell(r.category, textMuted),
                    _cell(fmt(r.totalAmount), textDark,
                        bold: true, align: pw.TextAlign.right),
                  ],
                );
              }),

              // Total
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFEDE9FE)),
                children: [
                  _cell('', textDark),
                  _cell('', textDark),
                  _cell('TOTAL', primaryColor, bold: true),
                  _cell(fmt(totalAmount), primaryColor,
                      bold: true, align: pw.TextAlign.right),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 28),

          // ── FOOTER ───────────────────────────────────────────────
          pw.Divider(color: dividerColor),
          pw.SizedBox(height: 6),
          pw.Text(
            'Generated by Digital Receipt Wallet  |  '
            '${DateFormat('dd MMMM yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8, color: textMuted),
          ),
        ],
      ),
    );

    final Uint8List bytes = await pdf.save();

    // sharePdf yerine layoutPdf kullaniyoruz — platform channel hatasini onler
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'statement_${DateFormat('yyyy_MM').format(month)}.pdf',
    );
  }

  static pw.Widget _summaryCard({
    required String label,
    required String value,
    required PdfColor color,
  }) =>
      pw.Expanded(
        child: pw.Container(
          padding:
              const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label,
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.white)),
              pw.SizedBox(height: 4),
              pw.Text(value,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  )),
            ],
          ),
        ),
      );

  static pw.Widget _cell(
    String text,
    PdfColor color, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Text(
          text,
          textAlign: align,
          style: pw.TextStyle(
            fontSize: 9.5,
            color: color,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );
}