// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:silai/core/constants/app_colors.dart';
import 'package:silai/core/services/supabase_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic> tailor;

  const BookAppointmentScreen({
    Key? key,
    required this.tailor,
  }) : super(key: key);

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final SupabaseService _supabaseService = SupabaseService();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedService;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  late AnimationController _headerController;
  late AnimationController _contentController;
  late Animation<Offset> _headerSlide;
  late Animation<double> _contentFade;

  final List<String> _services = [
    'Shirt Stitching',
    'Pant Stitching',
    'Suit Stitching',
    'Kurta Stitching',
    'Alteration',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadClientData();
  }

  void _setupAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _headerSlide = Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeInOutQuad),
    );

    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _notesController.dispose();
    _headerController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadClientData() async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) return;

      final profile = await _supabaseService.getProfile(user.id);

      if (profile != null && mounted) {
        setState(() {
          _nameController.text = profile['full_name'] ?? '';
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: const Color(0xFF1E2330),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: const Color(0xFF1E2330),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  Future<void> _sendBookingRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a service'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _supabaseService.currentUser;
      if (user == null) throw Exception('No user logged in');

      await _supabaseService.createBooking(
        clientId: user.id,
        tailorId: widget.tailor['id'],
        clientName: _nameController.text.trim(),
        clientAddress: _addressController.text.trim(),
        serviceType: _selectedService!,
        bookingDate: _selectedDate!,
        bookingTime: _selectedTime!,
        additionalNotes: _notesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Booking request sent successfully! 🎉'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send booking: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopName = widget.tailor['shop_name'] ?? 'Unknown Shop';

    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      body: SafeArea(
        child: Column(
          children: [
            // Animated Header
            SlideTransition(
              position: _headerSlide,
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
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 24),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Book Appointment',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            shopName,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: FadeTransition(
                opacity: _contentFade,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - _contentFade.value)),
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name Field
                            _buildFormSection(
                              label: 'Your Name',
                              icon: Icons.person_rounded,
                              child: TextFormField(
                                controller: _nameController,
                                decoration: _buildInputDecoration(
                                  hintText: 'Enter your full name',
                                ),
                                style: TextStyle(color: Colors.white, fontSize: 15),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Address Field
                            _buildFormSection(
                              label: 'Delivery Address',
                              icon: Icons.location_on_rounded,
                              child: TextFormField(
                                controller: _addressController,
                                maxLines: 2,
                                decoration: _buildInputDecoration(
                                  hintText: 'Enter your address',
                                ),
                                style: TextStyle(color: Colors.white, fontSize: 15),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your address';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Service Dropdown
                            _buildFormSection(
                              label: 'Service Type',
                              icon: Icons.design_services_rounded,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: _selectedService,
                                  decoration: _buildInputDecoration(
                                    hintText: 'Select a service',
                                  ),
                                  dropdownColor: const Color(0xFF1E2330),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                  icon: Icon(
                                    Icons.expand_more_rounded,
                                    color: AppColors.primary,
                                  ),
                                  items: _services.map((service) {
                                    return DropdownMenuItem(
                                      value: service,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 4,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(service),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() => _selectedService = value);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Date & Time Row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormSection(
                                    label: 'Date',
                                    icon: Icons.calendar_month_rounded,
                                    child: TextFormField(
                                      controller: _dateController,
                                      readOnly: true,
                                      decoration: _buildInputDecoration(
                                        hintText: 'DD/MM/YYYY',
                                      ),
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 15),
                                      onTap: _selectDate,
                                      validator: (value) {
                                        if (_selectedDate == null) {
                                          return 'Select date';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildFormSection(
                                    label: 'Time',
                                    icon: Icons.schedule_rounded,
                                    child: TextFormField(
                                      controller: _timeController,
                                      readOnly: true,
                                      decoration: _buildInputDecoration(
                                        hintText: 'HH:MM',
                                      ),
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 15),
                                      onTap: _selectTime,
                                      validator: (value) {
                                        if (_selectedTime == null) {
                                          return 'Select time';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Additional Notes
                            _buildFormSection(
                              label: 'Additional Notes (Optional)',
                              icon: Icons.note_rounded,
                              child: TextFormField(
                                controller: _notesController,
                                maxLines: 3,
                                decoration: _buildInputDecoration(
                                  hintText:
                                      'Any specific requirements or preferences...',
                                ),
                                style: TextStyle(color: Colors.white, fontSize: 15),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Info Banner
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withOpacity(0.15),
                                    AppColors.primary.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.info_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Booking Request',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'The tailor will confirm your appointment shortly. Track the status in "My Orders".',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[400],
                                            fontWeight: FontWeight.w400,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: _buildPremiumButton(
                                    label: 'Send Request',
                                    isDark: true,
                                    isLoading: _isLoading,
                                    onPressed:
                                        _isLoading ? null : _sendBookingRequest,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildPremiumButton(
                                    label: 'Cancel',
                                    isDark: false,
                                    isLoading: false,
                                    onPressed: _isLoading
                                        ? null
                                        : () => Navigator.pop(context),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
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

  Widget _buildFormSection({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  InputDecoration _buildInputDecoration({String? hintText}) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF1E2330),
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.grey[600],
        fontSize: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.red.shade400,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildPremiumButton({
    required String label,
    required bool isDark,
    required bool isLoading,
    required VoidCallback? onPressed,
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
            child: isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? Colors.white : AppColors.primary,
                      ),
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.white70,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
      ),
    );
  }
}