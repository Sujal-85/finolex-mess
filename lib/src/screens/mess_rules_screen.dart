import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../theme/neumorphism.dart';
import '../widgets/profile_style_header.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

class MessRulesScreen extends StatelessWidget {
  const MessRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Column(
        children: [
          ProfileStyleHeader(
            title: 'Hostel Mess Rules',
            showBackButton: true,
            onBackTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, '💰 Mess Charges'),
                  _buildCard(
                    context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRichText(
                          'Monthly Charge:',
                          ' ₹3450',
                          isBold: true,
                        ),
                        const SizedBox(height: 8),
                        const Text('Includes:'),
                        _buildBullet('Breakfast (Tea/Coffee)'),
                        _buildBullet('Unlimited Lunch & Dinner'),
                        _buildBullet('Eggs / Paneer (1 day/week)'),
                        _buildBullet('Chicken (limited) / Feast (another day)'),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        _buildBullet('All taxes included.'),
                        _buildBullet(
                          'Mess is compulsory for all hostel students.',
                        ),
                        _buildBullet('Charges start from the day of joining.'),
                        _buildBullet(
                          'Payment due: 1st week of every month (Online).',
                        ),
                        _buildBullet('Always collect payment receipt.'),
                        _buildBullet(
                          'Must clear dues before leaving (end of semester).',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  _buildSectionTitle(context, '🔁 Mess Rebate Rules'),

                  _buildSubHeader(context, '📘 Academic Leave Rebate'),
                  _buildCard(
                    context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBullet(
                          'Allowed only if Department approves leave.',
                        ),
                        _buildBullet('Apply at least 1 day in advance.'),
                        _buildBullet(
                          'Written application through Hostel Warden.',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  _buildSubHeader(context, '🎉 Ganpati Holiday Rebate'),
                  _buildCard(
                    context,
                    child: Text(
                      'During Ganpati holidays, students will get 100% mess rebate (no mess charges).',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  _buildSubHeader(context, '⚠️ Important Decision Rule'),
                  _buildCard(
                    context,
                    child: Text(
                      'If a student is absent for a serious reason, the Warden or Principal will decide whether rebate is allowed.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  _buildSectionTitle(context, '📅 Absent Days Payment Table'),
                  Container(
                    decoration: NeumorphicStyle.cardDecoration(
                      context,
                      borderRadius: 15,
                    ),
                    child: Table(
                      border: TableBorder(
                        horizontalInside: BorderSide(
                          color: Colors.grey.withOpacity(0.2),
                        ),
                        verticalInside: BorderSide(
                          color: Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      columnWidths: const {
                        0: FlexColumnWidth(1.2),
                        1: FlexColumnWidth(1),
                      },
                      children: [
                        _buildTableRow(
                          context,
                          'Holidays Taken',
                          'You Pay For',
                          isHeader: true,
                        ),
                        _buildTableRow(context, '3 – 5 days', '1 day'),
                        _buildTableRow(context, '6 – 8 days', '2 days'),
                        _buildTableRow(context, '9 – 11 days', '3 days'),
                        _buildTableRow(context, '12 days or more', '4 days'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  _buildSectionTitle(context, '🏥 Medical Rebate Rules'),
                  _buildCard(
                    context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('To get rebate, immediately inform:'),
                        _buildBullet('Mess Manager/Contractor'),
                        _buildBullet('Hostel Warden (Boys/Girls)'),
                        const SizedBox(height: 8),
                        const Text('Submit Original Documents:'),
                        _buildBullet('Medical Certificate'),
                        _buildBullet('Medical Prescription'),
                        _buildBullet('Medical Bills'),
                        const SizedBox(height: 8),
                        Text(
                          'Note: Rebate calculation follows the holiday rebate table above.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, '📄 Rebate Rules Document'),
                  _buildCard(
                    context,
                    child: Column(
                      children: [
                        Text(
                          'For full details on mess charges and rebate policies, you can view the official document.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textSecondary(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: SizedBox(
                            width: 200,
                            child: _buildActionButton(
                              context,
                              icon: Icons.visibility_outlined,
                              label: 'Open PDF',
                              color: AppColors.primary,
                              onTap: () =>
                                  _handlePdfAction(context, isDownload: false),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePdfAction(
    BuildContext context, {
    required bool isDownload,
  }) async {
    try {
      final byteData = await rootBundle.load(
        'assets/Hostel Mess Charges and Rebate Rule_251216_195916.pdf',
      );
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/rebate_rules.pdf');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (isDownload) {
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Hostel Mess Rebate Rules');
      } else {
        // Share also serves as "Open With" which is standard for local files
        await Share.shareXFiles([XFile(file.path)], text: 'View Rebate Rules');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error handling PDF: $e')));
      }
    }
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration:
            NeumorphicStyle.buttonDecoration(
              context,
              borderRadius: 12,
              color: color,
            ).copyWith(
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSubHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary(context),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 15),
      child: DefaultTextStyle(
        style: GoogleFonts.poppins(
          color: AppColors.textSecondary(context),
          fontSize: 14,
        ),
        child: child,
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildRichText(String label, String value, {bool isBold = false}) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(
          color: Colors.black,
          fontSize: 14,
        ), // Default style placeholder
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(
    BuildContext context,
    String col1,
    String col2, {
    bool isHeader = false,
  }) {
    final style = GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
      color: isHeader ? AppColors.primary : AppColors.textSecondary(context),
    );

    return TableRow(
      decoration: isHeader
          ? BoxDecoration(color: AppColors.primary.withOpacity(0.1))
          : null,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(col1, style: style),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(col2, style: style),
        ),
      ],
    );
  }
}
