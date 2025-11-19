import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:silai/core/constants/app_colors.dart';
import 'package:silai/core/services/supabase_service.dart';

class AddGarmentScreen extends StatefulWidget {
  final Map<String, dynamic> client;

  const AddGarmentScreen({
    super.key,
    required this.client,
  });

  @override
  State<AddGarmentScreen> createState() => _AddGarmentScreenState();
}

class _AddGarmentScreenState extends State<AddGarmentScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final SupabaseService _supabaseService = SupabaseService();

  // Form controllers
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  final _deliveryDateController = TextEditingController();

  // Measurement controllers
  final _neckController = TextEditingController();
  final _shoulderController = TextEditingController();
  final _armsController = TextEditingController();
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipsController = TextEditingController();
  final _shirtLengthController = TextEditingController();
  final _trouserLengthController = TextEditingController();

  // Dropdown selections
  String _selectedGarmentType = 'Suits';
  String _selectedQuantity = 'Single Piece';

  bool _isLoading = false;
  DateTime? _selectedDeliveryDate;

  late AnimationController _headerController;
  late AnimationController _formController;
  late Animation<Offset> _headerSlide;
  late Animation<double> _headerOpacity;
  late Animation<double> _formFade;

  final List<String> _garmentTypes = [
    'Suits',
    'Shirt',
    'Pant',
    'Kurta',
    'Shalwar Kameez',
    'Waistcoat',
    'Coat',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
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

    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    await _headerController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _formController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _formController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    _deliveryDateController.dispose();
    _neckController.dispose();
    _shoulderController.dispose();
    _armsController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _hipsController.dispose();
    _shirtLengthController.dispose();
    _trouserLengthController.dispose();
    super.dispose();
  }

  Future<void> _selectDeliveryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
        _selectedDeliveryDate = picked;
        _deliveryDateController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Map<String, dynamic> _buildMeasurementsJson() {
    final measurements = <String, dynamic>{};

    if (_neckController.text.isNotEmpty) {
      measurements['neck'] = _neckController.text;
    }
    if (_shoulderController.text.isNotEmpty) {
      measurements['shoulder'] = _shoulderController.text;
    }
    if (_armsController.text.isNotEmpty) {
      measurements['arms'] = _armsController.text;
    }
    if (_chestController.text.isNotEmpty) {
      measurements['chest'] = _chestController.text;
    }
    if (_waistController.text.isNotEmpty) {
      measurements['waist'] = _waistController.text;
    }
    if (_hipsController.text.isNotEmpty) {
      measurements['hips'] = _hipsController.text;
    }
    if (_shirtLengthController.text.isNotEmpty) {
      measurements['shirt_length'] = _shirtLengthController.text;
    }
    if (_trouserLengthController.text.isNotEmpty) {
      measurements['trouser_length'] = _trouserLengthController.text;
    }

    return measurements;
  }

  Future<void> _saveGarment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _supabaseService.currentUser;
      if (user == null) throw Exception('No user logged in');

      final measurements = _buildMeasurementsJson();

      await _supabaseService.addGarment(
        clientId: widget.client['id'],
        tailorId: user.id,
        garmentType: '$_selectedGarmentType - $_selectedQuantity',
        price:
            _priceController.text.isEmpty ? 0 : double.parse(_priceController.text),
        deliveryDate: _selectedDeliveryDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        measurements: measurements,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Garment added successfully! 🎉'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add garment: $e'),
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
    final clientName = widget.client['full_name'] ?? 'Unknown';

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
                              'Add Garment',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              'For $clientName',
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

            // Form Content
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
                child: FadeTransition(
                  opacity: _formFade,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Garment Type Dropdown
                          _buildLabel('Garment Type'),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedGarmentType,
                              decoration: _buildInputDecoration(),
                              dropdownColor: const Color(0xFF1E2330),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                              icon: Icon(
                                Icons.expand_more_rounded,
                                color: AppColors.primary,
                              ),
                              items: _garmentTypes.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedGarmentType = value!);
                              },
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Quantity Radio Buttons
                          _buildLabel('Quantity'),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildRadioTile(
                                    'Single Piece',
                                    _selectedQuantity == 'Single Piece',
                                    () => setState(() => _selectedQuantity = 'Single Piece'),
                                  ),
                                ),
                                Expanded(
                                  child: _buildRadioTile(
                                    'Multi Piece',
                                    _selectedQuantity == 'Multi Piece',
                                    () => setState(() => _selectedQuantity = 'Multi Piece'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Measurements Section
                          _buildLabel('Measurements (cm)'),
                          const SizedBox(height: 12),
                          _buildMeasurementRow('Neck', _neckController, 'Shoulder',
                              _shoulderController),
                          const SizedBox(height: 12),
                          _buildMeasurementRow('Arms', _armsController, 'Chest',
                              _chestController),
                          const SizedBox(height: 12),
                          _buildMeasurementRow('Waist', _waistController, 'Hips',
                              _hipsController),
                          const SizedBox(height: 12),
                          _buildMeasurementRow('Shirt Length', _shirtLengthController,
                              'Trouser Length', _trouserLengthController),
                          const SizedBox(height: 22),

                          // Expected Completion Date
                          _buildLabel('Expected Completion Date'),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _deliveryDateController,
                            readOnly: true,
                            decoration:
                                _buildInputDecoration(hintText: 'DD/MM/YYYY'),
                            onTap: _selectDeliveryDate,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Total Price
                          _buildLabel('Total Price (Rs)'),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: _buildInputDecoration(hintText: '0'),
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Notes (Optional)
                          _buildLabel('Notes (Optional)'),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: _buildInputDecoration(),
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  label: 'Add Garment',
                                  isDark: true,
                                  isLoading: _isLoading,
                                  onPressed: _isLoading ? null : _saveGarment,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildActionButton(
                                  label: 'Cancel',
                                  isDark: false,
                                  isLoading: false,
                                  onPressed:
                                      _isLoading ? null : () => Navigator.pop(context),
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
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.2,
      ),
    );
  }

  InputDecoration _buildInputDecoration({String? hintText}) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF1E2330),
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[600]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildMeasurementRow(
    String label1,
    TextEditingController controller1,
    String label2,
    TextEditingController controller2,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildMeasurementField(label1, controller1),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMeasurementField(label2, controller2),
        ),
      ],
    );
  }

  Widget _buildMeasurementField(
    String label,
    TextEditingController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey[300],
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1E2330),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              isDense: true,
            ),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioTile(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.primary : Colors.grey[600]!,
                width: 2,
              ),
              color: selected ? AppColors.primary.withOpacity(0.2) : transparent,
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
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
                    style: GoogleFonts.poppins(
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

// transparent constant for null coalescing
const transparent = Color(0x00000000);