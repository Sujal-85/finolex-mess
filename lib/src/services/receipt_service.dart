import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';

class ReceiptService {
  Future<void> generateAndDownloadReceipt(
    Transaction transaction,
    Map<String, dynamic> user,
  ) async {
    final pdf = pw.Document();

    // Load assets
    final logoImage = await rootBundle.load('assets/images/logo-circle.png');
    final signatureImage = await rootBundle.load(
      'assets/images/manager_signature.png',
    );

    final logo = pw.MemoryImage(logoImage.buffer.asUint8List());
    final signature = pw.MemoryImage(signatureImage.buffer.asUint8List());

    final font = await PdfGoogleFonts.poppinsRegular();
    final fontBold = await PdfGoogleFonts.poppinsBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Header
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Image(logo, width: 80, height: 80),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Prasanna Caterers',
                    style: pw.TextStyle(font: fontBold, fontSize: 24),
                  ),
                  pw.Text(
                    'Finolex Academy of Management and Technology',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Divider(),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Title
            pw.Center(
              child: pw.Text(
                'PAYMENT RECEIPT',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 20,
                  letterSpacing: 2,
                ),
              ),
            ),

            pw.SizedBox(height: 30),

            // Student Details
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Student Details',
                    style: pw.TextStyle(font: fontBold, fontSize: 14),
                  ),
                  pw.SizedBox(height: 10),
                  _buildInfoRow('Name', user['name'] ?? 'N/A', font, fontBold),
                  _buildInfoRow(
                    'Email',
                    user['email'] ?? 'N/A',
                    font,
                    fontBold,
                  ),
                  _buildInfoRow(
                    'Room No',
                    user['hostelDetails']?['roomNo'] ?? 'N/A',
                    font,
                    fontBold,
                  ),
                  _buildInfoRow(
                    'Hostel',
                    user['hostelDetails']?['hostelName'] ?? 'N/A',
                    font,
                    fontBold,
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Transaction Details
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Transaction Details',
                    style: pw.TextStyle(font: fontBold, fontSize: 14),
                  ),
                  pw.SizedBox(height: 10),
                  _buildInfoRow(
                    transaction.upiId != null ? 'UPI ID' : 'Transaction Ref',
                    transaction.upiId ?? transaction.id,
                    font,
                    fontBold,
                  ),
                  _buildInfoRow(
                    'Date',
                    DateFormat('dd MMM yyyy').format(transaction.date),
                    font,
                    fontBold,
                  ),
                  _buildInfoRow(
                    'Time',
                    DateFormat('hh:mm a').format(transaction.date),
                    font,
                    fontBold,
                  ),
                  _buildInfoRow(
                    'Payment Method',
                    transaction.paymentMethod,
                    font,
                    fontBold,
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Amount Paid',
                        style: pw.TextStyle(font: fontBold, fontSize: 16),
                      ),
                      pw.Text(
                        'INR ${transaction.amount.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 18,
                          color: PdfColors.green700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 40),

            // Signature Section (Moved from footer to avoid duplication on multi-page split)
            pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Image(signature, width: 100),
                        pw.SizedBox(height: 5),
                        pw.Container(
                          width: 120,
                          height: 1,
                          color: PdfColors.black,
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Mr. Sandeep Tambe',
                          style: pw.TextStyle(font: fontBold, fontSize: 14),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Manager Signature',
                          style: pw.TextStyle(font: font, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text(
                    'Thank you for your payment!',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    // Save and Share
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/receipt_${transaction.id}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Payment Receipt - ${transaction.id}');
  }

  pw.Widget _buildInfoRow(
    String label,
    String value,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: font, color: PdfColors.grey700),
          ),
          pw.Text(value, style: pw.TextStyle(font: fontBold)),
        ],
      ),
    );
  }
}
