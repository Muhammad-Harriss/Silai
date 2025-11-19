import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:silai/core/constants/app_colors.dart';
import 'package:silai/core/constants/app_routes.dart';
import 'package:silai/core/services/supabase_service.dart';

class GarmentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> garment;
  final Map<String, dynamic> client;

  const GarmentDetailsScreen({
    super.key,
    required this.garment,
    required this.client,
  });

  @override
  State<GarmentDetailsScreen> createState() => _GarmentDetailsScreenState();
}

class _GarmentDetailsScreenState extends State<GarmentDetailsScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final SupabaseService _supabaseService = SupabaseService();

  late TextEditingController _priceController;
  late TextEditingController _notesController;
  late TextEditingController _deliveryDateController;

  late TextEditingController _neckController;
  late TextEditingController _shoulderController;
  late TextEditingController _armsController;
  late TextEditingController _chestController;
  late TextEditingController _waistController;
  late TextEditingController _hipsController;
  late TextEditingController _shirtLengthController;
  late TextEditingController _trouserLengthController;

  late String _selectedStatus;
  DateTime? _selectedDeliveryDate;
  bool _isLoading = false;
  bool _isEditing = false;

  late AnimationController _headerController;
  late AnimationController _contentController;
  late Animation<Offset> _headerSlide;
  late Animation<double> _headerOpacity;
  late Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeControllers();
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

    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _headerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeIn),
    );

    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeIn),
    );

    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    await _headerController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _contentController.forward();
  }

  void _initializeControllers() {
    final measurements = widget.garment['measurements'] as Map<String, dynamic>? ?? {};

    _priceController = TextEditingController(
      text: (widget.garment['price'] ?? 0).toString(),
    );
    _notesController = TextEditingController(
      text: widget.garment['notes'] ?? '',
    );
    _deliveryDateController = TextEditingController();

    if (widget.garment['delivery_date'] != null) {
      _selectedDeliveryDate = DateTime.parse(widget.garment['delivery_date']);
      _deliveryDateController.text =
          '${_selectedDeliveryDate!.day.toString().padLeft(2, '0')}/${_selectedDeliveryDate!.month.toString().padLeft(2, '0')}/${_selectedDeliveryDate!.year}';
    }

    _selectedStatus = widget.garment['status'] ?? 'pending';

    _neckController = TextEditingController(
        text: measurements['neck']?.toString() ?? '');
    _shoulderController = TextEditingController(
        text: measurements['shoulder']?.toString() ?? '');
    _armsController =
        TextEditingController(text: measurements['arms']?.toString() ?? '');
    _chestController = TextEditingController(
        text: measurements['chest']?.toString() ?? '');
    _waistController = TextEditingController(
        text: measurements['waist']?.toString() ?? '');
    _hipsController =
        TextEditingController(text: measurements['hips']?.toString() ?? '');
    _shirtLengthController = TextEditingController(
        text: measurements['shirt_length']?.toString() ?? '');
    _trouserLengthController = TextEditingController(
        text: measurements['trouser_length']?.toString() ?? '');
  }

  @override
  void dispose() {
    _headerController.dispose();
    _contentController.dispose();
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
    if (!_isEditing) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeliveryDate ?? DateTime.now(),
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final measurements = _buildMeasurementsJson();

      await _supabaseService.updateGarment(widget.garment['id'], {
        'price': double.tryParse(_priceController.text) ?? 0,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
        'delivery_date': _selectedDeliveryDate?.toIso8601String(),
        'status': _selectedStatus,
        'measurements': measurements,
      });

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Garment updated successfully! 🎉'),
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
            content: Text('Failed to update garment: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
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

  Future<void> _deleteGarment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2330),
        title: Text(
          'Delete Garment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this garment? This action cannot be undone.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabaseService.deleteGarment(widget.garment['id']);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Garment deleted successfully'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete garment: $e'),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
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
                              'Garment Details',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              clientName,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_isEditing)
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
                            onPressed: () => setState(() => _isEditing = true),
                            icon: const Icon(Icons.edit_rounded,
                                color: Colors.white, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Content
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
                  opacity: _contentFade,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Garment Type Card
                          _GarmentTypeCard(
                            type: widget.garment['garment_type'] ?? 'Unknown',
                          ),
                          const SizedBox(height: 24),

                          // Status Section
                          _buildSectionLabel('Status'),
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
                              value: _selectedStatus,
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
                              items: const [
                                DropdownMenuItem(
                                  value: 'pending',
                                  child: Text('Pending'),
                                ),
                                DropdownMenuItem(
                                  value: 'in_progress',
                                  child: Text('In Progress'),
                                ),
                                DropdownMenuItem(
                                  value: 'completed',
                                  child: Text('Completed'),
                                ),
                                DropdownMenuItem(
                                  value: 'delivered',
                                  child: Text('Delivered'),
                                ),
                              ],
                              onChanged: _isEditing
                                  ? (value) =>
                                      setState(() => _selectedStatus = value!)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Measurements Section
                          _buildSectionLabel('Measurements (in cm)'),
                          const SizedBox(height: 12),
                          _buildMeasurementRow(
                            'Neck',
                            _neckController,
                            'Shoulder',
                            _shoulderController,
                          ),
                          const SizedBox(height: 12),
                          _buildMeasurementRow(
                            'Arms',
                            _armsController,
                            'Chest',
                            _chestController,
                          ),
                          const SizedBox(height: 12),
                          _buildMeasurementRow(
                            'Waist',
                            _waistController,
                            'Hips',
                            _hipsController,
                          ),
                          const SizedBox(height: 12),
                          _buildMeasurementRow(
                            'Shirt Length',
                            _shirtLengthController,
                            'Trouser Length',
                            _trouserLengthController,
                          ),
                          const SizedBox(height: 24),

                          // Delivery Date
                          _buildSectionLabel('Expected Completion Date'),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _deliveryDateController,
                            readOnly: true,
                            enabled: _isEditing,
                            decoration:
                                _buildInputDecoration(hintText: 'DD/MM/YYYY'),
                            onTap: _selectDeliveryDate,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Price
                          _buildSectionLabel('Total Price (Rs)'),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _priceController,
                            readOnly: !_isEditing,
                            keyboardType: TextInputType.number,
                            decoration: _buildInputDecoration(hintText: '0'),
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Notes
                          _buildSectionLabel('Notes'),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _notesController,
                            readOnly: !_isEditing,
                            maxLines: 3,
                            decoration: _buildInputDecoration(),
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Payment Section
                          _PaymentSection(
                            garment: widget.garment,
                            client: widget.client,
                          ),
                          const SizedBox(height: 28),

                          // Action Buttons
                          if (_isEditing) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _ActionButton(
                                    label: 'Save',
                                    color: AppColors.primary,
                                    onPressed:
                                        _isLoading ? null : _saveChanges,
                                    isLoading: _isLoading,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ActionButton(
                                    label: 'Cancel',
                                    color: Colors.white.withOpacity(0.12),
                                    textColor: Colors.white70,
                                    onPressed: _isLoading
                                        ? null
                                        : () {
                                            setState(() {
                                              _isEditing = false;
                                              _initializeControllers();
                                            });
                                          },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: _ActionButton(
                                label: 'Delete Garment',
                                color: Colors.red.shade700,
                                icon: Icons.delete_rounded,
                                onPressed:
                                    _isLoading ? null : _deleteGarment,
                              ),
                            ),
                          ],
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

  Widget _buildSectionLabel(String text) {
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

  Widget _buildMeasurementRow(
    String label1,
    TextEditingController controller1,
    String label2,
    TextEditingController controller2,
  ) {
    return Row(
      children: [
        Expanded(
          child: _MeasurementField(
            label: label1,
            controller: controller1,
            isEditing: _isEditing,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MeasurementField(
            label: label2,
            controller: controller2,
            isEditing: _isEditing,
          ),
        ),
      ],
    );
  }
}

// Garment Type Card
class _GarmentTypeCard extends StatelessWidget {
  final String type;

  const _GarmentTypeCard({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.checkroom_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Garment Type',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[400],
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  type,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Measurement Field Widget
class _MeasurementField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isEditing;

  const _MeasurementField({
    required this.label,
    required this.controller,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
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
            readOnly: !isEditing,
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
}

// Payment Section Widget
class _PaymentSection extends StatelessWidget {
  final Map<String, dynamic> garment;
  final Map<String, dynamic> client;

  const _PaymentSection({
    required this.garment,
    required this.client,
  });

  @override
  Widget build(BuildContext context) {
    final total = (garment['price'] ?? 0).toDouble();
    final paid = (garment['paid_amount'] ?? 0).toDouble();
    final remaining = total - paid;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade600.withOpacity(0.2),
            Colors.blue.shade600.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.payment_rounded,
                  color: Colors.blue.shade400,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Payment Status',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PaymentInfo(
                'Total',
                'Rs ${total.toStringAsFixed(0)}',
                color: Colors.white,
              ),
              _PaymentInfo(
                'Paid',
                'Rs ${paid.toStringAsFixed(0)}',
                color: Colors.green.shade400,
              ),
              _PaymentInfo(
                'Remaining',
                'Rs ${remaining.toStringAsFixed(0)}',
                color: remaining > 0 ? Colors.orange : Colors.green.shade400,
              ),
            ],
          ),
          if (remaining > 0) ...[
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      AppRoutes.paymentRecode,
                      arguments: {
                        'garment': garment,
                        'client': client,
                      },
                    );
                    if (result == true && context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade600,
                          Colors.blue.shade500,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_circle_rounded, size: 20, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Add Payment Record',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Payment Info Widget
class _PaymentInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _PaymentInfo(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color ?? Colors.white,
          ),
        ),
      ],
    );
  }
}

// Action Button Widget
class _ActionButton extends StatefulWidget {
  final String label;
  final Color color;
  final Color? textColor;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _ActionButton({
    required this.label,
    required this.color,
    this.textColor,
    this.icon,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
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
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? _onTapDown : null,
      onTapUp: widget.onPressed != null ? _onTapUp : null,
      onTapCancel: widget.onPressed != null ? _onTapCancel : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SizedBox(
            height: 56,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.color,
                        widget.color.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(widget.icon, size: 20, color: widget.textColor ?? Colors.white),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                widget.label,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: widget.textColor ?? Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}