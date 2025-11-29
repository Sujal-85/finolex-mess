import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/colors.dart';
import '../neumorphic_card.dart';

class MenuCard extends StatelessWidget {
  final VoidCallback onViewFullMenu;

  const MenuCard({super.key, required this.onViewFullMenu});

  @override
  Widget build(BuildContext context) {
    return NeumorphicCard(
      onTap: onViewFullMenu,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Menu",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              Icon(Icons.restaurant_menu, color: AppColors.accent, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          _buildMenuItem(
            context,
            'Breakfast',
            'Idli Sambar',
            Icons.breakfast_dining,
          ),
          const SizedBox(height: 8),
          _buildMenuItem(context, 'Lunch', 'Veg Thali', Icons.lunch_dining),
          const SizedBox(height: 8),
          _buildMenuItem(
            context,
            'Dinner',
            'Paneer Butter Masala',
            Icons.dinner_dining,
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'View Full Menu',
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String meal,
    String item,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondaryLight),
        const SizedBox(width: 8),
        Text(
          meal,
          style: GoogleFonts.roboto(
            fontSize: 12,
            color: AppColors.textSecondaryLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          item,
          style: GoogleFonts.roboto(
            fontSize: 12,
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
