import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import '../../../services/user_service.dart';
import '../../common/widgets/app_drawer.dart';
import '../../common/widgets/car_card.dart';
import '../../models/car.dart';
import '../../../utils/api_config.dart';

class OwnerCarsScreen extends StatefulWidget {
  const OwnerCarsScreen({super.key});

  @override
  State<OwnerCarsScreen> createState() => _OwnerCarsScreenState();
}

class _OwnerCarsScreenState extends State<OwnerCarsScreen> {
  String _selectedFilter = 'ALL';
  final List<String> _filters = ['ALL', 'Rent', 'Buy'];
  String _searchQuery = '';
  
  List<Car> _cars = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _fetchOwnerCars();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOwnerCars() async {
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
          _errorMessage = 'You must be logged in as an owner to view your cars';
        });
        return;
      }

      // For Android emulator, use 10.0.2.2 instead of localhost
      // For iOS simulator, use localhost
      final baseUrl = ApiConfig.baseUrl;
      
      // Build URL based on selected filter and search query
      String url = '$baseUrl/api/v1/cars/owner/filtered';
      List<String> queryParams = [];
      
      if (_selectedFilter == 'Rent') {
        queryParams.add('forRent=true');
      } else if (_selectedFilter == 'Buy') {
        queryParams.add('forSale=true');
      }
      
      if (_searchQuery.isNotEmpty) {
        queryParams.add('title=$_searchQuery');
      }
      
      queryParams.add('page=0');
      queryParams.add('size=20');
      
      if (queryParams.isNotEmpty) {
        url += '?' + queryParams.join('&');
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> carsData = jsonData['data']['content'];
        
        setState(() {
          _cars = carsData.map((carData) => Car.fromJson(carData)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load cars. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('My Cars'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              // Navigate to add new car screen and wait for result
              final result = await Navigator.pushNamed(context, '/add_car');
              // If returned with refresh flag, refetch cars
              if (result == true) {
                _fetchOwnerCars();
              }
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search cars...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                    _fetchOwnerCars();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onSubmitted: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _fetchOwnerCars();
              },
            ),
          ),
          
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                          _fetchOwnerCars(); // Fetch cars when filter changes
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFF00A651), // Green color for selected filter
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Car list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _cars.isEmpty
                        ? const Center(child: Text('No cars available'))
                        : RefreshIndicator(
                            onRefresh: _fetchOwnerCars,
                            child: ListView.builder(
                              itemCount: _cars.length,
                              itemBuilder: (context, index) {
                                final car = _cars[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: CarCard(car: car),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to add new car screen and wait for result
          final result = await Navigator.pushNamed(context, '/add_car');
          // If returned with refresh flag, refetch cars
          if (result == true) {
            _fetchOwnerCars();
          }
        },
        backgroundColor: const Color(0xFF00A651),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}


