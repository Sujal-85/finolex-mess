import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../../blocs/menu/menu_bloc.dart';
import '../../blocs/menu/menu_event.dart';
import '../../blocs/menu/menu_state.dart';
import '../../theme/colors.dart';
import '../../theme/neumorphism.dart';
import '../../widgets/skeletons/menu_skeleton.dart';
import '../../widgets/profile_style_header.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          MenuBloc()..add(MenuLoadRequested(date: DateTime.now())),
      child: const _MenuView(),
    );
  }
}

class _MenuView extends StatelessWidget {
  const _MenuView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Column(
        children: [
          ProfileStyleHeader(
            title: 'Weekly Menu',
            showBackButton: true,
            onBackTap: () => context.go('/home'),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                ),
                onPressed: () {},
              ),
            ],
          ),
          const _DateSelector(),
          Expanded(
            child: BlocBuilder<MenuBloc, MenuState>(
              builder: (context, state) {
                if (state.status == MenuStatus.loading) {
                  return const MenuSkeleton();
                } else if (state.status == MenuStatus.failure) {
                  return Center(
                    child: Text(
                      state.errorMessage ?? 'Error loading menu',
                      style: TextStyle(color: AppColors.textSecondary(context)),
                    ),
                  );
                } else if (state.menuItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset(
                          'assets/lottie/Not found error.json',
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No menu available for this day',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Group items by mealType
                final groupedItems = <String, List<Map<String, dynamic>>>{};
                for (var item in state.menuItems) {
                  final mealType = (item['mealType'] as String? ?? 'Other')
                      .toLowerCase();
                  if (!groupedItems.containsKey(mealType)) {
                    groupedItems[mealType] = [];
                  }
                  groupedItems[mealType]!.add(item);
                }

                // Define order
                final order = ['breakfast', 'lunch', 'snacks', 'dinner'];
                final sortedKeys = groupedItems.keys.toList()
                  ..sort((a, b) {
                    final indexA = order.indexOf(a);
                    final indexB = order.indexOf(b);
                    return (indexA == -1 ? 999 : indexA).compareTo(
                      indexB == -1 ? 999 : indexB,
                    );
                  });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, sectionIndex) {
                    final sectionKey = sortedKeys[sectionIndex];
                    final items = groupedItems[sectionKey]!;
                    final title =
                        sectionKey[0].toUpperCase() + sectionKey.substring(1);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        ...items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _MenuItemCard(item: item),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekDates = List.generate(
      7,
      (index) => now.add(Duration(days: index)),
    );

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: weekDates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final date = weekDates[index];
          return BlocBuilder<MenuBloc, MenuState>(
            buildWhen: (previous, current) =>
                previous.selectedDate != current.selectedDate,
            builder: (context, state) {
              final isSelected = DateUtils.isSameDay(state.selectedDate, date);
              return GestureDetector(
                onTap: () {
                  context.read<MenuBloc>().add(MenuDaySelected(date));
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 60,
                  decoration: NeumorphicStyle.cardDecoration(
                    context,
                    borderRadius: 16,
                    isPressed: isSelected,
                    color: isSelected ? AppColors.primary : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(date),
                        style: GoogleFonts.roboto(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary(context),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('d').format(date),
                        style: GoogleFonts.poppins(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _MenuItemCard({required this.item});

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.circle,
                    size: 16,
                    color: item['isVeg'] ? Colors.green : Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                item['description'] ?? 'No description available',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: AppColors.textSecondary(context),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${item['price']}',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetails(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item['name'],
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ),
                Icon(
                  Icons.circle,
                  size: 10,
                  color: item['isVeg'] ? Colors.green : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item['description'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: AppColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${item['price']}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppColors.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: NeumorphicStyle.buttonDecoration(
                    context,
                    borderRadius: 20,
                    color: AppColors.accent,
                  ),
                  child: Text(
                    'Open',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
