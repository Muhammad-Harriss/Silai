import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

/// Handles user authentication, profile creation, and data access.
class SupabaseService {
  final SupabaseClient _client = SupabaseClientManager.client;

  /// 🔹 Sign up new user (Tailor or Client)
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role, // "tailor" or "client"
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': role,
      },
    );

    final user = response.user;
    if (user != null) {
      // Create a record in 'profiles' table
      await _client.from('profiles').insert({
        'id': user.id,
        'full_name': fullName,
        'email': email,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    return response;
  }

  /// 🔹 Sign in existing user
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  /// 🔹 Sign out current user
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// 🔹 Whether a user is logged in
  bool get isLoggedIn => _client.auth.currentUser != null;

  /// 🔹 Currently logged-in user
  User? get currentUser => _client.auth.currentUser;

  /// 🔹 Fetch user profile info from 'profiles' table
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response =
        await _client.from('profiles').select().eq('id', userId).maybeSingle();

    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  /// 🔹 Update user profile
  Future<void> updateProfile(String userId, Map<String, dynamic> updates) async {
    await _client.from('profiles').update(updates).eq('id', userId);
  }

  /// 🔹 Upload a file (image, measurement image, etc.)
  /// `file` must be a `File` object from dart:io
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required File file,
  }) async {
    // Upload file to Supabase Storage
    await _client.storage.from(bucket).upload(
      path,
      file,
      fileOptions: const FileOptions(
        cacheControl: '3600',
        upsert: true,
      ),
    );

    // Return a public URL (if bucket is public)
    final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
    return publicUrl;
  }

  /// 🔹 Delete a file from storage
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    await _client.storage.from(bucket).remove([path]);
  }

  /// 🔹 Get current user's full profile (including auth metadata)
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;
    return getProfile(user.id);
  }

  // ============================================
  // CLIENT MANAGEMENT METHODS
  // ============================================

  /// 🔹 Get all clients for a tailor
  Future<List<Map<String, dynamic>>> getClientsByTailorId(String tailorId) async {
    final response = await _client
        .from('clients')
        .select()
        .eq('tailor_id', tailorId)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// 🔹 Add a new client
  Future<Map<String, dynamic>> addClient({
    required String tailorId,
    required String fullName,
    required String contact,
    String? email,
    File? profileImage,
  }) async {
    String? imageUrl;

    // Upload profile image if provided
    if (profileImage != null) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$fullName.jpg';
      imageUrl = await uploadFile(
        bucket: 'clients',
        path: 'avatars/$fileName',
        file: profileImage,
      );
    }

    final response = await _client.from('clients').insert({
      'tailor_id': tailorId,
      'full_name': fullName,
      'contact': contact,
      'email': email,
      'profile_image': imageUrl,
      'suits_count': 0,
      'payment_status': 'pending',
    }).select().single();

    return Map<String, dynamic>.from(response);
  }

  /// 🔹 Update a client
  Future<void> updateClient(String clientId, Map<String, dynamic> updates) async {
    await _client.from('clients').update(updates).eq('id', clientId);
  }

  /// 🔹 Delete a client
  Future<void> deleteClient(String clientId) async {
    await _client.from('clients').delete().eq('id', clientId);
  }

  /// 🔹 Get a single client by ID
  Future<Map<String, dynamic>?> getClientById(String clientId) async {
    final response = await _client
        .from('clients')
        .select()
        .eq('id', clientId)
        .maybeSingle();

    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  /// 🔹 Search clients by name or contact
  Future<List<Map<String, dynamic>>> searchClients(String tailorId, String query) async {
    final response = await _client
        .from('clients')
        .select()
        .eq('tailor_id', tailorId)
        .or('full_name.ilike.%$query%,contact.ilike.%$query%')
        .order('created_at', ascending: false);
    
  return List<Map<String, dynamic>>.from(response);
  }

  /// 🔹 Get total clients count for a tailor
  Future<int> getClientsCount(String tailorId) async {
    final response = await _client
        .from('clients')
        .select('id')
        .eq('tailor_id', tailorId)
        .count(CountOption.exact);
    
    return response.count;
  }

  /// 🔹 Update client suits count
  Future<void> updateClientSuitsCount(String clientId, int count) async {
    await _client.from('clients').update({
      'suits_count': count,
    }).eq('id', clientId);
  }

  /// 🔹 Update client payment status
  Future<void> updateClientPaymentStatus(String clientId, String status) async {
    await _client.from('clients').update({
      'payment_status': status,
    }).eq('id', clientId);
  }

  // ============================================
  // GARMENT MANAGEMENT METHODS
  // ============================================

  /// 🔹 Get all garments for a client
  Future<List<Map<String, dynamic>>> getGarmentsByClientId(String clientId) async {
    final response = await _client
        .from('garments')
        .select()
        .eq('client_id', clientId)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// 🔹 Get all garments for a tailor
  Future<List<Map<String, dynamic>>> getGarmentsByTailorId(String tailorId) async {
    final response = await _client
        .from('garments')
        .select()
        .eq('tailor_id', tailorId)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// 🔹 Add a new garment
  Future<Map<String, dynamic>> addGarment({
    required String clientId,
    required String tailorId,
    required String garmentType,
    String? status,
    DateTime? deliveryDate,
    double? price,
    String? notes,
    Map<String, dynamic>? measurements,
  }) async {
    final response = await _client.from('garments').insert({
      'client_id': clientId,
      'tailor_id': tailorId,
      'garment_type': garmentType,
      'status': status ?? 'pending',
      'delivery_date': deliveryDate?.toIso8601String(),
      'price': price ?? 0,
      'notes': notes,
      'measurements': measurements,
    }).select().single();

    return Map<String, dynamic>.from(response);
  }

  /// 🔹 Update a garment
  Future<void> updateGarment(String garmentId, Map<String, dynamic> updates) async {
    await _client.from('garments').update(updates).eq('id', garmentId);
  }

  /// 🔹 Delete a garment
  Future<void> deleteGarment(String garmentId) async {
    await _client.from('garments').delete().eq('id', garmentId);
  }

  /// 🔹 Get garment by ID
  Future<Map<String, dynamic>?> getGarmentById(String garmentId) async {
    final response = await _client
        .from('garments')
        .select()
        .eq('id', garmentId)
        .maybeSingle();

    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  /// 🔹 Update garment status
  Future<void> updateGarmentStatus(String garmentId, String status) async {
    await _client.from('garments').update({
      'status': status,
    }).eq('id', garmentId);
  }

  /// 🔹 Get garments count by status for a tailor
  Future<Map<String, int>> getGarmentsCountByStatus(String tailorId) async {
    final response = await _client
        .from('garments')
        .select('status')
        .eq('tailor_id', tailorId);
    
    final garments = List<Map<String, dynamic>>.from(response);
    final counts = <String, int>{};
    
    for (var garment in garments) {
      final status = garment['status']?.toString() ?? 'unknown';
      counts[status] = (counts[status] ?? 0) + 1;
    }
    
    return counts;
  }

  // ============================================
  // PAYMENT MANAGEMENT METHODS
  // ============================================

  /// 🔹 Add a payment record
  Future<Map<String, dynamic>> addPayment({
    required String garmentId,
    required double amount,
    required String paymentMethod,
    String? notes,
  }) async {
    final response = await _client.from('payments').insert({
      'garment_id': garmentId,
      'amount': amount,
      'payment_method': paymentMethod,
      'notes': notes,
    }).select().single();

    return Map<String, dynamic>.from(response);
  }

  /// 🔹 Get all payments for a garment
  Future<List<Map<String, dynamic>>> getPaymentsByGarmentId(String garmentId) async {
    final response = await _client
        .from('payments')
        .select()
        .eq('garment_id', garmentId)
        .order('payment_date', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// 🔹 Get total pending payments for a tailor
  Future<double> getTotalPendingPayments(String tailorId) async {
    final response = await _client
        .from('garments')
        .select('price, paid_amount')
        .eq('tailor_id', tailorId);
    
    final garments = List<Map<String, dynamic>>.from(response);
    double totalPending = 0;
    
    for (var garment in garments) {
      final price = (garment['price'] ?? 0).toDouble();
      final paid = (garment['paid_amount'] ?? 0).toDouble();
      totalPending += (price - paid);
    }
    
    return totalPending;
  }

  /// 🔹 Delete a payment
  Future<void> deletePayment(String paymentId) async {
    await _client.from('payments').delete().eq('id', paymentId);
  }

  /// 🔹 Get active orders (in_progress status) for a tailor
  Future<int> getActiveOrdersCount(String tailorId) async {
    final response = await _client
        .from('garments')
        .select('id')
        .eq('tailor_id', tailorId)
        .eq('status', 'in_progress')
        .count(CountOption.exact);
    
    return response.count;
  }

  // ============================================
  // CLIENT-SIDE METHODS (For finding tailors)
  // ============================================

  /// 🔹 Get all tailors (for client to find)
  Future<List<Map<String, dynamic>>> getAllTailors() async {
    final response = await _client
        .from('profiles')
        .select('id, full_name, email, shop_name, address, phone_number, working_hours, profile_image, verified')
        .eq('role', 'tailor')
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// 🔹 Search tailors by name or location
  Future<List<Map<String, dynamic>>> searchTailors(String query) async {
    final response = await _client
        .from('profiles')
        .select('id, full_name, email, shop_name, address, phone_number, working_hours, profile_image, verified')
        .eq('role', 'tailor')
        .or('shop_name.ilike.%$query%,address.ilike.%$query%,full_name.ilike.%$query%');
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// 🔹 Get verified tailors only
  Future<List<Map<String, dynamic>>> getVerifiedTailors() async {
    final response = await _client
        .from('profiles')
        .select('id, full_name, email, shop_name, address, phone_number, working_hours, profile_image, verified')
        .eq('role', 'tailor')
        .eq('verified', true)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================
  // BOOKING MANAGEMENT METHODS
  // ============================================

  /// 🔹 Create a booking
  Future<Map<String, dynamic>> createBooking({
    required String clientId,
    required String tailorId,
    required String clientName,
    required String clientAddress,
    required String serviceType,
    required DateTime bookingDate,
    required TimeOfDay bookingTime,
    String? additionalNotes,
  }) async {
    final response = await _client.from('bookings').insert({
      'client_id': clientId,
      'tailor_id': tailorId,
      'client_name': clientName,
      'client_address': clientAddress,
      'service_type': serviceType,
      'booking_date': bookingDate.toIso8601String().split('T')[0],
      'booking_time': '${bookingTime.hour.toString().padLeft(2, '0')}:${bookingTime.minute.toString().padLeft(2, '0')}:00',
      'additional_notes': additionalNotes,
      'status': 'pending',
    }).select().single();

    return Map<String, dynamic>.from(response);
  }

  /// 🔹 Get bookings for a client
  Future<List<Map<String, dynamic>>> getClientBookings(String clientId) async {
    final response = await _client
        .from('bookings')
        .select()
        .eq('client_id', clientId)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// 🔹 Get bookings for a tailor
  Future<List<Map<String, dynamic>>> getTailorBookings(String tailorId) async {
    final response = await _client
        .from('bookings')
        .select()
        .eq('tailor_id', tailorId)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// 🔹 Get bookings for current tailor (helper method)
  Future<List<Map<String, dynamic>>> getBookingsForTailor() async {
    final user = currentUser;
    if (user == null) return [];
    return getTailorBookings(user.id);
  }

  /// 🔹 Update booking status
  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _client.from('bookings').update({
      'status': status,
    }).eq('id', bookingId);
  }

  // ============================================
  // REVIEW MANAGEMENT METHODS
  // ============================================

  /// 🔹 Add a review
  Future<Map<String, dynamic>> addReview({
    required String tailorId,
    required String clientId,
    required String clientName,
    required int rating,
    required String reviewText,
  }) async {
    final response = await _client.from('reviews').insert({
      'tailor_id': tailorId,
      'client_id': clientId,
      'client_name': clientName,
      'rating': rating,
      'review_text': reviewText,
    }).select().single();

    return Map<String, dynamic>.from(response);
  }

  /// 🔹 Get reviews for a tailor
  Future<List<Map<String, dynamic>>> getReviewsByTailorId(String tailorId) async {
    final response = await _client
        .from('reviews')
        .select()
        .eq('tailor_id', tailorId)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// 🔹 Delete a review
  Future<void> deleteReview(String reviewId) async {
    await _client.from('reviews').delete().eq('id', reviewId);
  }

  // ============================================
// ORDER MANAGEMENT METHODS (Add to SupabaseService)
// ============================================

/// 🔹 Create an order (when client books a tailor)
Future<Map<String, dynamic>> createOrder({
  required String clientId,
  required String tailorId,
  required String tailorShopName,
  required String orderDescription,
  required double totalAmount,
  String? status,
}) async {
  final response = await _client.from('orders').insert({
    'client_id': clientId,
    'tailor_id': tailorId,
    'tailor_shop_name': tailorShopName,
    'order_description': orderDescription,
    'total_amount': totalAmount,
    'status': status ?? 'pending',
    'created_at': DateTime.now().toIso8601String(),
  }).select().single();

  return Map<String, dynamic>.from(response);
}

/// 🔹 Get all orders for a client
Future<List<Map<String, dynamic>>> getClientOrders({
  required String userId,
  String? status,
}) async {
  var query = _client
      .from('orders')
      .select()
      .eq('client_id', userId);

  // Filter by status if provided
  if (status != null && status.isNotEmpty) {
    query = query.eq('status', status);
  }

  final response = await query.order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
}

/// 🔹 Get all orders for a tailor
Future<List<Map<String, dynamic>>> getTailorOrders({
  required String tailorId,
  String? status,
}) async {
  var query = _client
      .from('orders')
      .select()
      .eq('tailor_id', tailorId);

  // Filter by status if provided
  if (status != null && status.isNotEmpty) {
    query = query.eq('status', status);
  }

  final response = await query.order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
}

/// 🔹 Get a single order by ID
Future<Map<String, dynamic>?> getOrderById(String orderId) async {
  final response = await _client
      .from('orders')
      .select()
      .eq('id', orderId)
      .maybeSingle();

  if (response == null) return null;
  return Map<String, dynamic>.from(response);
}

/// 🔹 Update order status
Future<void> updateOrderStatus(String orderId, String status) async {
  await _client.from('orders').update({
    'status': status,
  }).eq('id', orderId);
}

/// 🔹 Update order details
Future<void> updateOrder(String orderId, Map<String, dynamic> updates) async {
  await _client.from('orders').update(updates).eq('id', orderId);
}

/// 🔹 Delete an order
Future<void> deleteOrder(String orderId) async {
  await _client.from('orders').delete().eq('id', orderId);
}

/// 🔹 Get orders count by status for a client
Future<Map<String, int>> getClientOrdersCountByStatus(String clientId) async {
  final response = await _client
      .from('orders')
      .select('status')
      .eq('client_id', clientId);

  final orders = List<Map<String, dynamic>>.from(response);
  final counts = <String, int>{};

  for (var order in orders) {
    final status = order['status']?.toString() ?? 'unknown';
    counts[status] = (counts[status] ?? 0) + 1;
  }

  return counts;
}

/// 🔹 Get total spent by a client
Future<double> getClientTotalSpent(String clientId) async {
  final response = await _client
      .from('orders')
      .select('total_amount')
      .eq('client_id', clientId);

  final orders = List<Map<String, dynamic>>.from(response);
  double total = 0;

  for (var order in orders) {
    final amount = (order['total_amount'] ?? 0).toDouble();
    total += amount;
  }

  return total;
}

/// 🔹 Search client orders by tailor name or description
Future<List<Map<String, dynamic>>> searchClientOrders({
  required String clientId,
  required String query,
}) async {
  final response = await _client
      .from('orders')
      .select()
      .eq('client_id', clientId)
      .or('tailor_shop_name.ilike.%$query%,order_description.ilike.%$query%')
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
}

/// 🔹 Accept an order (tailor accepts client's order)
Future<void> acceptOrder(String orderId) async {
  await _client.from('orders').update({
    'status': 'Accepted',
  }).eq('id', orderId);
}

/// 🔹 Complete an order
Future<void> completeOrder(String orderId) async {
  await _client.from('orders').update({
    'status': 'Completed',
    'completed_at': DateTime.now().toIso8601String(),
  }).eq('id', orderId);
}

/// 🔹 Cancel an order
Future<void> cancelOrder(String orderId) async {
  await _client.from('orders').update({
    'status': 'Cancelled',
    'cancelled_at': DateTime.now().toIso8601String(),
  }).eq('id', orderId);
}
}