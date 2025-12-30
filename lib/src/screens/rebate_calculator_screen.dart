import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../theme/neumorphism.dart';
import '../widgets/profile_style_header.dart';

class RebateCalculatorScreen extends StatefulWidget {
  const RebateCalculatorScreen({super.key});

  @override
  State<RebateCalculatorScreen> createState() => _RebateCalculatorScreenState();
}

class _RebateCalculatorScreenState extends State<RebateCalculatorScreen> {
  final TextEditingController _daysController = TextEditingController();
  bool _isGanpatiHoliday = false;
  double _calculatedRebate = 0.0;
  int _payForDays = 0;
  final double _dailyRate = 3450 / 30; // ₹115.0

  @override
  void initState() {
    super.initState();
    _daysController.addListener(_calculateRebate);
  }

  @override
  void dispose() {
    _daysController.dispose();
    super.dispose();
  }

  void _calculateRebate() {
    final String text = _daysController.text;
    if (text.isEmpty) {
      setState(() {
        _calculatedRebate = 0.0;
        _payForDays = 0;
      });
      return;
    }

    final int? days = int.tryParse(text);
    if (days == null || days <= 0) {
      setState(() {
        _calculatedRebate = 0.0;
        _payForDays = 0;
      });
      return;
    }

    if (_isGanpatiHoliday) {
      setState(() {
        _payForDays = 0;
        _calculatedRebate = days * _dailyRate;
      });
      return;
    }

    int payDays = 0;
    if (days < 3) {
      payDays = days; // No rebate for less than 3 days
    } else if (days >= 3 && days <= 5) {
      payDays = 1;
    } else if (days >= 6 && days <= 8) {
      payDays = 2;
    } else if (days >= 9 && days <= 11) {
      payDays = 3;
    } else {
      payDays = 4;
    }

    setState(() {
      _payForDays = payDays;
      _calculatedRebate = (days - payDays) * _dailyRate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Column(
        children: [
          ProfileStyleHeader(
            title: 'Rebate Calculator',
            showBackButton: true,
            onBackTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputSection(),
                  const SizedBox(height: 32),
                  _buildResultCard(),
                  const SizedBox(height: 32),
                  _buildRulesSummary(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rebate Details',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 20),
          child: Column(
            children: [
              TextField(
                controller: _daysController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.poppins(
                  color: AppColors.textPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: 'Number of Absent Days',
                  labelStyle: GoogleFonts.poppins(
                    color: AppColors.textSecondaryLight,
                  ),
                  hintText: 'e.g. 5',
                  prefixIcon: const Icon(
                    Icons.calendar_today,
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.surface(context),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ganpati Holidays',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        Text(
                          '100% Rebate applies',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _isGanpatiHoliday,
                    onChanged: (value) {
                      setState(() {
                        _isGanpatiHoliday = value;
                        _calculateRebate();
                      });
                    },
                    activeTrackColor: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withAlpha((0.8 * 255).toInt()),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha((0.3 * 255).toInt()),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Estimated Rebate',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white.withAlpha((0.7 * 255).toInt()),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${_calculatedRebate.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, thickness: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildResultItem(
                label: 'Absent',
                value:
                    '${_daysController.text.isEmpty ? '0' : _daysController.text} Days',
              ),
              _buildResultItem(label: 'Pay For', value: '$_payForDays Days'),
              _buildResultItem(
                label: 'Rebate',
                value:
                    '${(int.tryParse(_daysController.text) ?? 0) - _payForDays} Days',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem({required String label, required String value}) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildRulesSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rebate Policy Table',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 15),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1.2),
                1: FlexColumnWidth(1),
              },
              children: [
                _buildTableRow('Absent Days', 'Pay For', isHeader: true),
                _buildTableRow('3 – 5 days', '1 day'),
                _buildTableRow('6 – 8 days', '2 days'),
                _buildTableRow('9 – 11 days', '3 days'),
                _buildTableRow('12+ days', '4 days'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '* Calculation based on monthly charge potential of ₹3450.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  TableRow _buildTableRow(String col1, String col2, {bool isHeader = false}) {
    final style = GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
      color: isHeader ? Colors.white : AppColors.textSecondary(context),
    );

    return TableRow(
      decoration: BoxDecoration(color: isHeader ? AppColors.primary : null),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Text(col1, style: style),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Text(col2, style: style),
        ),
      ],
    );
  }
}
