import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import '../../../services/user_service.dart';
import '../../common/widgets/app_drawer.dart';
import '../../../utils/api_config.dart';

class AdminUser {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final List<String> roles;
  final String phoneNumber;
  final String country;
  final String profilePicUrl;
  final String accountStatus;
  final bool verified;

  AdminUser({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.roles,
    required this.phoneNumber,
    required this.country,
    required this.profilePicUrl,
    required this.accountStatus,
    required this.verified,
  });

  String get fullName => '$firstName $lastName';

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      userId: json['userId'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      roles: List<String>.from(json['roles'] ?? []),
      phoneNumber: json['phoneNumber'] ?? '',
      country: json['country'] ?? '',
      profilePicUrl: json['profilePicUrl'] ?? '',
      accountStatus: json['accountStatus'] ?? '',
      verified: json['verified'] ?? false,
    );
  }
}

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<AdminUser> _users = [];
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalUsers = 0;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
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
          _errorMessage = 'You must be logged in as an admin to view this page';
        });
        return;
      }

      // For Android emulator, use 10.0.2.2 instead of localhost
      // For iOS simulator, use localhost
      final baseUrl = ApiConfig.baseUrl;
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/admin/users?page=$_currentPage&size=10'),
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
        final data = responseData['data'];
        final List<dynamic> usersData = data['content'];
        
        setState(() {
          _users = usersData.map((data) => AdminUser.fromJson(data)).toList();
          _currentPage = data['page'];
          _totalPages = data['totalPages'];
          _totalUsers = data['totalElements'];
        });
      } else {
        // Request failed
        final errorData = jsonDecode(response.body);
        setState(() {
          _errorMessage = errorData['message'] ?? 'Failed to fetch users. Please try again.';
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

  Future<void> _refreshUsers() async {
    _currentPage = 0;
    await _fetchUsers();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() {
        _currentPage++;
      });
      _fetchUsers();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _fetchUsers();
    }
  }

  Future<void> _toggleUserStatus(AdminUser user) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get user token
      final currentUser = await UserService.getUser();
      if (currentUser == null || currentUser.token == null) {
        setState(() {
          _isLoading = false;
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
      final isActive = user.accountStatus == 'ACTIVE';
      final endpoint = isActive ? 'deactivate' : 'activate';
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/v1/admin/users/${user.userId}/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${currentUser.token}',
        },
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        // Request successful
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ${isActive ? 'deactivated' : 'activated'} successfully')),
        );
        
        // Refresh the list
        _fetchUsers();
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
        title: const Text('Manage Users'),
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : RefreshIndicator(
                  onRefresh: _refreshUsers,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Users: $_totalUsers',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  onPressed: _currentPage > 0 ? _previousPage : null,
                                ),
                                Text('${_currentPage + 1} / $_totalPages'),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward),
                                  onPressed: _currentPage < _totalPages - 1 ? _nextPage : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(user.profilePicUrl),
                                ),
                                title: Text(user.fullName),
                                subtitle: Text(user.email),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Chip(
                                      label: Text(
                                        user.accountStatus,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      backgroundColor: user.accountStatus == 'ACTIVE'
                                          ? Colors.green[100]
                                          : Colors.red[100],
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  final result = await Navigator.pushNamed(
                                    context,
                                    '/admin/user_details',
                                    arguments: user.userId,
                                  );
                                  
                                  // Refresh the list if we got a result indicating changes
                                  if (result == true) {
                                    _fetchUsers();
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
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
}





