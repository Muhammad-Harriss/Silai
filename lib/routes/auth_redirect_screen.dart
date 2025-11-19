import 'package:flutter/material.dart';
import 'package:silai/core/constants/app_colors.dart';
import 'package:silai/core/constants/app_routes.dart';
import 'package:silai/core/services/supabase_service.dart';

/// This screen checks if the user has completed their profile
/// and redirects them to the appropriate screen
class AuthRedirectScreen extends StatefulWidget {
  const AuthRedirectScreen({Key? key}) : super(key: key);

  @override
  State<AuthRedirectScreen> createState() => _AuthRedirectScreenState();
}

class _AuthRedirectScreenState extends State<AuthRedirectScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _checkProfileAndRedirect();
  }

  Future<void> _checkProfileAndRedirect() async {
    try {
      final user = _supabaseService.currentUser;
      
      if (user == null) {
        // No user logged in, go to welcome
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.welcome);
        }
        return;
      }

      // Get user profile
      final profile = await _supabaseService.getProfile(user.id);
      
      if (profile == null) {
        // Profile not found, go to welcome
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.welcome);
        }
        return;
      }

      final role = profile['role']?.toString().toLowerCase();
      
      if (role == 'tailor') {
        // Check if tailor profile is complete
        final isProfileComplete = profile['shop_name'] != null && 
                                  profile['phone_number'] != null &&
                                  profile['shop_name'].toString().isNotEmpty &&
                                  profile['phone_number'].toString().isNotEmpty;
        
        if (mounted) {
          if (isProfileComplete) {
            // Profile complete, go to dashboard
            Navigator.pushReplacementNamed(context, AppRoutes.tailorDashboard);
          } else {
            // Profile incomplete, go to profile setup
            Navigator.pushReplacementNamed(context, AppRoutes.profileSetup);
          }
        }
      } else if (role == 'client') {
        // Client goes to their home screen
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.clientHome);
        }
      } else {
        // Unknown role, go to welcome
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.welcome);
        }
      }
    } catch (e) {
      // Error occurred, go to welcome
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.welcome);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}