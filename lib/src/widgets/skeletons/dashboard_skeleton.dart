import 'package:flutter/material.dart';
import '../animations/shimmer_effect.dart';
import '../../theme/neumorphism.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Card Skeleton
          Container(
            height: 120,
            width: double.infinity,
            decoration: NeumorphicStyle.cardDecoration(context),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerEffect.rectangular(height: 20, width: 100),
                const SizedBox(height: 16),
                const ShimmerEffect.rectangular(height: 40, width: 150),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick Actions Grid Skeleton
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Container(
                decoration: NeumorphicStyle.cardDecoration(context),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const ShimmerEffect.rectangular(
                      height: 40,
                      width: 40,
                      borderRadius: 12,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        ShimmerEffect.rectangular(height: 24, width: 80),
                        SizedBox(height: 8),
                        ShimmerEffect.rectangular(height: 16, width: 60),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Announcements Skeleton
          const ShimmerEffect.rectangular(
            height: 24,
            width: 150,
          ), // Section Title
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return Container(
                height: 80,
                decoration: NeumorphicStyle.cardDecoration(context),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const ShimmerEffect.rectangular(
                      height: 48,
                      width: 48,
                      borderRadius: 8,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          ShimmerEffect.rectangular(
                            height: 16,
                            width: double.infinity,
                          ),
                          SizedBox(height: 8),
                          ShimmerEffect.rectangular(height: 12, width: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
