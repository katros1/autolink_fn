import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import '../../../services/user_service.dart';
import 'package:intl/intl.dart';
import '../../../utils/api_config.dart';

class UserDetailsScreen extends StatefulWidget {
  final String userId;

  const UserDetailsScreen({super.key, required this.userId});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _userData;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get user token
      final user = await UserService.getUser();
      if (user == null || user.token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'You must be logged in as an admin to view user details';
        });
        return;
      }

      // For Android emulator, use 10.0.2.2 instead of localhost
      // For iOS simulator, use localhost
      final baseUrl = ApiConfig.baseUrl;
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/admin/users/${widget.userId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        // Request successful
        final responseData = jsonDecode(response.body);
        setState(() {
          _userData = responseData['data'];
        });
      } else {
        // Request failed
        final errorData = jsonDecode(response.body);
        setState(() {
          _errorMessage = errorData['message'] ?? 'Failed to fetch user details. Please try again.';
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

  Future<void> _toggleUserStatus() async {
    if (_userData == null) return;
    
    final currentStatus = _userData!['accountStatus'];
    final isActive = currentStatus == 'ACTIVE';
    
    setState(() {
      _isProcessing = true;
    });

    try {
      // Get user token
      final user = await UserService.getUser();
      if (user == null || user.token == null) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'You must be logged in as an admin to update user status';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
        return;
      }

      // For Android emulator, use 10.0.2.2 instead of localhost
      // For iOS simulator, use localhost
      final baseUrl = ApiConfig.baseUrl;
      
      // Use the appropriate endpoint based on the current status
      final endpoint = isActive ? 'deactivate' : 'activate';
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/v1/admin/users/${widget.userId}/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
      );

      setState(() {
        _isProcessing = false;
      });

      if (response.statusCode == 200) {
        // Request successful
        final newStatus = isActive ? 'INACTIVE' : 'ACTIVE';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ${isActive ? 'deactivated' : 'activated'} successfully')),
        );
        
        // Refresh user details
        await _fetchUserDetails();
      } else {
        // Request failed
        final errorData = jsonDecode(response.body);
        setState(() {
          _errorMessage = errorData['message'] ?? 'Failed to update user status. Please try again.';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'ADMIN':
        return Colors.red[100]!;
      case 'OWNER':
        return Colors.purple[100]!;
      case 'CLIENT':
        return Colors.green[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Set result to true when navigating back
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('User Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Return to the previous screen with a result
              Navigator.pop(context, true);
            },
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : _userData == null
                    ? const Center(child: Text('No user data found'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User header with profile picture
                            Center(
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundImage: NetworkImage(_userData!['profilePicUrl'] ?? ''),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '${_userData!['firstName']} ${_userData!['lastName']}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Chip(
                                    label: Text(
                                      _userData!['accountStatus'] ?? 'UNKNOWN',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: (_userData!['accountStatus'] ?? '') == 'ACTIVE'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // User roles
                            const Text(
                              'Roles',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: ((_userData!['roles'] ?? []) as List<dynamic>).map((role) {
                                return Chip(
                                  label: Text(
                                    role.toString(),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  backgroundColor: _getRoleColor(role.toString()),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                            
                            // User information
                            const Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow('Email', _userData!['email'] ?? 'N/A'),
                            _buildInfoRow('Phone', _userData!['phoneNumber'] ?? 'N/A'),
                            _buildInfoRow('Gender', _userData!['gender'] ?? 'N/A'),
                            _buildInfoRow('Country', _userData!['country'] ?? 'N/A'),
                            _buildInfoRow('Date of Birth', _formatDate(_userData!['dob'])),
                            _buildInfoRow('Verified', (_userData!['verified'] ?? false) ? 'Yes' : 'No'),
                            const SizedBox(height: 24),
                            
                            // Account information
                            const Text(
                              'Account Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow('User ID', _userData!['userId'] ?? 'N/A'),
                            _buildInfoRow('Created At', _formatDate(_userData!['createdAt'])),
                            _buildInfoRow('Updated At', _formatDate(_userData!['updatedAt'])),
                            const SizedBox(height: 32),
                            
                            // Action buttons
                            Center(
                              child: Column(
                                children: [
                                  ElevatedButton(
                                    onPressed: _isProcessing ? null : _toggleUserStatus,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: (_userData!['accountStatus'] ?? '') == 'ACTIVE'
                                          ? Colors.red
                                          : Colors.green,
                                      minimumSize: const Size(200, 50),
                                    ),
                                    child: _isProcessing
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : Text(
                                            (_userData!['accountStatus'] ?? '') == 'ACTIVE'
                                                ? 'Deactivate User'
                                                : 'Activate User',
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}







