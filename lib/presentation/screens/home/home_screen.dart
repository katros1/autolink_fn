import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import '../../common/widgets/car_card.dart';
import '../../common/widgets/app_drawer.dart';
import '../../models/car.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'ALL';
  final List<String> _filters = ['ALL', 'Rent', 'Buy'];
  
  List<Car> _cars = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Create a key for the scaffold to access the drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _fetchCars();
  }

  Future<void> _fetchCars() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // For Android emulator, use 10.0.2.2 instead of localhost
      // For iOS simulator, use localhost
      final baseUrl = Platform.isAndroid ? 'http://10.0.2.2:8070' : 'http://localhost:8070';
      
      // Build URL based on selected filter
      String url = '$baseUrl/api/v1/cars/filtered';
      if (_selectedFilter == 'Rent') {
        url += '?forRent=true';
      } else if (_selectedFilter == 'Buy') {
        url += '?forSale=true';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
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
      backgroundColor: Colors.grey[100],
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Custom green header
          Container(
            color: const Color(0xFF00A651), // Green color
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Hamburger menu icon (white)
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
                      // Open the drawer
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
                  // AutoLink logo/text
                  const Text(
                    'AutoLink',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Empty SizedBox to balance the layout
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
          // Rest of the content
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search cars...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Filter chips
                    SizedBox(
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
                                  _fetchCars(); // Fetch cars when filter changes
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
                                      onRefresh: _fetchCars,
                                      child: ListView.builder(
                                        itemCount: _cars.length,
                                        itemBuilder: (context, index) {
                                          final car = _cars[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 16),
                                            child: CarCard(car: car),
                                          );
                                        },
                                      ),
                                    ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open chat
        },
        backgroundColor: const Color(0xFF0A2647),
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }
}





