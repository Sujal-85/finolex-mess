import 'package:flutter/material.dart';
import '../animations/shimmer_effect.dart';
import '../../theme/neumorphism.dart';

class NewsSkeletonPro extends StatelessWidget {
  const NewsSkeletonPro({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        return Container(
          decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 28),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Placeholder
                const ShimmerEffect.rectangular(
                  height: 180,
                  width: double.infinity,
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date/Priority Row
                      Row(
                        children: [
                          const ShimmerEffect.rectangular(
                            height: 24,
                            width: 80,
                            borderRadius: 20,
                          ),
                          const Spacer(),
                          const ShimmerEffect.circular(height: 10, width: 10),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Title
                      const ShimmerEffect.rectangular(
                        height: 24,
                        width: double.infinity,
                      ),
                      const SizedBox(height: 8),
                      const ShimmerEffect.rectangular(height: 24, width: 200),
                      const SizedBox(height: 16),
                      // Content Lines
                      const ShimmerEffect.rectangular(
                        height: 14,
                        width: double.infinity,
                      ),
                      const SizedBox(height: 4),
                      const ShimmerEffect.rectangular(
                        height: 14,
                        width: double.infinity,
                      ),
                      const SizedBox(height: 4),
                      const ShimmerEffect.rectangular(height: 14, width: 150),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
