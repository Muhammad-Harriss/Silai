import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:silai/core/constants/app_colors.dart';
import 'package:silai/core/constants/app_routes.dart';

class SelectRoleScreen extends StatefulWidget {
  const SelectRoleScreen({super.key});

  @override
  State<SelectRoleScreen> createState() => _SelectRoleScreenState();
}

class _SelectRoleScreenState extends State<SelectRoleScreen>
    with TickerProviderStateMixin {
  late AnimationController _titleController;
  late AnimationController _card1Controller;
  late AnimationController _card2Controller;

  late Animation<Offset> _titleSlide;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _card1Slide;
  late Animation<double> _card1Opacity;
  late Animation<Offset> _card2Slide;
  late Animation<double> _card2Opacity;

  @override
  void initState() {
    super.initState();

    _titleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _card1Controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _card2Controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _titleSlide = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOutCubic),
    );

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeIn),
    );

    _card1Slide = Tween<Offset>(begin: const Offset(-1.0, 0), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: _card1Controller, curve: Curves.easeOutCubic),
    );

    _card1Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _card1Controller, curve: Curves.easeIn),
    );

    _card2Slide = Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: _card2Controller, curve: Curves.easeOutCubic),
    );

    _card2Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _card2Controller, curve: Curves.easeIn),
    );

    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    await _titleController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _card1Controller.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _card2Controller.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _card1Controller.dispose();
    _card2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0F1419),
        title: Text(
          'Select Your Role',
          style: GoogleFonts.poppins(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Title
              SlideTransition(
                position: _titleSlide,
                child: FadeTransition(
                  opacity: _titleOpacity,
                  child: Text(
                    "Who are you?",
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 56),

              // Animated Tailor Card - Slides from left
              SlideTransition(
                position: _card1Slide,
                child: FadeTransition(
                  opacity: _card1Opacity,
                  child: AnimatedRoleCard(
                    title: "Tailor",
                    description: "Manage your clients and suits efficiently",
                    icon: Icons.cut_rounded,
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.tailorSignup);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Animated Client Card - Slides from right
              SlideTransition(
                position: _card2Slide,
                child: FadeTransition(
                  opacity: _card2Opacity,
                  child: AnimatedRoleCard(
                    title: "Client",
                    description: "Find the nearest tailors and book appointments",
                    icon: Icons.person_rounded,
                    color: const Color(0xFFF2A04D),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.clientSignup);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated Card Widget for Role Selection
class AnimatedRoleCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const AnimatedRoleCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<AnimatedRoleCard> createState() => _AnimatedRoleCardState();
}

class _AnimatedRoleCardState extends State<AnimatedRoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );

    _shadowAnimation = Tween<double>(begin: 12.0, end: 20.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onEnter(PointerEvent details) {
    _hoverController.forward();
    setState(() => _isHovered = true);
  }

  void _onExit(PointerEvent details) {
    _hoverController.reverse();
    setState(() => _isHovered = false);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedBuilder(
            animation: _shadowAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(_isHovered ? 0.3 : 0.15),
                      blurRadius: _shadowAnimation.value,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1E2330).withOpacity(0.9),
                        const Color(0xFF2A3342).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isHovered
                          ? widget.color.withOpacity(0.4)
                          : Colors.white.withOpacity(0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Animated Icon Container
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              widget.color.withOpacity(0.2),
                              widget.color.withOpacity(0.05),
                            ],
                          ),
                          border: Border.all(
                            color: widget.color.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: AnimatedBuilder(
                          animation: _hoverController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _hoverController.value * 0.2,
                              child: Icon(
                                widget.icon,
                                size: 44,
                                color: widget.color,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 18),

                      // Text Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.description,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.w400,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Animated Arrow
                      AnimatedBuilder(
                        animation: _hoverController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_hoverController.value * 6, 0),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: widget.color,
                              size: 16,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                )
              );
            },
          ),
        ),
      ),
    );
  }
}