import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/receipt_model.dart';

class ReceiptService extends ChangeNotifier {
  List<Receipt> _receipts = [];
  List<Receipt> _filteredReceipts = [];
  Set<String> _selectedReceiptIds = {};
  String _searchQuery = '';
  String _selectedFilter = 'All';

  List<Receipt> get receipts => _filteredReceipts;
  Set<String> get selectedReceiptIds => _selectedReceiptIds;
  bool get hasSelectedReceipts => _selectedReceiptIds.isNotEmpty;
  int get selectedCount => _selectedReceiptIds.length;
  String get selectedFilter => _selectedFilter;

  ReceiptService() {
    _loadSampleReceipts();
    _applyFilters();
  }

  void _loadSampleReceipts() {
    _receipts = [];
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setSelectedFilter(String filter) {
    _selectedFilter = filter;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredReceipts = _receipts.where((receipt) {
      // Apply search filter
      bool matchesSearch =
          _searchQuery.isEmpty ||
          receipt.transactionId.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          receipt.amount.toString().contains(_searchQuery) ||
          receipt.dateTime.toString().contains(_searchQuery);

      // Apply category filter
      bool matchesFilter =
          _selectedFilter == 'All' ||
          (_selectedFilter == 'This Month' &&
              receipt.dateTime.isAfter(
                DateTime.now().subtract(const Duration(days: 30)),
              )) ||
          (_selectedFilter == 'Last Month' &&
              receipt.dateTime.isAfter(
                DateTime.now().subtract(const Duration(days: 60)),
              ) &&
              receipt.dateTime.isBefore(
                DateTime.now().subtract(const Duration(days: 30)),
              )) ||
          receipt.paymentMethod == _selectedFilter ||
          receipt.status == _selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();

    notifyListeners();
  }

  void toggleReceiptSelection(String id) {
    if (_selectedReceiptIds.contains(id)) {
      _selectedReceiptIds.remove(id);
    } else {
      _selectedReceiptIds.add(id);
    }
    notifyListeners();
  }

  void selectAllReceipts() {
    _selectedReceiptIds = _filteredReceipts
        .map((receipt) => receipt.id)
        .toSet();
    notifyListeners();
  }

  void clearSelection() {
    _selectedReceiptIds.clear();
    notifyListeners();
  }

  List<Receipt> getSelectedReceipts() {
    return _receipts
        .where((receipt) => _selectedReceiptIds.contains(receipt.id))
        .toList();
  }

  Future<void> downloadReceipt(String id) async {
    final receipt = _receipts.firstWhere((r) => r.id == id);
    await _generateAndDownloadPdf([receipt]);
  }

  Future<void> downloadSelectedReceipts() async {
    final selectedReceipts = getSelectedReceipts();
    if (selectedReceipts.isEmpty) return;
    await _generateAndDownloadPdf(selectedReceipts);
  }

  Future<void> shareReceipt(String id) async {
    final receipt = _receipts.firstWhere((r) => r.id == id);
    await _generateAndDownloadPdf([receipt], isShare: true);
  }

  Future<void> shareSelectedReceipts() async {
    final selectedReceipts = getSelectedReceipts();
    if (selectedReceipts.isEmpty) return;
    await _generateAndDownloadPdf(selectedReceipts, isShare: true);
  }

  Future<void> _generateAndDownloadPdf(
    List<Receipt> receipts, {
    bool isShare = false,
  }) async {
    final doc = pw.Document();

    for (final receipt in receipts) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'FAMT Canteen',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Payment Receipt',
                        style: const pw.TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 20),
                _buildPdfRow('Transaction ID', receipt.transactionId),
                _buildPdfRow('Date', receipt.dateTime.toString()),
                _buildPdfRow(
                  'Amount',
                  'INR ${receipt.amount.toStringAsFixed(2)}',
                ),
                _buildPdfRow('Payment Method', receipt.paymentMethod),
                _buildPdfRow('Status', receipt.status),
                pw.SizedBox(height: 40),
                pw.Divider(),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text(
                    'Thank you for your business!',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    if (isShare) {
      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'receipts.pdf',
      );
    } else {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'FAMT_Receipts',
      );
    }
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(value),
        ],
      ),
    );
  }
}
