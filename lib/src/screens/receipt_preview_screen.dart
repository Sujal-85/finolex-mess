import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import '../models/transaction.dart';
import '../services/receipt_service.dart';
import '../services/auth_service.dart';
import '../theme/colors.dart';

class ReceiptPreviewScreen extends StatefulWidget {
  final Transaction transaction;

  const ReceiptPreviewScreen({super.key, required this.transaction});

  @override
  State<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends State<ReceiptPreviewScreen> {
  final ReceiptService _receiptService = ReceiptService();
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getUser();
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // For use in BottomSheet
      appBar: AppBar(
        title: Text(
          'Receipt Preview',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
        ),
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        leading: CloseButton(color: AppColors.textPrimary(context)),
      ),
      body: _user == null
          ? const Center(child: CircularProgressIndicator())
          : PdfPreview(
              build: (format) => _receiptService.generateReceiptPdf(
                widget.transaction,
                _user!,
              ),
              allowPrinting: true,
              allowSharing: true,
              canChangeOrientation: false,
              canChangePageFormat: false,
              maxPageWidth: 700,
              actions: [
                // Custom actions can be added here if needed, but standard print/share are usually enough
              ],
            ),
    );
  }
}
