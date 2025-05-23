import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              Image.asset(
                'assets/images/welcome_car.png',
                height: 240,
              ),
              const SizedBox(height: 40),
              const Text(
                'Welcome',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Have a better renting experience',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  // Navigate to create account screen
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SignupScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Create an account'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  // Navigate to login screen
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: Colors.green),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Log in'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

