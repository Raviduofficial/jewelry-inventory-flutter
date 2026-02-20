import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../database/db_helper.dart';
import 'package:intl/intl.dart'; 

class ReportSetupScreen extends StatefulWidget {
  const ReportSetupScreen({super.key});

  @override
  State<ReportSetupScreen> createState() => _ReportSetupScreenState();
}

class _ReportSetupScreenState extends State<ReportSetupScreen> {
  bool showPrices = true;
  bool showOnlyDifferences = false; 
  bool showLowStockWarnings = true;
  bool isGenerating = false;

  Future<void> _generateAndSharePDF() async {
    setState(() => isGenerating = true);

    try {
      final items = await DBHelper.instance.getFilteredItems('', null);
      final pdf = pw.Document();

      // --- 1. Headers Update (අලුත් Column එක දැම්මා) ---
      final List<String> headers = ['Item Name', 'System', 'Real', 'Status'];
      if (showPrices) {
        headers.add('Stock Value');
        headers.add('Sold Income'); // විකුණුනු ගාණට එන්න ඕන ආදායම
      }

      final List<List<String>> tableData = [];
      double totalReportValue = 0.0;
      int totalSoldItems = 0;
      double totalExpectedIncome = 0.0; // මුළු ආදායම එකතු කරන්න Variable එකක්

      // --- 2. Data Calculation ---
      for (var item in items) {
        int sysQty = item['quantity'] ?? 0;
        int? realQty = item['physical_quantity'];
        double price = (item['price'] as num?)?.toDouble() ?? 0.0;
        int limit = item['min_limit'] ?? 5;

        int currentQty = realQty ?? sysQty;
        int diff = (realQty != null) ? (realQty - sysQty) : 0;
        
        if (showOnlyDifferences && diff == 0) continue;

        String status = 'Balanced';
        double itemSoldIncome = 0.0; // මේ අයිටම් එකෙන් ආපු ආදායම

        if (diff < 0) {
          status = 'Sold: ${diff.abs()}';
          totalSoldItems += diff.abs();
          
          // විකුණුනු ගාණ * මිල
          itemSoldIncome = diff.abs() * price; 
          totalExpectedIncome += itemSoldIncome; // Total එකට එකතු කරනවා
          
        } else if (diff > 0) {
          status = 'Surplus: +$diff';
        } else if (showLowStockWarnings && currentQty <= limit) {
          status = 'LOW STOCK';
        }

        double itemValue = currentQty * price;
        totalReportValue += itemValue;

        // --- 3. Table Rows Update ---
        List<String> row = [
          item['name'],
          sysQty.toString(),
          realQty?.toString() ?? '-',
          status,
        ];
        
        if (showPrices) {
          row.add('Rs. ${itemValue.toStringAsFixed(2)}');
          // ආදායමක් තියෙනවා නම් ඒක පෙන්නනවා, නැත්නම් ඉරක් ගහනවා
          row.add(itemSoldIncome > 0 ? 'Rs. ${itemSoldIncome.toStringAsFixed(2)}' : '-'); 
        }

        tableData.add(row);
      }

      String currentDate = DateFormat('yyyy-MM-dd / hh:mm a').format(DateTime.now());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('MONTHLY STOCK REPORT', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                    pw.Text(currentDate, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text('Automatically generated from the Inventory App.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              pw.SizedBox(height: 20),

              // The Data Table
              pw.TableHelper.fromTextArray(
                headers: headers,
                data: tableData,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: const pw.TextStyle(fontSize: 10),
                headerHeight: 28,
                cellHeight: 25,
                // Column widths ගාණට හදලා තියෙන්නේ table එක කැත නොවෙන්න
                columnWidths: showPrices ? {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1.2),
                  2: const pw.FlexColumnWidth(1.2),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(2),
                  5: const pw.FlexColumnWidth(2),
                } : null,
              ),

              pw.SizedBox(height: 30),

              // --- 4. Summary Section Update (ලොකුවට ආදායම පෙන්වීම) ---
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(color: PdfColors.grey100, border: pw.Border.all(color: PdfColors.teal, width: 1.5)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('REPORT SUMMARY', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.teal800)),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Items Checked:'),
                        pw.Text('${tableData.length}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ]
                    ),
                    pw.SizedBox(height: 5),
                    if (!showOnlyDifferences) 
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total Items Sold (Qty):'),
                          pw.Text('$totalSoldItems', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ]
                      ),
                    pw.SizedBox(height: 5),
                    if (showPrices) 
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Remaining Stock Value:'),
                          pw.Text('Rs. ${totalReportValue.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                        ]
                      ),
                    
                    if (showPrices) pw.Divider(color: PdfColors.grey400),
                    
                    // EXPECTED CASH / INCOME
                    if (showPrices) 
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('EXPECTED INCOME (CASH IN DRAWER):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                          pw.Text('Rs. ${totalExpectedIncome.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.green800)),
                        ]
                      ),
                  ],
                ),
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Stock_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
    } finally {
      setState(() => isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Customize Report')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select what to include in the PDF Report:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            Card(
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('Include Prices & Expected Income'),
                    subtitle: const Text('Shows item values and total cash expected from sold items.'),
                    value: showPrices,
                    onChanged: (v) => setState(() => showPrices = v ?? true),
                  ),
                  const Divider(height: 1),
                  CheckboxListTile(
                    title: const Text('Show Only Differences'),
                    subtitle: const Text('Hides balanced items. Shows only sold or surplus items.'),
                    value: showOnlyDifferences,
                    onChanged: (v) => setState(() => showOnlyDifferences = v ?? false),
                  ),
                  const Divider(height: 1),
                  CheckboxListTile(
                    title: const Text('Highlight Low Stock'),
                    subtitle: const Text('Marks items that are below the minimum limit.'),
                    value: showLowStockWarnings,
                    onChanged: (v) => setState(() => showLowStockWarnings = v ?? true),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: isGenerating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.picture_as_pdf),
                label: Text(isGenerating ? 'GENERATING PDF...' : 'GENERATE & SHARE PDF', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: isGenerating ? null : _generateAndSharePDF,
              ),
            ),
          ],
        ),
      ),
    );
  }
}