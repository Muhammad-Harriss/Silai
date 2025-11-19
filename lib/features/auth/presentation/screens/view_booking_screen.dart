import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:silai/core/constants/app_colors.dart';
import 'package:silai/core/services/supabase_service.dart';

class ViewBookingScreen extends StatefulWidget {
  const ViewBookingScreen({super.key});

  @override
  State<ViewBookingScreen> createState() => _ViewBookingScreenState();
}

class _ViewBookingScreenState extends State<ViewBookingScreen>
    with TickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;

  late AnimationController _headerController;
  late AnimationController _listController;
  late Animation<Offset> _headerSlide;
  late Animation<double> _headerOpacity;
  late Animation<double> _listFade;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadBookings();
  }

  void _setupAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _listController = AnimationController(
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

    _listFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _listController, curve: Curves.easeIn),
    );

    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    await _headerController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _listController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _listController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _loading = true);
    try {
      final data = await _supabaseService.getBookingsForTailor();
      if (mounted) {
        setState(() {
          _bookings = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading bookings: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _updateStatus(
    String bookingId,
    String newStatus,
    Map<String, dynamic> booking,
  ) async {
    try {
      final currentTaillorId = _supabaseService.currentUser?.id;
      if (currentTaillorId == null) {
        throw Exception('User not authenticated');
      }

      await _supabaseService.updateBookingStatus(bookingId, newStatus);

      if (newStatus == 'confirmed') {
        final tailorProfile =
            await _supabaseService.getProfile(currentTaillorId);

        if (tailorProfile == null) {
          throw Exception('Tailor profile not found');
        }

        await _supabaseService.createOrder(
          clientId: booking['client_id'],
          tailorId: currentTaillorId,
          tailorShopName: tailorProfile['shop_name'] ?? 'Tailor Shop',
          orderDescription:
              '${booking['service_type']} - ${booking['additional_notes'] ?? 'No notes'}',
          totalAmount: 0.0,
          status: 'Accepted',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Booking accepted! Order created. 🎉'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }

      if (newStatus == 'cancelled') {
        final tailorProfile =
            await _supabaseService.getProfile(currentTaillorId);

        if (tailorProfile != null) {
          try {
            await _supabaseService.createOrder(
              clientId: booking['client_id'],
              tailorId: currentTaillorId,
              tailorShopName: tailorProfile['shop_name'] ?? 'Tailor Shop',
              orderDescription:
                  '${booking['service_type']} - Rejected by tailor',
              totalAmount: 0.0,
              status: 'Cancelled',
            );
          } catch (e) {
            debugPrint('Note: Could not create cancelled order: $e');
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Booking rejected!'),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }

      _loadBookings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      debugPrint('Error updating booking status: $e');
    }
  }

  Widget _statusBadge(String status) {
    Color color;
    String displayText;

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.amber;
        displayText = 'PENDING';
        break;
      case 'confirmed':
        color = Colors.green;
        displayText = 'CONFIRMED';
        break;
      case 'completed':
        color = Colors.blue;
        displayText = 'COMPLETED';
        break;
      case 'cancelled':
        color = Colors.red;
        displayText = 'CANCELLED';
        break;
      default:
        color = Colors.grey;
        displayText = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.3),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1.2,
        ),
      ),
      child: Text(
        displayText,
        style: GoogleFonts.poppins(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(String? timeString) {
    if (timeString == null) return 'N/A';
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = parts[1];
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '$displayHour:$minute $period';
      }
      return timeString;
    } catch (e) {
      return timeString;
    }
  }

  Widget _bookingCard(Map<String, dynamic> booking) {
    final clientName = booking['client_name'] ?? 'Unknown Client';
    final clientAddress = booking['client_address'] ?? 'No address';
    final serviceType = booking['service_type'] ?? 'Service';
    final status = booking['status']?.toString().toLowerCase() ?? 'pending';
    final bookingId = booking['id']?.toString() ?? '';
    final bookingDate = _formatDate(booking['booking_date']);
    final bookingTime = _formatTime(booking['booking_time']);
    final notes = booking['additional_notes'];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
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
            color: Colors.white.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.3),
                          AppColors.primary.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        clientName[0].toUpperCase(),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clientName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          serviceType,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusBadge(status),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.05),
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Text(
                    bookingDate,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Text(
                    bookingTime,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_rounded, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      clientAddress,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note_rounded, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        notes,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              if (status == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.check_rounded,
                        label: 'Accept',
                        isDark: true,
                        onPressed: () =>
                            _updateStatus(bookingId, 'confirmed', booking),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.close_rounded,
                        label: 'Reject',
                        isDark: false,
                        color: Colors.red,
                        onPressed: () =>
                            _updateStatus(bookingId, 'cancelled', booking),
                      ),
                    ),
                  ],
                ),
              if (status == 'confirmed')
                SizedBox(
                  width: double.infinity,
                  child: _buildActionButton(
                    icon: Icons.check_circle_rounded,
                    label: 'Mark Completed',
                    isDark: true,
                    onPressed: () =>
                        _updateStatus(bookingId, 'completed', booking),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onPressed,
    Color? color,
  }) {
    final btnColor = color ?? (isDark ? AppColors.primary : Colors.white);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
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
                      btnColor.withOpacity(0.2),
                      btnColor.withOpacity(0.1),
                    ],
                  ),
            borderRadius: BorderRadius.circular(10),
            border: !isDark
                ? Border.all(
                    color: btnColor.withOpacity(0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: isDark ? Colors.white : btnColor),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : btnColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      body: SafeArea(
        child: Column(
          children: [
            SlideTransition(
              position: _headerSlide,
              child: FadeTransition(
                opacity: _headerOpacity,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'My Bookings',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : FadeTransition(
                        opacity: _listFade,
                        child: _bookings.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Icon(
                                        Icons.calendar_today_outlined,
                                        size: 64,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No bookings yet',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Bookings will appear here',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadBookings,
                                child: ListView.builder(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: _bookings.length,
                                  itemBuilder: (context, index) {
                                    return _bookingCard(_bookings[index]);
                                  },
                                ),
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