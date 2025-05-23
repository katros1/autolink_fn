import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App logo
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Image.asset(
                  'assets/icon/icon.png',
                  width: 120,
                  height: 120,
                ),
              ),
            ),
            
            // App name and version
            const Center(
              child: Text(
                'AutoLink',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 24.0),
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            
            // About us description
            const Text(
              'About Us',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'AutoLink is a mobile application designed to connect car owners with potential renters and buyers. The platform allows individuals and businesses to easily list their vehicles for rent or sale, providing customers with a seamless way to browse, compare, and book cars based on their needs.',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Contact information
            const Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactItem(Icons.email, 'Email', 'support@autolink.com'),
            _buildContactItem(Icons.phone, 'Phone', '+1 (123) 456-7890'),
            _buildContactItem(Icons.language, 'Website', 'www.autolink.com'),
            
            const SizedBox(height: 32),
            
            // Social media links
            const Text(
              'Follow Us',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSocialButton(Icons.facebook, 'Facebook'),
                _buildSocialButton(Icons.camera_alt, 'Instagram'),
                _buildSocialButton(Icons.telegram, 'Twitter'),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Copyright
            const Center(
              child: Text(
                '© 2023 AutoLink. All rights reserved.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContactItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00A651)), // Green color
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(value),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSocialButton(IconData icon, String platform) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFF00A651), // Green color
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(platform),
      ],
    );
  }
}

