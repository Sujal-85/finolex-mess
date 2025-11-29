import 'package:flutter/material.dart';
import '../animations/shimmer_effect.dart';
import '../../theme/neumorphism.dart';

class MenuSkeleton extends StatelessWidget {
  const MenuSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: NeumorphicStyle.cardDecoration(context),
          child: Row(
            children: [
              // Food Image Placeholder
              const ShimmerEffect.rectangular(
                height: 80,
                width: 80,
                borderRadius: 12,
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerEffect.rectangular(height: 18, width: 120),
                    SizedBox(height: 8),
                    ShimmerEffect.rectangular(height: 14, width: 80),
                    SizedBox(height: 12),
                    ShimmerEffect.rectangular(height: 20, width: 60),
                  ],
                ),
              ),
              // Add Button Placeholder
              const ShimmerEffect.circular(height: 32, width: 32),
            ],
          ),
        );
      },
    );
  }
}
