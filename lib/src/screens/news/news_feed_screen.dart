import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../blocs/news/news_bloc.dart';
import '../../blocs/news/news_event.dart';
import '../../blocs/news/news_state.dart';
import '../../theme/colors.dart';
import '../../theme/neumorphism.dart';
import '../../widgets/famt_app_bar.dart';
import '../../widgets/skeletons/news_skeleton_pro.dart';

class NewsFeedScreen extends StatelessWidget {
  const NewsFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NewsBloc()..add(NewsLoadRequested()),
      child: const _NewsFeedView(),
    );
  }
}

class _NewsFeedView extends StatefulWidget {
  const _NewsFeedView();

  @override
  State<_NewsFeedView> createState() => _NewsFeedViewState();
}

class _NewsFeedViewState extends State<_NewsFeedView>
    with TickerProviderStateMixin {
  late final AnimationController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: FamtAppBar(
        title: 'College News',
        showProfile: true,
        onNotificationTap: () {},
        onProfileTap: () {},
      ),
      body: BlocBuilder<NewsBloc, NewsState>(
        builder: (context, state) {
          if (state.status == NewsStatus.loading && state.newsItems.isEmpty) {
            return const NewsSkeletonPro(); // Your pro skeleton
          }

          if (state.status == NewsStatus.failure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset('assets/lottie/no_connection.json', height: 180),
                  const SizedBox(height: 24),
                  Text(
                    'Oops! Something went wrong',
                    style: GoogleFonts.poppins(fontSize: 18),
                  ),
                  Text(
                    state.errorMessage ?? '',
                    style: GoogleFonts.roboto(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<NewsBloc>().add(NewsRefreshRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state.newsItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset('assets/lottie/empty_news.json', height: 200),
                  const SizedBox(height: 24),
                  Text(
                    'No news yet',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Check back later!',
                    style: GoogleFonts.roboto(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _refreshController.reset();
              context.read<NewsBloc>().add(NewsRefreshRequested());
              await Future.delayed(const Duration(milliseconds: 1200));
            },
            displacement: 80,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: state.newsItems.length,
              itemBuilder: (context, index) {
                final item = state.newsItems[index];
                final isRead = false; // You can track read status later

                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: NewsCardPro(item: item, isRead: isRead, index: index),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// PRO NEWS CARD — The Star of the Show
class NewsCardPro extends StatefulWidget {
  final Map<String, dynamic> item;
  final bool isRead;
  final int index;

  const NewsCardPro({
    super.key,
    required this.item,
    required this.isRead,
    required this.index,
  });

  @override
  State<NewsCardPro> createState() => _NewsCardProState();
}

class _NewsCardProState extends State<NewsCardPro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(widget.item['date'] as String);
    final isImportant = widget.item['isImportant'] as bool? ?? false;
    final hasImage = widget.item['image'] != null;

    return Hero(
      tag: 'news_${widget.item['id']}',
      child: GestureDetector(
        onTap: () {
          // Navigate to detail with Hero
          context.push('/news/${widget.item['id']}');
        },
        child: Container(
          decoration: NeumorphicStyle.cardDecoration(
            context,
            borderRadius: 28,
            shadowIntensity: widget.isRead ? 0.08 : 0.2,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image with gradient overlay
                    if (hasImage)
                      Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl: widget.item['image'],
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: Colors.grey[200]),
                          ),
                          Container(
                            height: 180,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                    Padding(
                      padding: EdgeInsets.all(hasImage ? 20 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Priority + Date Row
                          Row(
                            children: [
                              // Priority Badge
                              if (isImportant)
                                AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withOpacity(
                                          0.15 + _pulseController.value * 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppColors.error.withOpacity(
                                            0.4,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.priority_high,
                                            color: AppColors.error,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'URGENT',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              else
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
                                      fontSize: 12,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                              const Spacer(),

                              // Unread dot
                              if (!widget.isRead)
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Title
                          Text(
                            widget.item['title'],
                            style: GoogleFonts.poppins(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                              color: AppColors.textPrimary(context),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Content Preview
                          Text(
                            widget.item['content'],
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              fontSize: 14.5,
                              height: 1.6,
                              color: AppColors.textSecondaryLight.withOpacity(
                                0.9,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Read more hint
                          Row(
                            children: [
                              Text(
                                'Tap to read more',
                                style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  color: AppColors.primary.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: AppColors.primary.withOpacity(0.7),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
