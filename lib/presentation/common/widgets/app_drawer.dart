import 'package:flutter/material.dart';
import '../../../services/user_service.dart';
import '../../models/user.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await UserService.getUser();
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  Future<void> _logout(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Clear user data
    await UserService.clearUser();

    // Close loading indicator
    if (context.mounted) {
      Navigator.pop(context);
    }

    // Navigate to welcome screen
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Drawer header with user info
          Container(
            padding: const EdgeInsets.only(top: 40, bottom: 20, left: 20, right: 20),
            color: Colors.white,
            child: Column(
              children: [
                // Back button
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const Text('Back'),
                  ],
                ),
                const SizedBox(height: 20),
                // User profile
                _isLoading
                    ? const CircularProgressIndicator()
                    : Row(
                        children: [
                          // User avatar
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: _user?.profilePicture != null 
                                ? NetworkImage(_user!.profilePicture) 
                                : null,
                            child: _user?.profilePicture == null
                                ? const Icon(Icons.person, size: 30, color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(width: 15),
                          // User name and email
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _user?.fullName ?? 'Guest User',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _user?.email ?? 'Not logged in',
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
              ],
            ),
          ),
          // Drawer menu items
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.home,
                    title: 'Home',
                    onTap: () {
                      // Navigate to home screen
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('My Booking History'),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer
                      Navigator.pushNamed(context, '/client/bookings');
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.car_rental,
                    title: 'Get a Car to Rent or Sell?',
                    onTap: () {
                      // Navigate to car listing screen
                      Navigator.pop(context);
                      // Add navigation logic here
                    },
                  ),
                  // Only show "Become a Car Owner" if user is not already an OWNER or ADMIN
                  if (_user == null || (!_user!.roles.contains('OWNER') && !_user!.roles.contains('ADMIN')))
                    _buildMenuItem(
                      context,
                      icon: Icons.verified_user,
                      title: 'Become a Car Owner',
                      onTap: () {
                        // Navigate to become owner screen
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/become_owner');
                      },
                    ),
                    // Show "My Cars" only for OWNER role
                  if (_user != null && _user!.roles.contains('OWNER'))
                    _buildMenuItem(
                      context,
                      icon: Icons.directions_car,
                      title: 'My Cars',
                      onTap: () {
                        // Navigate to owner cars screen
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/owner/cars');
                      },
                    ),
                  // Show "My Bookings" only for OWNER role
                  if (_user != null && _user!.roles.contains('OWNER'))
                    _buildMenuItem(
                      context,
                      icon: Icons.book_online,
                      title: 'My Bookings',
                      onTap: () {
                        // Navigate to owner bookings screen
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/owner/bookings');
                      },
                    ),
                  // Admin section - only show if user is admin
                  if (_user != null && _user!.roles.contains('ADMIN')) ...[
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/admin/dashboard');
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.admin_panel_settings,
                      title: 'Role Requests',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/admin/role_requests');
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.people,
                      title: 'Manage Users',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/admin/users');
                      },
                    ),
                    // Add more admin menu items here
                    const Divider(), // Added divider to separate admin section from other menu items
                  ],
                  _buildMenuItem(
                    context,
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () {
                      // Navigate to settings screen
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline,
                    title: 'Help and Support',
                    onTap: () {
                      // Navigate to help screen
                      Navigator.pop(context);
                      // Add navigation logic here
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: () {
                      // Logout logic
                      Navigator.pop(context);
                      _logout(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.grey[800],
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }
}














