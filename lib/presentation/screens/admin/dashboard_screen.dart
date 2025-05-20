import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:fl_chart/fl_chart.dart';
import '../../../services/user_service.dart';
import '../../common/widgets/app_drawer.dart';
import '../../../utils/api_config.dart';

class DashboardStats {
  final int totalCars;
  final int totalRenters;
  final int totalOwners;
  final int totalBookings;
  final int successfulBookings;
  final int pendingBookings;
  final int rejectedBookings;
  final int canceledBookings;
  final int availableCars;
  final int unavailableCars;
  final int carsForRent;
  final int carsForSale;

  DashboardStats({
    required this.totalCars,
    required this.totalRenters,
    required this.totalOwners,
    required this.totalBookings,
    required this.successfulBookings,
    required this.pendingBookings,
    required this.rejectedBookings,
    required this.canceledBookings,
    required this.availableCars,
    required this.unavailableCars,
    required this.carsForRent,
    required this.carsForSale,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalCars: json['totalCars'] ?? 0,
      totalRenters: json['totalRenters'] ?? 0,
      totalOwners: json['totalOwners'] ?? 0,
      totalBookings: json['totalBookings'] ?? 0,
      successfulBookings: json['successfulBookings'] ?? 0,
      pendingBookings: json['pendingBookings'] ?? 0,
      rejectedBookings: json['rejectedBookings'] ?? 0,
      canceledBookings: json['canceledBookings'] ?? 0,
      availableCars: json['availableCars'] ?? 0,
      unavailableCars: json['unavailableCars'] ?? 0,
      carsForRent: json['carsForRent'] ?? 0,
      carsForSale: json['carsForSale'] ?? 0,
    );
  }
}

class LegendItem {
  final Color color;
  final String label;
  final int value;
  final int total;

  LegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.total,
  });

  double get percentage => total > 0 ? (value / total) * 100 : 0;
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  DashboardStats? _stats;

  @override
  void initState() {
    super.initState();
    _fetchDashboardStats();
  }

  Future<void> _fetchDashboardStats() async {
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
        Uri.parse('$baseUrl/api/v1/admin/dashboard'),
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
        
        if (data == null) {
          setState(() {
            _errorMessage = 'Invalid response format: missing data field';
          });
          return;
        }
        
        try {
          setState(() {
            _stats = DashboardStats.fromJson(data);
          });
        } catch (e) {
          setState(() {
            _errorMessage = 'Error parsing dashboard data: ${e.toString()}';
          });
          print('Error parsing dashboard data: $e');
          print('Response data: $data');
        }
      } else {
        // Request failed
        final errorData = jsonDecode(response.body);
        setState(() {
          _errorMessage = errorData['message'] ?? 'Failed to fetch dashboard stats. Please try again.';
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
      
      print('Dashboard fetch error: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _stats == null
                  ? const Center(child: Text('No dashboard data found'))
                  : RefreshIndicator(
                      onRefresh: _fetchDashboardStats,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'System Overview',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // User stats
                            _buildStatSection(
                              'Users',
                              [
                                _buildStatCard('Total Owners', _stats!.totalOwners.toString(), Icons.person, Colors.blue),
                                _buildStatCard('Total Renters', _stats!.totalRenters.toString(), Icons.people, Colors.green),
                              ],
                            ),
                            
                            // Car stats
                            _buildStatSection(
                              'Cars',
                              [
                                _buildStatCard('Total Cars', _stats!.totalCars.toString(), Icons.directions_car, Colors.orange),
                                _buildStatCard('Available Cars', _stats!.availableCars.toString(), Icons.check_circle, Colors.green),
                                _buildStatCard('Unavailable Cars', _stats!.unavailableCars.toString(), Icons.cancel, Colors.red),
                              ],
                            ),
                            
                            // Car listing stats
                            _buildStatSection(
                              'Car Listings',
                              [
                                _buildStatCard('For Rent', _stats!.carsForRent.toString(), Icons.car_rental, Colors.purple),
                                _buildStatCard('For Sale', _stats!.carsForSale.toString(), Icons.sell, Colors.amber),
                              ],
                            ),
                            
                            // Booking stats
                            _buildStatSection(
                              'Bookings',
                              [
                                _buildStatCard('Total Bookings', _stats!.totalBookings.toString(), Icons.book_online, Colors.blue),
                                _buildStatCard('Successful', _stats!.successfulBookings.toString(), Icons.check_circle, Colors.green),
                                _buildStatCard('Pending', _stats!.pendingBookings.toString(), Icons.pending, Colors.orange),
                                _buildStatCard('Rejected', _stats!.rejectedBookings.toString(), Icons.cancel, Colors.red),
                                _buildStatCard('Canceled', _stats!.canceledBookings.toString(), Icons.block, Colors.grey),
                              ],
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Pie charts
                            const Text(
                              'Booking Status Distribution',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 250,
                              child: _buildBookingStatusPieChart(),
                            ),
                            _buildPieChartLegend([
                              LegendItem(
                                color: Colors.green,
                                label: 'Successful',
                                value: _stats!.successfulBookings,
                                total: _stats!.totalBookings,
                              ),
                              LegendItem(
                                color: Colors.orange,
                                label: 'Pending',
                                value: _stats!.pendingBookings,
                                total: _stats!.totalBookings,
                              ),
                              LegendItem(
                                color: Colors.red,
                                label: 'Rejected',
                                value: _stats!.rejectedBookings,
                                total: _stats!.totalBookings,
                              ),
                              LegendItem(
                                color: Colors.grey,
                                label: 'Canceled',
                                value: _stats!.canceledBookings,
                                total: _stats!.totalBookings,
                              ),
                            ]),
                            
                            const SizedBox(height: 32),
                            
                            const Text(
                              'Car Status Distribution',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 250,
                              child: _buildCarStatusPieChart(),
                            ),
                            _buildPieChartLegend([
                              LegendItem(
                                color: Colors.green,
                                label: 'Available',
                                value: _stats!.availableCars,
                                total: _stats!.totalCars,
                              ),
                              LegendItem(
                                color: Colors.red,
                                label: 'Unavailable',
                                value: _stats!.unavailableCars,
                                total: _stats!.totalCars,
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildStatSection(String title, List<Widget> statCards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: statCards,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingStatusPieChart() {
    // Check if all values are zero
    final bool allZero = _stats!.successfulBookings == 0 && 
                         _stats!.pendingBookings == 0 && 
                         _stats!.rejectedBookings == 0 && 
                         _stats!.canceledBookings == 0;
    
    if (allZero) {
      return const Center(child: Text('No booking data available'));
    }
    
    final bookingData = [
      PieChartSectionData(
        value: _stats!.successfulBookings.toDouble(),
        title: _stats!.successfulBookings > 0 ? 'Successful' : '',
        color: Colors.green,
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: _stats!.pendingBookings.toDouble(),
        title: _stats!.pendingBookings > 0 ? 'Pending' : '',
        color: Colors.orange,
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: _stats!.rejectedBookings.toDouble(),
        title: _stats!.rejectedBookings > 0 ? 'Rejected' : '',
        color: Colors.red,
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: _stats!.canceledBookings.toDouble(),
        title: _stats!.canceledBookings > 0 ? 'Canceled' : '',
        color: Colors.grey,
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];

    return PieChart(
      PieChartData(
        sections: bookingData,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildCarStatusPieChart() {
    // Check if all values are zero
    final bool allZero = _stats!.availableCars == 0 && _stats!.unavailableCars == 0;
    
    if (allZero) {
      return const Center(child: Text('No car status data available'));
    }
    
    final carData = [
      PieChartSectionData(
        value: _stats!.availableCars.toDouble(),
        title: _stats!.availableCars > 0 ? 'Available' : '',
        color: Colors.green,
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: _stats!.unavailableCars.toDouble(),
        title: _stats!.unavailableCars > 0 ? 'Unavailable' : '',
        color: Colors.red,
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];

    return PieChart(
      PieChartData(
        sections: carData,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildPieChartLegend(List<LegendItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: items.map((item) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${item.label}: ${item.value} (${item.percentage.toStringAsFixed(1)}%)',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

