import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:silai/core/constants/app_colors.dart';
import 'package:silai/core/constants/app_routes.dart';
import 'package:silai/core/services/supabase_client.dart';
import 'package:silai/core/services/supabase_service.dart';

class TailorDashboardScreen extends StatefulWidget {
  const TailorDashboardScreen({Key? key}) : super(key: key);

  @override
  State<TailorDashboardScreen> createState() => _TailorDashboardScreenState();
}

class _TailorDashboardScreenState extends State<TailorDashboardScreen>
    with TickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();

  String _shopName = 'Shop Name';
  String _tailorName = 'Tailor Name';
  int _totalClients = 0;
  int _activeJobs = 0;
  double _pendingPayments = 0;
  int _newBookings = 0;
  bool _hasRecentBooking = false;
  bool _isLoading = true;

  List<Map<String, dynamic>> _activeGarments = [];
  List<Map<String, dynamic>> _pendingGarments = [];
  Map<String, dynamic>? _recentBooking;

  StreamSubscription<dynamic>? _bookingsSub;

  late AnimationController _headerController;
  late AnimationController _statsController;
  late AnimationController _contentController;

  late Animation<Offset> _headerSlide;
  late Animation<double> _headerOpacity;
  late Animation<double> _statsScale;
  late Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadDashboardData();
    _subscribeToBookingsRealtime();
  }

  void _setupAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _statsController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _headerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeIn),
    );

    _statsScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _statsController, curve: Curves.elasticOut),
    );

    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeIn),
    );

    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    await _headerController.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _statsController.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _contentController.forward();
  }

  @override
  void dispose() {
    _bookingsSub?.cancel();
    _headerController.dispose();
    _statsController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  double _toDoubleSafe(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _supabaseService.currentUser;
      if (user == null) return;

      final profile = await _supabaseService.getProfile(user.id);
      final clientsCount = await _supabaseService.getClientsCount(user.id);
      final garments = await _supabaseService.getGarmentsByTailorId(user.id);

      double totalPending = 0;
      final activeGarments = <Map<String, dynamic>>[];
      final pendingGarments = <Map<String, dynamic>>[];

      for (var g in garments) {
        final price = _toDoubleSafe(g['price']);
        final paid = _toDoubleSafe(g['paid_amount']);
        final remaining = (price - paid);

        final garmentWithRemaining = Map<String, dynamic>.from(g);
        garmentWithRemaining['remaining_amount'] = remaining;

        if (remaining > 0) {
          totalPending += remaining;
          pendingGarments.add(garmentWithRemaining);
        }

        final status = (g['status'] ?? '').toString();
        if (status == 'in_progress') {
          activeGarments.add(garmentWithRemaining);
        }
      }

      final activeCount =
          await _supabase_service_safe_getActiveOrdersCount(user.id);
      await _loadBookingsForDashboard();

      if (mounted) {
        setState(() {
          _shopName = profile?['shop_name'] ?? 'Shop Name';
          _tailorName = profile?['full_name'] ?? 'Tailor Name';
          _totalClients = clientsCount;
          _activeJobs = activeCount;
          _pendingPayments = totalPending;
          _activeGarments = activeGarments;
          _pendingGarments = pendingGarments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load dashboard: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<int> _supabase_service_safe_getActiveOrdersCount(
      String tailorId) async {
    try {
      return await _supabaseService.getActiveOrdersCount(tailorId);
    } catch (_) {
      return _activeGarments.length;
    }
  }

  Future<void> _signOut() async {
    try {
      await _supabaseService.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.welcome,
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sign out: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _loadBookingsForDashboard() async {
    try {
      final raw = await _supabaseService.getBookingsForTailor();
      final List<Map<String, dynamic>> bookings =
          raw.map((e) => Map<String, dynamic>.from(e)).toList();

      bookings.sort((a, b) {
        final aStr = a['created_at']?.toString() ?? '';
        final bStr = b['created_at']?.toString() ?? '';
        try {
          final aDt = DateTime.parse(aStr);
          final bDt = DateTime.parse(bStr);
          return bDt.compareTo(aDt);
        } catch (_) {
          return 0;
        }
      });

      final now = DateTime.now().toUtc();
      int newCount = 0;
      Map<String, dynamic>? recent;

      for (var b in bookings) {
        final status = b['status']?.toString().toLowerCase() ?? 'pending';
        final createdStr = b['created_at']?.toString() ?? '';
        DateTime? created;
        try {
          created = DateTime.parse(createdStr).toUtc();
        } catch (_) {
          created = null;
        }

        if (status == 'pending') {
          if (created == null) {
            newCount++;
          } else {
            final diff = now.difference(created);
            if (diff.inHours <= 24) newCount++;
          }
        }

        if (recent == null) recent = b;
      }

      if (mounted) {
        setState(() {
          _newBookings = newCount;
          _hasRecentBooking = (recent != null);
          _recentBooking = recent;
        });
      }
    } catch (e) {
      // ignore
    }
  }

  void _subscribeToBookingsRealtime() async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) return;

      final client = SupabaseClientManager.client;
      final stream =
          client.from('bookings').stream(primaryKey: ['id']).eq('tailor_id', user.id);

      _bookingsSub = stream.listen((event) {
        _loadBookingsForDashboard();
      }, onError: (err) {
        _loadBookingsForDashboard();
      });
    } catch (e) {
      // ignore
    }
  }

  Future<void> _openGarmentDetail(Map<String, dynamic> garment) async {
    try {
      final clientId = garment['client_id']?.toString() ??
          garment['client']?.toString();

      if (garment['client'] is Map<String, dynamic>) {
        final clientFromGarment = Map<String, dynamic>.from(garment['client']);
        Navigator.pushNamed(context, AppRoutes.garmentDetail, arguments: {
          'client': clientFromGarment,
          'garment': garment,
        });
        return;
      }

      if (clientId == null || clientId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client information not available for this garment'),
          ),
        );
        return;
      }

      final client = await _supabaseService.getClientById(clientId);
      if (client == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client not found')),
        );
        return;
      }

      Navigator.pushNamed(context, AppRoutes.garmentDetail, arguments: {
        'client': client,
        'garment': garment,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open garment detail: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  String _formatRecentBookingText() {
    if (!_hasRecentBooking || _recentBooking == null) return 'No new bookings yet';

    final rb = _recentBooking!;
    final clientName = rb['client_name'] ??
        (rb['client'] is Map
            ? (rb['client'] as Map)['name'] ??
                (rb['client'] as Map)['full_name']
            : null) ??
        'Client';
    final bookingDate = rb['booking_date']?.toString() ??
        rb['created_at']?.toString() ??
        '';
    final service = rb['service_type'] ?? rb['garment_type'] ?? '';
    String dateOnly = bookingDate;
    try {
      dateOnly = DateTime.parse(bookingDate).toString().split(' ')[0];
    } catch (_) {}
    return '$clientName — ${service.isNotEmpty ? "$service • " : ""}$dateOnly';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      body: SafeArea(
        child: Column(
          children: [
            // Animated Header
            SlideTransition(
              position: _headerSlide,
              child: FadeTransition(
                opacity: _headerOpacity,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _shopName,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _tailorName,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.2),
                              AppColors.primary.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _signOut,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.logout_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Logout',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Dashboard Content
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1A1F2A),
                      const Color(0xFF0F1419),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Animated Stats
                            ScaleTransition(
                              scale: _statsScale,
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _AnimatedStatCard(
                                          title: 'Total Clients',
                                          value: _totalClients.toString(),
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.blue.shade500,
                                              Colors.blue.shade400,
                                            ],
                                          ),
                                          icon: Icons.people_rounded,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _AnimatedStatCard(
                                          title: 'Active Jobs',
                                          value: _activeJobs.toString(),
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.green.shade500,
                                              Colors.green.shade400,
                                            ],
                                          ),
                                          icon: Icons.work_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _AnimatedStatCard(
                                          title: 'Pending Payment',
                                          value:
                                              'Rs ${_pendingPayments.toStringAsFixed(0)}',
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.orange.shade500,
                                              Colors.orange.shade400,
                                            ],
                                          ),
                                          icon: Icons.payments_rounded,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _AnimatedStatCard(
                                          title: 'New Bookings',
                                          value: _newBookings.toString(),
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.purple.shade500,
                                              Colors.purple.shade400,
                                            ],
                                          ),
                                          icon: Icons.calendar_month_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Animated Recent Booking Card
                            FadeTransition(
                              opacity: _contentFade,
                              child: _RecentBookingCard(
                                text: _formatRecentBookingText(),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Animated Action Buttons
                            FadeTransition(
                              opacity: _contentFade,
                              child: Column(
                                children: [
                                  _AnimatedActionButton(
                                    'Manage Clients',
                                    Icons.people_outline_rounded,
                                    () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.tailorClientManage,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _AnimatedActionButton(
                                    'View Bookings',
                                    Icons.calendar_month_rounded,
                                    () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.viewBooking,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _AnimatedActionButton(
                                    'Edit Profile',
                                    Icons.edit_rounded,
                                    () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.profileSetup,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Active Jobs Section
                            FadeTransition(
                              opacity: _contentFade,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionHeader(
                                    'Active Jobs (${_activeGarments.length})',
                                    onSeeAll: () {
                                      Navigator.pushNamed(context,
                                          AppRoutes.tailorClientManage);
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _activeGarments.isEmpty
                                      ? _EmptyState('No active jobs right now.')
                                      : Column(
                                          children: _activeGarments
                                              .map((g) => _GarmentTile(
                                                    garment: g,
                                                    onTap: () =>
                                                        _openGarmentDetail(g),
                                                  ))
                                              .toList(),
                                        ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Pending Payments Section
                            FadeTransition(
                              opacity: _contentFade,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionHeader(
                                    'Pending Payments (${_pendingGarments.length})',
                                    onSeeAll: () {
                                      Navigator.pushNamed(context,
                                          AppRoutes.tailorClientManage);
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _pendingGarments.isEmpty
                                      ? _EmptyState('No pending payments.')
                                      : Column(
                                          children: _pendingGarments
                                              .map((g) => _PaymentTile(
                                                    garment: g,
                                                    onTap: () =>
                                                        _openGarmentDetail(g),
                                                  ))
                                              .toList(),
                                        ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
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
}

// Animated Stat Card Widget
class _AnimatedStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Gradient gradient;
  final IconData icon;

  const _AnimatedStatCard({
    required this.title,
    required this.value,
    required this.gradient,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.85),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// Recent Booking Card
class _RecentBookingCard extends StatelessWidget {
  final String text;

  const _RecentBookingCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.2),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Recent Booking',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[300],
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// Animated Action Button
class _AnimatedActionButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _AnimatedActionButton(this.text, this.icon, this.onTap);

  @override
  State<_AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<_AnimatedActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                widget.text,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Section Header
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader(this.title, {this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onSeeAll,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                'See all',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Garment Tile
class _GarmentTile extends StatelessWidget {
  final Map<String, dynamic> garment;
  final VoidCallback onTap;

  const _GarmentTile({required this.garment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final clientName =
        garment['client_name'] ?? garment['client_full_name'] ?? 'Client';
    final garmentType = garment['garment_type'] ?? 'Garment';
    final deliveryDate = garment['delivery_date'] ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E2330).withOpacity(0.9),
              const Color(0xFF2A3342).withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.green.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.checkroom_rounded,
                size: 18,
                color: Colors.green.shade400,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$clientName • $garmentType',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Delivery: ${deliveryDate.toString().split('T').first}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade500.withOpacity(0.2),
                    Colors.green.shade600.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'Active',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.green.shade400,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Payment Tile
class _PaymentTile extends StatelessWidget {
  final Map<String, dynamic> garment;
  final VoidCallback onTap;

  const _PaymentTile({required this.garment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final clientName =
        garment['client_name'] ?? garment['client_full_name'] ?? 'Client';
    final garmentType = garment['garment_type'] ?? 'Garment';
    final remaining = (garment['remaining_amount'] ?? 0).toDouble();
    final price = (garment['price'] ?? 0).toString();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E2330).withOpacity(0.9),
              const Color(0xFF2A3342).withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.currency_exchange_rounded,
                size: 18,
                color: Colors.orange.shade400,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$clientName • $garmentType',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Price: Rs $price',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade500.withOpacity(0.2),
                    Colors.orange.shade600.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'Rs ${remaining.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange.shade400,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Empty State Widget
class _EmptyState extends StatelessWidget {
  final String text;

  const _EmptyState(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}