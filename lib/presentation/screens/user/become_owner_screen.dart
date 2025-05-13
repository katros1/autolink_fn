import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import '../../../services/user_service.dart';
import '../../common/widgets/app_drawer.dart';

class BecomeOwnerScreen extends StatefulWidget {
  const BecomeOwnerScreen({super.key});

  @override
  State<BecomeOwnerScreen> createState() => _BecomeOwnerScreenState();
}

class _BecomeOwnerScreenState extends State<BecomeOwnerScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _submitOwnerRequest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Get user token
      final user = await UserService.getUser();
      if (user == null || user.token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'You must be logged in to request owner status';
        });
        return;
      }

      // For Android emulator, use 10.0.2.2 instead of localhost
      // For iOS simulator, use localhost
      final baseUrl = Platform.isAndroid ? 'http://10.0.2.2:8070' : 'http://localhost:8070';
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/roles/request?requestedRole=OWNER'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Request successful
        final responseData = jsonDecode(response.body);
        setState(() {
          _successMessage = responseData['message'] ?? 'Your request has been submitted successfully!';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_successMessage!)),
        );
      } else {
        // Request failed
        final errorData = jsonDecode(response.body);
        setState(() {
          _errorMessage = errorData['message'] ?? 'Failed to submit request. Please try again.';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Car Owner'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Become a Car Owner',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Description
              const Text(
                'As a car owner, you can list your vehicles for rent or sale on our platform. '
                'Submit your request to become a verified car owner and start earning today!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              
              // Benefits section
              const Text(
                'Benefits of becoming a car owner:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildBenefitItem(
                icon: Icons.monetization_on,
                title: 'Earn Extra Income',
                description: 'Make money by renting or selling your vehicles',
              ),
              _buildBenefitItem(
                icon: Icons.schedule,
                title: 'Flexible Schedule',
                description: 'You decide when your car is available',
              ),
              _buildBenefitItem(
                icon: Icons.verified_user,
                title: 'Verified Status',
                description: 'Get a verified owner badge on your profile',
              ),
              _buildBenefitItem(
                icon: Icons.support_agent,
                title: 'Dedicated Support',
                description: 'Access to priority customer service',
              ),
              
              const SizedBox(height: 32),
              
              // Success message
              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 32),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitOwnerRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.green),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
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
