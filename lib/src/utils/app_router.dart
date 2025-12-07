import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/menu/menu_screen.dart';
import '../screens/history_screen.dart';
import '../screens/news/news_feed_screen.dart';
import '../screens/news/news_detail_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/student_registration_screen.dart';
import '../screens/payment_screen.dart';
import '../screens/complaints_screen.dart';
import '../screens/receipt_preview_screen.dart';
import '../screens/feedback_screen.dart';
import '../screens/notification_center_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/about_screen.dart';
import '../screens/emergency_support_screen.dart';
import '../screens/all_receipts_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/change_password_screen.dart';
import '../screens/profile/id_card_screen.dart';
import '../screens/settings/privacy_policy_screen.dart';
import '../screens/settings/terms_screen.dart';
import '../widgets/bottom_nav_bar.dart';
import '../theme/animations.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => AppAnimations.transitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => AppAnimations.transitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => AppAnimations.transitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => AppAnimations.transitionPage(
          key: state.pageKey,
          child: const StudentRegistrationScreen(),
        ),
      ),
      GoRoute(
        path: '/payment',
        pageBuilder: (context, state) => AppAnimations.transitionPage(
          key: state.pageKey,
          child: const PaymentScreen(),
        ),
      ),
      GoRoute(
        path: '/complaints',
        pageBuilder: (context, state) => AppAnimations.transitionPage(
          key: state.pageKey,
          child: const ComplaintsScreen(),
        ),
      ),
      GoRoute(
        path: '/receipt-preview',
        pageBuilder: (context, state) => AppAnimations.transitionPage(
          key: state.pageKey,
          child: ReceiptPreviewScreen(
            receiptData: state.extra as Map<String, dynamic>? ?? {},
          ),
        ),
      ),

      // StatefulShellRoute for Bottom Navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: BottomNavBar(navigationShell: navigationShell),
          );
        },
        branches: [
          // Home Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => AppAnimations.transitionPage(
                  key: state.pageKey,
                  child: const DashboardScreen(),
                ),
              ),
            ],
          ),

          // Menu Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/menu',
                pageBuilder: (context, state) => AppAnimations.transitionPage(
                  key: state.pageKey,
                  child: const MenuScreen(),
                ),
              ),
            ],
          ),

          // History Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                pageBuilder: (context, state) => AppAnimations.transitionPage(
                  key: state.pageKey,
                  child: const HistoryScreen(),
                ),
              ),
            ],
          ),

          // News Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/news',
                pageBuilder: (context, state) => AppAnimations.transitionPage(
                  key: state.pageKey,
                  child: const NewsFeedScreen(),
                ),
                routes: [
                  GoRoute(
                    path: ':id',
                    pageBuilder: (context, state) {
                      final newsItem = state.extra as Map<String, dynamic>;
                      return AppAnimations.transitionPage(
                        key: state.pageKey,
                        child: NewsDetailScreen(newsItem: newsItem),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Profile Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => AppAnimations.transitionPage(
                  key: state.pageKey,
                  child: const ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/feedback',
        pageBuilder: (context, state) => AppAnimations.transitionPage(
          key: state.pageKey,
          child: const FeedbackScreen(),
        ),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => AppAnimations.transitionPage(
          key: state.pageKey,
          child: const NotificationCenterScreen(),
        ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => AppAnimations.transitionPage(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/about',
        pageBuilder: (context, state) => AppAnimations.transitionPage(
          key: state.pageKey,
          child: const AboutScreen(),
        ),
      ),
      GoRoute(
        path: '/emergency',
        pageBuilder: (context, state) => AppAnimations.transitionPage(
          key: state.pageKey,
          child: const EmergencySupportScreen(),
        ),
      ),
      GoRoute(
        path: '/all-receipts',
        pageBuilder: (context, state) => AppAnimations.transitionPage(
          key: state.pageKey,
          child: const AllReceiptsScreen(),
        ),
      ),
      GoRoute(
        path: '/edit-profile',
        pageBuilder: (context, state) => AppAnimations.transitionPage(
          key: state.pageKey,
          child: const EditProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/change-password',
        pageBuilder: (context, state) => AppAnimations.transitionPage(
          key: state.pageKey,
          child: const ChangePasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/id-card',
        pageBuilder: (context, state) => AppAnimations.transitionPage(
          key: state.pageKey,
          child: const IdCardScreen(),
        ),
      ),
      GoRoute(
        path: '/privacy',
        pageBuilder: (context, state) => AppAnimations.transitionPage(
          key: state.pageKey,
          child: const PrivacyPolicyScreen(),
        ),
      ),
      GoRoute(
        path: '/terms',
        pageBuilder: (context, state) => AppAnimations.transitionPage(
          key: state.pageKey,
          child: const TermsScreen(),
        ),
      ),
    ],
  );
}
