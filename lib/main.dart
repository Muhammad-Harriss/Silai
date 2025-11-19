import 'package:flutter/material.dart';
import 'package:silai/core/constants/app_colors.dart';
import 'package:silai/core/constants/app_routes.dart';
import 'package:silai/features/auth/presentation/screens/Tailor_client_Manage_Screen.dart';
import 'package:silai/features/auth/presentation/screens/add_client_screen.dart';
import 'package:silai/features/auth/presentation/screens/add_garment_screen.dart';
import 'package:silai/features/auth/presentation/screens/book_appoimnet_screen.dart';
import 'package:silai/features/auth/presentation/screens/client_garment_screen.dart';
import 'package:silai/features/auth/presentation/screens/garment_detail_screen.dart';
import 'package:silai/features/auth/presentation/screens/client_home_screen.dart';
import 'package:silai/features/auth/presentation/screens/client_signin_screen.dart';
import 'package:silai/features/auth/presentation/screens/client_signup_screen.dart';
import 'package:silai/features/auth/presentation/screens/my_orders_screen.dart';
import 'package:silai/features/auth/presentation/screens/payment_recode_screen.dart';
import 'package:silai/features/auth/presentation/screens/profile_setup_screen.dart';
import 'package:silai/features/auth/presentation/screens/select_role_screen.dart';
import 'package:silai/features/auth/presentation/screens/tailor_dashboard_screen.dart';
import 'package:silai/features/auth/presentation/screens/tailor_detail_screen.dart';
import 'package:silai/features/auth/presentation/screens/tailor_home_screen.dart';
import 'package:silai/features/auth/presentation/screens/tailor_map_screen.dart';
import 'package:silai/features/auth/presentation/screens/tailor_signin_screen.dart';
import 'package:silai/features/auth/presentation/screens/tailor_signup_screen.dart';
import 'package:silai/features/auth/presentation/screens/view_booking_screen.dart';
import 'package:silai/features/auth/presentation/screens/welcome_screen.dart';

import 'core/services/supabase_client.dart';
import 'core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseClientManager.init();

  runApp(TailorApp());
}

class TailorApp extends StatelessWidget {
  TailorApp({super.key});

  final SupabaseService _supabaseService = SupabaseService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tailor App',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),

      // Determine initial route based on user login
      home:
          _supabaseService.isLoggedIn
              ? (() {
                final role =
                    _supabaseService.currentUser?.userMetadata?['role']
                        as String?;
                if (role == 'tailor') {
                  return const TailorHomeScreen();
                } else {
                  return const ClientHomeScreen();
                }
              })()
              : const WelcomeScreen(),

      // Use onGenerateRoute for dynamic routing
      onGenerateRoute: (settings) {
        // Handle clientGarments route with arguments
        if (settings.name == AppRoutes.clientGarments) {
          final client = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ClientGarmentScreen(client: client),
          );
        }

        // Handle addGarment route with arguments
        if (settings.name == AppRoutes.addGarments) {
          final client = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => AddGarmentScreen(client: client),
          );
        }

        // Handle garmentDetails route with arguments
        if (settings.name == AppRoutes.garmentDetail) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder:
                (context) => GarmentDetailsScreen(
                  garment: args['garment'],
                  client: args['client'],
                ),
          );
        }

        // Handle addPayment route with arguments
        if (settings.name == AppRoutes.paymentRecode) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder:
                (context) => AddPaymentScreen(
                  garment: args['garment'],
                  client: args['client'],
                ),
          );
        }

        // NEW: Handle tailor detail route with arguments (selected tailor map)
        if (settings.name == AppRoutes.tailorDetail) {
          final tailor = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => TailorDetailsScreen(tailor: tailor),
          );
        }

        // ✅ Handle book appointment route (needs tailor argument)
        if (settings.name == AppRoutes.bookAppointment) {
          final tailor = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => BookAppointmentScreen(tailor: tailor),
          );
        }

         if (settings.name == AppRoutes.tailormap) {
          final tailor = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => TailorMapScreen(tailor: tailor),
          );
        }

        // Handle all other routes
        final routes = <String, WidgetBuilder>{
          AppRoutes.welcome: (context) => const WelcomeScreen(),
          AppRoutes.selectRole: (context) => const SelectRoleScreen(),

          // Tailor Routes
          AppRoutes.tailorSignup: (context) => const TailorSignupScreen(),
          AppRoutes.tailorLogin: (context) => const TailorSignInScreen(),
          AppRoutes.tailorHome: (context) => const TailorHomeScreen(),
          AppRoutes.profileSetup: (context) => const ProfileSetupScreen(),
          AppRoutes.tailorDashboard: (context) => const TailorDashboardScreen(),
          AppRoutes.tailorClientManage:
              (context) => const TailorClientManageScreen(),
          AppRoutes.addClient: (context) => const AddClientScreen(),
          AppRoutes.viewBooking: (context) => const ViewBookingScreen(),

          // Client Routes
          AppRoutes.clientSignup: (context) => const ClientSignupScreen(),
          AppRoutes.clientLogin: (context) => const ClientSignInScreen(),
          AppRoutes.clientHome: (context) => const ClientHomeScreen(),
          AppRoutes.myorder: (context) => const MyOrdersScreen(),
         
        };

        final builder = routes[settings.name];
        if (builder != null) {
          return MaterialPageRoute(builder: builder);
        }

        // Route not found
        return MaterialPageRoute(
          builder:
              (context) => Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: Center(child: Text('Route ${settings.name} not found')),
              ),
        );
      },
    );
  }
}
