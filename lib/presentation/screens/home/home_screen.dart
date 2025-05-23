import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import '../../common/widgets/car_card.dart';
import '../../common/widgets/app_drawer.dart';
import '../../models/car.dart';
import '../../../utils/api_config.dart';

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
  
  // Add these variables for search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Create a key for the scaffold to access the drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      final baseUrl = ApiConfig.baseUrl;
      
      String url = '$baseUrl/api/v1/cars/filtered';
      List<String> queryParams = [];
      
      if (_selectedFilter == 'Rent') {
        queryParams.add('forRent=true');
      } else if (_selectedFilter == 'Buy') {
        queryParams.add('forSale=true');
      }

      if (_searchQuery.isNotEmpty) {

        queryParams.add('title=${Uri.encodeComponent(_searchQuery)}');
      }

      if (queryParams.isNotEmpty) {
        url += '?' + queryParams.join('&');
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
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
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
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search cars...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Clear button
                              if (_searchController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                    _fetchCars(); // Refresh with empty search
                                  },
                                ),
                              // Search button with arrow icon
                              IconButton(
                                icon: const Icon(Icons.arrow_forward, color: Color(0xFF00A651)),
                                onPressed: () {
                                  // Perform search when icon is clicked
                                  final query = _searchController.text.trim();
                                  print('Searching for: "$query"'); // Debug log
                                  setState(() {
                                    _searchQuery = query;
                                  });
                                  _fetchCars(); // Call your existing fetch method with the search query
                                },
                              ),
                            ],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (value) {
                          // This still works if keyboard enter functions properly
                          setState(() {
                            _searchQuery = value.trim();
                          });
                          _fetchCars();
                        },
                        textInputAction: TextInputAction.search, // Set keyboard action to search
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
                    
                    if (_searchQuery.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            const Text('Search results for: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('"$_searchQuery"'),
                            const Spacer(),
                            TextButton.icon(
                              icon: const Icon(Icons.clear, size: 16),
                              label: const Text('Clear'),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                                _fetchCars();
                              },
                            ),
                          ],
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
    );
  }
}








