import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../theme/colors.dart';
import '../../widgets/profile_style_header.dart';

class NewsDetailScreen extends StatelessWidget {
  final Map<String, dynamic> newsItem;

  const NewsDetailScreen({super.key, required this.newsItem});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(newsItem['date'] as String);
    final isImportant = newsItem['isImportant'] as bool? ?? false;
    final image = newsItem['image'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Column(
        children: [
          ProfileStyleHeader(
            title: 'News Details',
            showBackButton: true,
            onBackTap: () => context.pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (image != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CachedNetworkImage(
                        imageUrl: image,
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(height: 250, color: Colors.grey[200]),
                        errorWidget: (context, url, error) => Container(
                          height: 250,
                          color: Colors.grey[200],
                          child: const Icon(Icons.error),
                        ),
                      ),
                    ),
                  if (image != null) const SizedBox(height: 24),
                  Row(
                    children: [
                      if (isImportant)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.error),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.priority_high,
                                size: 16,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'URGENT',
                                style: GoogleFonts.poppins(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          timeago.format(date),
                          style: GoogleFonts.roboto(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    newsItem['title'] ?? 'No Title',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    newsItem['content'] ?? '',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      height: 1.8,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
