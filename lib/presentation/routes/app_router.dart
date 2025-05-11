import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/verify_otp_screen.dart';
import '../screens/auth/send_verification_screen.dart';
import '../screens/auth/set_new_password_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/car/car_details_screen.dart';
import '../screens/splash_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case '/splash':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/welcome':
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case '/signup':
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/send_verification':
        return MaterialPageRoute(builder: (_) => const SendVerificationScreen());
      case '/verify_otp':
        // Extract the arguments
        final args = settings.arguments as Map<String, dynamic>?;
        final phoneNumber = args?['phoneNumber'] as String? ?? '';
        final email = args?['email'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => VerifyOtpScreen(
            email: email,
          ),
        );
      case '/set_new_password':
        return MaterialPageRoute(builder: (_) => const SetNewPasswordScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/car_details':
        // Extract the car ID from arguments
        final args = settings.arguments as Map<String, dynamic>?;
        final carId = args?['carId'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => CarDetailsScreen(carId: carId),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}









