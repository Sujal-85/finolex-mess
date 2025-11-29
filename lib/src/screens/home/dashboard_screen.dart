import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/dashboard_bloc.dart';
import '../../blocs/dashboard_event.dart';
import '../../blocs/dashboard_state.dart';
import '../../theme/colors.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/dashboard/menu_card.dart';
import '../../widgets/dashboard/balance_card.dart';
import '../../widgets/dashboard/action_card.dart';
import '../../widgets/dashboard/announcement_card.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(DashboardLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is DashboardError) {
              return Center(child: Text('Error: ${state.message}'));
            }

            if (state is DashboardLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<DashboardBloc>().add(
                    DashboardRefreshRequested(),
                  );
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      DashboardHeader(
                        studentName: 'Student', // Replace with dynamic data
                        hostelBlock: 'Block A',
                        roomNumber: '101',
                        notificationCount: 3,
                        onNotificationTap: () => context.push('/notifications'),
                        onProfileTap: () => context.push('/profile'),
                      ),

                      const SizedBox(height: 20),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            // Menu Card
                            MenuCard(
                              onViewFullMenu: () => context.push('/menu'),
                            ),

                            const SizedBox(height: 24),

                            // Balance Card
                            BalanceCard(
                              balance: 1500.00, // Replace with dynamic data
                              onAddMoney: () => context.push('/payment'),
                            ),

                            const SizedBox(height: 24),

                            // Action Grid
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.1,
                                  children: [
                                    ActionCard(
                                      title: 'Payments',
                                      subtitle: 'History & Dues',
                                      icon: Icons.history,
                                      onTap: () =>
                                          context.push('/transactions'),
                                    ),
                                    ActionCard(
                                      title: 'Complaints',
                                      subtitle: 'Support & Help',
                                      icon: Icons.chat_bubble_outline,
                                      onTap: () => context.push('/complaints'),
                                      iconColor: AppColors.accent,
                                    ),
                                    ActionCard(
                                      title: 'Feedback',
                                      subtitle: 'Rate Meals',
                                      icon: Icons.star_outline,
                                      onTap: () => context.push('/feedback'),
                                      iconColor: Colors.amber,
                                    ),
                                    ActionCard(
                                      title: 'Settings',
                                      subtitle: 'App Preferences',
                                      icon: Icons.settings_outlined,
                                      onTap: () => context.push('/settings'),
                                      iconColor: Colors.grey,
                                    ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 24),

                            // Announcements
                            AnnouncementCard(
                              announcement: state.latestAnnouncement,
                              onTap: () => context.push('/news'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () {
          // Quick Pay
        },
        backgroundColor: AppColors.primary,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 32,
                ),
                Text(
                  'Pay',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
