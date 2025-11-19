// ignore_for_file: unused_element, unused_field

import 'package:flutter/material.dart';
import 'package:silai/core/constants/app_colors.dart';
import 'package:silai/core/services/supabase_service.dart';
import 'package:silai/features/auth/presentation/screens/book_appoimnet_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class TailorDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> tailor;

  const TailorDetailsScreen({
    Key? key,
    required this.tailor,
  }) : super(key: key);

  @override
  State<TailorDetailsScreen> createState() => _TailorDetailsScreenState();
}

class _TailorDetailsScreenState extends State<TailorDetailsScreen>
    with TickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoadingReviews = true;

  late AnimationController _headerAnimController;
  late AnimationController _contentAnimController;
  late AnimationController _reviewsAnimController;
  late Animation<double> _headerSlideAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<double> _reviewsSlideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadReviews();
  }

  void _setupAnimations() {
    _headerAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _contentAnimController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _reviewsAnimController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _headerSlideAnimation = Tween<double>(begin: -100, end: 0).animate(
      CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOutCubic),
    );

    _contentFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentAnimController, curve: Curves.easeInOutQuad),
    );

    _reviewsSlideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _reviewsAnimController, curve: Curves.easeOutCubic),
    );

    _headerAnimController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentAnimController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _reviewsAnimController.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _contentAnimController.dispose();
    _reviewsAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await _supabaseService.getReviewsByTailorId(widget.tailor['id']);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingReviews = false);
      }
    }
  }

  Future<void> _showReviewDialog() async {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    final profile = await _supabaseService.getProfile(user.id);
    final clientName = profile?['full_name'] ?? 'Anonymous';

    int rating = 5;
    final reviewController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Write a Review'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rating', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setDialogState(() => rating = index + 1);
                      },
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                const Text('Review', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: reviewController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Write your review here...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reviewController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please write a review')),
                  );
                  return;
                }

                try {
                  await _supabaseService.addReview(
                    tailorId: widget.tailor['id'],
                    clientId: user.id,
                    clientName: clientName,
                    rating: rating,
                    reviewText: reviewController.text.trim(),
                  );
                  Navigator.pop(context, true);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to submit review: $e')),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadReviews();
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopName = widget.tailor['shop_name'] ?? 'Unknown Shop';
    final tailorName = widget.tailor['full_name'] ?? 'Unknown';
    final address = widget.tailor['address'] ?? 'Address not provided';
    final phone = widget.tailor['phone_number']?.toString() ?? 'N/A';
    final workingHours = widget.tailor['working_hours'] ?? 'N/A';
    final isVerified = widget.tailor['verified'] == true;
    final profileImage = widget.tailor['profile_image'];

    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      body: SafeArea(
        child: Column(
          children: [
            // Animated Header
            AnimatedBuilder(
              animation: _headerSlideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_headerSlideAnimation.value, 0),
                  child: child,
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.2),
                            AppColors.primary.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Tailor Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
              )
              ),
            ),

            // Content
            Expanded(
              child: AnimatedBuilder(
                animation: _contentFadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _contentFadeAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - _contentFadeAnimation.value)),
                      child: child,
                    ),
                  );
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Premium Tailor Card
                      _buildPremiumTailorCard(
                        shopName,
                        tailorName,
                        address,
                        phone,
                        workingHours,
                        isVerified,
                        profileImage,
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons with Glassmorphism
                      _buildActionButtons(),
                      const SizedBox(height: 28),

                      // Reviews Section
                      AnimatedBuilder(
                        animation: _reviewsSlideAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _reviewsSlideAnimation.value),
                            child: Opacity(
                              opacity: _reviewsAnimController.isAnimating
                                  ? 1 - (_reviewsSlideAnimation.value / 50)
                                  : 1,
                              child: child,
                            ),
                          );
                        },
                        child: _buildReviewsSection(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumTailorCard(
    String shopName,
    String tailorName,
    String address,
    String phone,
    String workingHours,
    bool isVerified,
    String? profileImage,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E2330).withOpacity(0.8),
            const Color(0xFF2A3342).withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Animated Profile Image
            ScaleTransition(
              scale: Tween<double>(begin: 0.7, end: 1).animate(
                CurvedAnimation(parent: _contentAnimController, curve: Curves.elasticOut),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.4),
                          AppColors.primary.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    backgroundImage: profileImage != null ? NetworkImage(profileImage) : null,
                    child: profileImage == null
                        ? Text(
                            shopName.isNotEmpty ? shopName[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Shop Name with Verification
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    shopName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (isVerified) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade400.withOpacity(0.3),
                          Colors.green.shade600.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.green.shade400,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: Colors.green.shade300,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade300,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              tailorName,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),

            // Info Rows with Icons
            _buildGlassInfoRow(Icons.location_on_rounded, address),
            const SizedBox(height: 14),
            _buildGlassInfoRow(Icons.phone_rounded, phone),
            const SizedBox(height: 14),
            _buildGlassInfoRow(Icons.schedule_rounded, workingHours),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassInfoRow(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildPremiumButton(
            label: 'Book Appointment',
            icon: Icons.calendar_today_rounded,
            isDark: true,
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      BookAppointmentScreen(tailor: widget.tailor),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: animation.drive(
                        Tween(begin: const Offset(1, 0), end: Offset.zero)
                            .chain(CurveTween(curve: Curves.easeInOutCubic)),
                      ),
                      child: child,
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPremiumButton(
            label: 'Call Now',
            icon: Icons.phone_rounded,
            isDark: false,
            onPressed: () {
              final phone = widget.tailor['phone_number']?.toString() ?? 'N/A';
              _makePhoneCall(phone);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumButton({
    required String label,
    required IconData icon,
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.12),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
            borderRadius: BorderRadius.circular(14),
            border: !isDark
                ? Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  )
                : null,
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isDark ? Colors.white : Colors.white70,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.white70,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E2330).withOpacity(0.8),
            const Color(0xFF2A3342).withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Reviews (${_reviews.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showReviewDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Write',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_isLoadingReviews)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_reviews.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: 52,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'No reviews yet.\nBe the first to review!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _reviews.asMap().entries.map((entry) {
                  int index = entry.key;
                  var review = entry.value;
                  final rating = int.tryParse('${review['rating'] ?? 0}') ??
                      (review['rating'] as int? ?? 0);

                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.1, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _reviewsAnimController,
                        curve: Interval(
                          0.1 * index,
                          0.1 + 0.3,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  review['client_name'] ?? 'Client',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                Row(
                                  children: List.generate(5, (idx) {
                                    return Icon(
                                      idx < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                      size: 16,
                                      color: Colors.amber[300],
                                    );
                                  }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              review['review_text'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[300],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber == 'N/A' || phoneNumber.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Phone number not available'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw 'Could not launch phone dialer';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to make call: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}