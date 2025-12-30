import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/colors.dart';
import '../../theme/neumorphism.dart';

class FoodQuoteCard extends StatefulWidget {
  const FoodQuoteCard({super.key});

  @override
  State<FoodQuoteCard> createState() => _FoodQuoteCardState();
}

class _FoodQuoteCardState extends State<FoodQuoteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isLiked = false;
  bool _showPopper = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final List<Map<String, String>> _quotes = [
    {
      'quote': 'People who love to eat are always the best people.',
      'author': 'Julia Child',
    },
    {
      'quote': 'First we eat, then we do everything else.',
      'author': 'M.F.K. Fisher',
    },
    {
      'quote': 'Life is uncertain. Eat dessert first.',
      'author': 'Ernestine Ulmer',
    },
    {'quote': 'Cooking is love made visible.', 'author': 'Unknown'},
    {
      'quote': 'Good food is the foundation of genuine happiness.',
      'author': 'Auguste Escoffier',
    },
    {
      'quote':
          'One cannot think well, love well, sleep well, if one has not dined well.',
      'author': 'Virginia Woolf',
    },
    {
      'quote': 'Let food be thy medicine and medicine be thy food.',
      'author': 'Hippocrates',
    },
    {
      'quote':
          'The only thing I like better than talking about food is eating.',
      'author': 'John Walters',
    },
    {
      'quote': 'Laughter is brightest where food is best.',
      'author': 'Irish Proverb',
    },
    {
      'quote': 'Food is symbolic of love when words are inadequate.',
      'author': 'Alan D. Wolfelt',
    },
    {
      'quote': 'There is no sincere love than the love of food.',
      'author': 'George Bernard Shaw',
    },
    {
      'quote':
          'A recipe has no soul. You as the cook must bring soul to the recipe.',
      'author': 'Thomas Keller',
    },
    {
      'quote': 'To eat is a necessity, but to eat intelligently is an art.',
      'author': 'François de La Rochefoucauld',
    },
    {
      'quote':
          'We all eat, and it would be a sad waste of opportunity to eat badly.',
      'author': 'Anna Thomas',
    },
    {
      'quote':
          'If you really want to make a friend, go to someone\'s house and eat with him... the people who give you their food give you their heart.',
      'author': 'Cesar Chavez',
    },
    {
      'quote': 'Everything you see I owe to spaghetti.',
      'author': 'Sophia Loren',
    },
    {
      'quote': 'Food is our common ground, a universal experience.',
      'author': 'James Beard',
    },
    {'quote': 'Count memories, not calories.', 'author': 'Unknown'},
    {'quote': 'Happiness is homemade.', 'author': 'Unknown'},
    {'quote': 'Waffles are just pancakes with abs.', 'author': 'Unknown'},
    {
      'quote':
          'You can\'t buy happiness, but you can buy ice cream and that is pretty much the same thing.',
      'author': 'Unknown',
    },
    {
      'quote':
          'Meals make the society, hold the fabric together in lots of ways.',
      'author': 'Anthony Bourdain',
    },
    {
      'quote': 'Tell me what you eat, and I will tell you what you are.',
      'author': 'Jean Anthelme Brillat-Savarin',
    },
    {
      'quote':
          'Food, to me, is always about cooking and eating with those you love and care for.',
      'author': 'David Chang',
    },
    {'quote': 'The secret ingredient is always love.', 'author': 'Unknown'},
    {'quote': 'Good food ends with good talk.', 'author': 'Geoffrey Neighbors'},
    {
      'quote':
          'Popcorn for breakfast! Why not? It\'s a grain. It\'s like, like, grits, but with high self-esteem.',
      'author': 'James Patterson',
    },
    {
      'quote':
          'Vegetables are a must on a diet. I suggest carrot cake, zucchini bread, and pumpkin pie.',
      'author': 'Jim Davis',
    },
    {
      'quote': 'I am on a seafood diet. I see food and I eat it.',
      'author': 'Unknown',
    },
    {
      'quote': 'Life is too short for self-hatred and celery sticks.',
      'author': 'Marilyn Wann',
    },
    {
      'quote': 'My weaknesses have always been food and men — in that order.',
      'author': 'Dolly Parton',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Select quote based on day of month
    final int day = DateTime.now().day;
    final int quoteIndex = (day - 1) % _quotes.length;
    final Map<String, String> currentQuote = _quotes[quoteIndex];

    return Container(
      width: double.infinity,
      decoration: NeumorphicStyle.cardDecoration(context, borderRadius: 24),
      child: Stack(
        children: [
          // Decorative Background
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.format_quote_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Quote of the Day',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '"${currentQuote['quote']}"',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '- ${currentQuote['author']}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_showPopper)
                          Lottie.asset(
                            'assets/lottie/party propper.json',
                            controller: _controller,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            repeat: false,
                            onLoaded: (composition) {
                              _controller.duration = composition.duration;
                              _controller.forward().then((value) {
                                setState(() {
                                  _showPopper = false;
                                  _controller.reset();
                                });
                              });
                            },
                          ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isLiked = !_isLiked;
                              if (_isLiked) {
                                _showPopper = true;
                              }
                            });
                          },
                          icon: Icon(
                            _isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: _isLiked
                                ? Colors.red
                                : AppColors.textSecondaryLight,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {
                        Share.share(
                          '"${currentQuote['quote']}" - ${currentQuote['author']}\n\nShared via Finolex Canteen App',
                        );
                      },
                      icon: Icon(
                        Icons.share_rounded,
                        color: AppColors.textSecondaryLight,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
