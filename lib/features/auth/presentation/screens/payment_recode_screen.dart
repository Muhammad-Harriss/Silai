import 'package:flutter/material.dart';
import 'package:silai/core/constants/app_colors.dart';
import 'package:silai/core/services/supabase_service.dart';

class AddPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> garment;
  final Map<String, dynamic> client;

  const AddPaymentScreen({
    Key? key,
    required this.garment,
    required this.client,
  }) : super(key: key);

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseService _supabaseService = SupabaseService();
  
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedPaymentMethod = 'Cash';
  bool _isLoading = false;

  final List<String> _paymentMethods = [
    'Cash',
    'Bank Transfer',
    'Card',
    'JazzCash',
    'EasyPaisa',
    'Other',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _price {
    final price = widget.garment['price'];
    if (price == null) return 0.0;
    if (price is int) return price.toDouble();
    if (price is double) return price;
    return double.tryParse(price.toString()) ?? 0.0;
  }

  double get _paidAmount {
    final paid = widget.garment['paid_amount'];
    if (paid == null) return 0.0;
    if (paid is int) return paid.toDouble();
    if (paid is double) return paid;
    return double.tryParse(paid.toString()) ?? 0.0;
  }

  double get _remaining => _price - _paidAmount;

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _supabaseService.currentUser;
      if (user == null) throw Exception('No user logged in');

      await _supabaseService.addPayment(
        garmentId: widget.garment['id'],
        amount: double.parse(_amountController.text),
        paymentMethod: _selectedPaymentMethod,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recorded successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record payment: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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
    final garmentType = widget.garment['garment_type'] ?? 'Unknown';

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Add Payment Record',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 15,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8E8E8),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Order Info
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB8E6C9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      clientName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      garmentType,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const Divider(height: 24, thickness: 1),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildAmountInfo(
                                          'Total',
                                          'Rs ${_price.toStringAsFixed(0)}',
                                          Colors.blue.shade700,
                                        ),
                                        _buildAmountInfo(
                                          'Paid',
                                          'Rs ${_paidAmount.toStringAsFixed(0)}',
                                          Colors.green.shade700,
                                        ),
                                        _buildAmountInfo(
                                          'Remaining',
                                          'Rs ${_remaining.toStringAsFixed(0)}',
                                          Colors.red.shade700,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Payment Amount
                              _buildLabel('Payment Amount'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                decoration: _buildInputDecoration(
                                  hintText: 'Enter amount (Max: Rs ${_remaining.toStringAsFixed(0)})',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter amount';
                                  }
                                  final amount = double.tryParse(value);
                                  if (amount == null || amount <= 0) {
                                    return 'Please enter valid amount';
                                  }
                                  if (amount > _remaining) {
                                    return 'Amount exceeds remaining balance';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Payment Method
                              _buildLabel('Payment Method'),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedPaymentMethod,
                                decoration: _buildInputDecoration(),
                                items: _paymentMethods.map((method) {
                                  return DropdownMenuItem(
                                    value: method,
                                    child: Text(method),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedPaymentMethod = value!);
                                },
                              ),
                              const SizedBox(height: 16),

                              // Notes
                              _buildLabel('Notes (Optional)'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _notesController,
                                maxLines: 3,
                                decoration: _buildInputDecoration(
                                  hintText: 'Add payment notes...',
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _savePayment,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                                ),
                                              )
                                            : const Text(
                                                'Record Payment',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: SizedBox(
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: _isLoading 
                                            ? null 
                                            : () => Navigator.pop(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFE8B4B8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }

  InputDecoration _buildInputDecoration({String? hintText}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildAmountInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}