import 'package:flutter/material.dart';
import '../animations/shimmer_effect.dart';
import '../../theme/neumorphism.dart';

class NewsSkeleton extends StatelessWidget {
  const NewsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: NeumorphicStyle.cardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Badge
              const ShimmerEffect.rectangular(
                height: 24,
                width: 80,
                borderRadius: 20,
              ),
              const SizedBox(height: 12),
              // Title
              const ShimmerEffect.rectangular(
                height: 20,
                width: double.infinity,
              ),
              const SizedBox(height: 8),
              const ShimmerEffect.rectangular(height: 20, width: 200),
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
        );
      },
    );
  }
}
