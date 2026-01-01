import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';

class ReceiptService {
  Future<Uint8List> generateReceiptPdf(
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
    final fontItalic = await PdfGoogleFonts.playfairDisplayItalic();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Content
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 60,
                            height: 60,
                            child: pw.Image(logo),
                          ),
                          pw.SizedBox(width: 15),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Prasanna Caterers',
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 22,
                                  color: PdfColors.blue900,
                                ),
                              ),
                              pw.Text(
                                'Finolex Academy of Management and Technology',
                                style: pw.TextStyle(
                                  font: font,
                                  fontSize: 10,
                                  color: PdfColors.grey700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'RECEIPT',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 24,
                              color: PdfColors.grey400,
                              letterSpacing: 2,
                            ),
                          ),
                          pw.Text(
                            '#${(transaction.id.toLowerCase() == 'unknown' || transaction.id.isEmpty) ? DateTime.now().millisecondsSinceEpoch.toString().substring(5) : (transaction.id.length > 8 ? transaction.id.substring(0, 8) : transaction.id)}',
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 12,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 30),
                  pw.Divider(color: PdfColors.grey300),
                  pw.SizedBox(height: 30),

                  // Paid To / Bill To
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Received From',
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 10,
                              color: PdfColors.grey600,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            user['name'] ?? 'N/A',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 14,
                              color: PdfColors.black,
                            ),
                          ),
                          if (user['email'] != null)
                            pw.Text(
                              user['email'],
                              style: pw.TextStyle(
                                font: font,
                                fontSize: 10,
                                color: PdfColors.grey700,
                              ),
                            ),
                          if (user['hostelDetails'] != null) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              '${user['hostelDetails']['hostelName'] ?? ''} - ${user['hostelDetails']['roomNo'] ?? ''}',
                              style: pw.TextStyle(
                                font: font,
                                fontSize: 10,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Payment Details',
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 10,
                              color: PdfColors.grey600,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            DateFormat(
                              'dd MMM yyyy, hh:mm a',
                            ).format(transaction.date),
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 12,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.Text(
                            transaction.paymentMethod,
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 12,
                              color: PdfColors.grey800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 40),

                  // Amount Box
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 20,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey50,
                      borderRadius: pw.BorderRadius.circular(10),
                      border: pw.Border.all(color: PdfColors.grey200),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Total Amount Paid',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 14,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          'INR ${transaction.amount.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 24,
                            color: PdfColors.green700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 20),

                  // Transaction ID row
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10),
                    child: pw.Row(
                      children: [
                        pw.Text(
                          'Transaction Ref: ',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.Text(
                          transaction.upiId ?? transaction.id,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                            color: PdfColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.Spacer(),

                  // Signature
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Column(
                        children: [
                          pw.Image(signature, width: 100),
                          pw.SizedBox(height: 4),
                          pw.Container(
                            width: 140,
                            height: 1,
                            color: PdfColors.grey400,
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Mr. Sandeep Tambe',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 12,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.Text(
                            'Manager (Prasanna Caterers)',
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 10,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 30),
                  pw.Center(
                    child: pw.Text(
                      'This is a computer generated receipt.',
                      style: pw.TextStyle(
                        font: fontItalic,
                        fontSize: 10,
                        color: PdfColors.grey500,
                      ),
                    ),
                  ),
                ],
              ),

              // Paid Stamp
              pw.Positioned(
                bottom: 150,
                left: 40,
                child: pw.Transform.rotate(
                  angle: -0.2,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: const PdfColor(0.219, 0.556, 0.235, 0.7),
                        width: 3,
                      ),
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Text(
                      'PAID',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 35,
                        color: const PdfColor(0.219, 0.556, 0.235, 0.7),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<File> saveReceiptFile(
    Transaction transaction,
    Map<String, dynamic> user,
  ) async {
    final pdfBytes = await generateReceiptPdf(transaction, user);

    Directory? directory;
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }

      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory =
            await getExternalStorageKeys(); // Fallback if regular path fails
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    // Fallback if custom directory logic failed
    if (directory == null || !await directory.exists()) {
      directory = await getApplicationDocumentsDirectory();
    }

    // Create a specific folder
    final finolexDir = Directory('${directory.path}/Finolex Receipts');
    if (!await finolexDir.exists()) {
      await finolexDir.create(recursive: true);
    }

    String safeId = transaction.id;
    if (safeId.toLowerCase() == 'unknown' || safeId.isEmpty) {
      safeId = 'REF_${DateTime.now().millisecondsSinceEpoch}';
    }

    final file = File(
      '${finolexDir.path}/Receipt_${DateFormat('yyyyMMdd').format(transaction.date)}_$safeId.pdf',
    );
    await file.writeAsBytes(pdfBytes);
    return file;
  }

  Future<Directory?> getExternalStorageKeys() async {
    return await getExternalStorageDirectory();
  }

  Future<void> shareReceipt(
    Transaction transaction,
    Map<String, dynamic> user,
  ) async {
    final file = await saveReceiptFile(transaction, user);
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Payment Receipt from Finolex Mess');
  }
}
