// ignore_for_file: use_super_parameters

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:silai/core/constants/app_colors.dart';
import 'package:silai/core/services/supabase_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();

  // Controllers
  final _shopNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _workingHoursController = TextEditingController();

  File? _selectedImage;
  String? _existingImageUrl;
  bool _isLoading = false;
  bool _isLoadingProfile = true;

  late AnimationController _headerController;
  late AnimationController _formController;
  late AnimationController _imageController;
  late Animation<Offset> _headerSlide;
  late Animation<double> _headerOpacity;
  late Animation<double> _formFade;
  late Animation<double> _imageScale;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadProfile();
  }

  void _setupAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _formController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _imageController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _headerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeIn),
    );

    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeIn),
    );

    _imageScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _imageController, curve: Curves.elasticOut),
    );

    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    await _headerController.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _imageController.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _formController.forward();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _workingHoursController.dispose();
    _headerController.dispose();
    _formController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) return;

      final profile = await _supabaseService.getProfile(user.id);

      if (profile != null && mounted) {
        setState(() {
          _shopNameController.text = profile['shop_name'] ?? '';
          _addressController.text = profile['address'] ?? '';
          _phoneController.text = profile['phone_number'] ?? '';
          _workingHoursController.text = profile['working_hours'] ?? '';
          _existingImageUrl = profile['profile_image'];
        });
      }
    } catch (e) {
      _showError('Failed to load profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _supabaseService.currentUser;
      if (user == null) throw Exception('No user logged in');

      String? imageUrl = _existingImageUrl;

      if (_selectedImage != null) {
        final fileName =
            '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imageUrl = await _supabaseService.uploadFile(
          bucket: 'profiles',
          path: 'avatars/$fileName',
          file: _selectedImage!,
        );
      }

      await _supabaseService.updateProfile(user.id, {
        'shop_name': _shopNameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'working_hours': _workingHoursController.text.trim(),
        'profile_image': imageUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile saved successfully! 🎉'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/tailor-dashboard',
              (route) => false,
            );
          }
        });
      }
    } catch (e) {
      _showError('Failed to save profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null
          ? Container(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: AppColors.primary, size: 20),
            )
          : null,
      filled: true,
      fillColor: const Color(0xFF1E2330),
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
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      labelStyle: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.grey[400],
      ),
      hintStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.grey[600],
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
            // Animated Header
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
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Setup Your Profile',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              'Complete your shop information',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[400],
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
            ),

            // Animated Form Container
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
                child: _isLoadingProfile
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : FadeTransition(
                        opacity: _formFade,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Profile Image Section
                                Center(
                                  child: Column(
                                    children: [
                                      ScaleTransition(
                                        scale: _imageScale,
                                        child: GestureDetector(
                                          onTap: _pickImage,
                                          child: Container(
                                            width: 130,
                                            height: 130,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  AppColors.primary,
                                                  AppColors.primary
                                                      .withOpacity(0.7),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              border: Border.all(
                                                color: AppColors.primary
                                                    .withOpacity(0.5),
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.primary
                                                      .withOpacity(0.3),
                                                  blurRadius: 24,
                                                  offset:
                                                      const Offset(0, 12),
                                                ),
                                              ],
                                            ),
                                            child: Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(22),
                                                  child: _selectedImage !=
                                                          null
                                                      ? Image.file(
                                                          _selectedImage!,
                                                          fit: BoxFit.cover,
                                                        )
                                                      : _existingImageUrl !=
                                                              null
                                                          ? Image.network(
                                                              _existingImageUrl!,
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (
                                                                _,
                                                                __,
                                                                ___,
                                                              ) =>
                                                                  Container(
                                                                decoration: BoxDecoration(
                                                                  gradient: LinearGradient(
                                                                    colors: [
                                                                      AppColors
                                                                          .primary
                                                                          .withOpacity(
                                                                              0.1),
                                                                      AppColors
                                                                          .primary
                                                                          .withOpacity(
                                                                              0.05),
                                                                    ],
                                                                  ),
                                                                ),
                                                                child:
                                                                    const Icon(
                                                                  Icons
                                                                      .camera_alt_rounded,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 42,
                                                                ),
                                                              ),
                                                            )
                                                          : Container(
                                                              decoration: BoxDecoration(
                                                                gradient:
                                                                    LinearGradient(
                                                                  colors: [
                                                                    AppColors
                                                                        .primary
                                                                        .withOpacity(
                                                                            0.1),
                                                                    AppColors
                                                                        .primary
                                                                        .withOpacity(
                                                                            0.05),
                                                                  ],
                                                                ),
                                                              ),
                                                              child: const Icon(
                                                                Icons
                                                                    .camera_alt_rounded,
                                                                color: Colors
                                                                    .white,
                                                                size: 42,
                                                              ),
                                                            ),
                                                    ),
                                                Positioned(
                                                  bottom: 0,
                                                  right: 0,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          AppColors.primary,
                                                          AppColors.primary
                                                              .withOpacity(0.8),
                                                        ],
                                                      ),
                                                      border: Border.all(
                                                        color: Colors.white,
                                                        width: 3,
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(0.3),
                                                          blurRadius: 8,
                                                          offset: const Offset(
                                                              0, 4),
                                                        ),
                                                      ],
                                                    ),
                                                    padding:
                                                        const EdgeInsets.all(
                                                            10),
                                                    child: const Icon(
                                                      Icons.edit_rounded,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Tap to upload shop photo',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.grey[400],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'JPG, PNG up to 5MB',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 36),

                                // Shop Name
                                _buildFormLabel('Shop Name'),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _shopNameController,
                                  decoration: _buildInputDecoration(
                                    'Enter your shop name',
                                    Icons.storefront_rounded,
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter shop name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 22),

                                // Address
                                _buildFormLabel('Address'),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _addressController,
                                  maxLines: 2,
                                  decoration: _buildInputDecoration(
                                    'Enter your full address',
                                    Icons.location_on_rounded,
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 22),

                                // Phone Number
                                _buildFormLabel('Phone Number'),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: _buildInputDecoration(
                                    'Enter your phone number',
                                    Icons.phone_rounded,
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter phone number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 22),

                                // Working Hours
                                _buildFormLabel('Working Hours'),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _workingHoursController,
                                  decoration: _buildInputDecoration(
                                    'e.g., 9 AM - 6 PM',
                                    Icons.schedule_rounded,
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter working hours';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 36),

                                // Save Button
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap:
                                            _isLoading ? null : _saveProfile,
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        child: Ink(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppColors.primary,
                                                AppColors.primary
                                                    .withOpacity(0.8),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          child: Center(
                                            child: _isLoading
                                                ? SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2.5,
                                                    ),
                                                  )
                                                : Text(
                                                    'Save Profile',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white,
                                                      letterSpacing: 0.3,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
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

  Widget _buildFormLabel(String label) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}