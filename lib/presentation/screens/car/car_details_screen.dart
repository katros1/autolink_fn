import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:intl/intl.dart';
import '../../models/car.dart';
import '../../models/rating.dart';
import '../../common/widgets/app_drawer.dart';
import '../../../services/user_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../utils/api_config.dart';

class CarDetailsScreen extends StatefulWidget {
  final String carId;

  const CarDetailsScreen({super.key, required this.carId});

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  Car? _car;
  List<Rating> _ratings = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isOwner = false;
  bool _isDeleting = false;
  
  // For image carousel
  int _currentImageIndex = 0;
  
  // For date selection
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  
  // For pricing calculation
  double _baseRate = 0;
  double _serviceFee = 0;
  double _securityDeposit = 0;
  double _total = 0;
  
  // Create a key for the scaffold to access the drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Add these variables to the _CarDetailsScreenState class
  final _ratingController = TextEditingController();
  int _selectedRating = 0;
  bool _isSubmittingRating = false;

  @override
  void initState() {
    super.initState();
    _fetchCarDetails();
  }

  Future<void> _fetchCarDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current user to check if they're the owner
      final user = await UserService.getUser();
      
      // For Android emulator, use 10.0.2.2 instead of localhost
      // For iOS simulator, use localhost
      final baseUrl = ApiConfig.baseUrl;
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/cars/${widget.carId}'),
        headers: {
          'Content-Type': 'application/json',
          if (user != null && user.token != null) 'Authorization': 'Bearer ${user.token}',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final carData = jsonData['data'];
        
        // Parse ratings
        final List<dynamic> ratingsData = carData['ratings'] ?? [];
        final List<Rating> ratings = ratingsData.map((ratingData) => Rating.fromJson(ratingData)).toList();
        
        // Check if current user is the owner
        final bool isOwner = user != null && user.userId == carData['ownerId'];
        print('User ID: ${user?.userId}, Car Owner ID: ${carData['ownerId']}, Is Owner: $isOwner');
        
        setState(() {
          _car = Car.fromJson(carData);
          _ratings = ratings;
          _isLoading = false;
          _isOwner = isOwner;
          
          // Set pricing details
          _baseRate = _car!.rentalPricePerDay;
          _serviceFee = _baseRate * 0.1; // 10% service fee
          _securityDeposit = _baseRate * 1.0; // 100% security deposit
          _updateTotal();
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load car details. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }
  
  void _updateTotal() {
    final days = _endDate.difference(_startDate).inDays;
    _total = (_baseRate * days) + _serviceFee + _securityDeposit;
  }
  
  void _nextImage() {
    if (_car != null && _car!.imageUrls.isNotEmpty) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % (_car!.imageUrls.length + 1);
      });
    }
  }
  
  void _previousImage() {
    if (_car != null && _car!.imageUrls.isNotEmpty) {
      setState(() {
        _currentImageIndex = (_currentImageIndex - 1 + _car!.imageUrls.length + 1) % (_car!.imageUrls.length + 1);
      });
    }
  }
  
  String _getCurrentImageUrl() {
    if (_car == null) return '';
    if (_currentImageIndex == 0) return _car!.coverImageUrl;
    return _car!.imageUrls[_currentImageIndex - 1];
  }
  
  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
        _updateTotal();
      });
    }
  }
  
  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate.add(const Duration(days: 1)),
      lastDate: _startDate.add(const Duration(days: 30)),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
        _updateTotal();
      });
    }
  }

  Future<void> _deleteCar() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Car'),
        content: const Text('Are you sure you want to delete this car? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() {
      _isDeleting = true;
    });
    
    try {
      final user = await UserService.getUser();
      if (user == null || user.token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to delete a car')),
        );
        setState(() {
          _isDeleting = false;
        });
        return;
      }
      
      final baseUrl = ApiConfig.baseUrl;
      
      final response = await http.delete(
        Uri.parse('$baseUrl/api/v1/cars/${widget.carId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
      );
      
      setState(() {
        _isDeleting = false;
      });
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Car deleted successfully')),
        );
        // Navigate back to owner cars screen with refresh flag
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete car. Please try again.')),
        );
      }
    } catch (e) {
      setState(() {
        _isDeleting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // Add this method to handle booking
  Future<void> _bookCar() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      final user = await UserService.getUser();
      if (user == null || user.token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to book a car')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      final baseUrl = ApiConfig.baseUrl;
      
      // Format dates for API
      final startDateFormatted = "${DateFormat('yyyy-MM-dd').format(_startDate)}T10:00:00";
      final endDateFormatted = "${DateFormat('yyyy-MM-dd').format(_endDate)}T18:00:00";
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/bookings/${_car!.id}/book'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
        body: jsonEncode({
          'startDate': startDateFormatted,
          'endDate': endDateFormatted,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Booking successful
        final responseData = jsonDecode(response.body);
        final bookingId = responseData['data']['id'];
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking successful!')),
        );
        
        // Navigate to booking details or confirmation screen
        // TODO: Add navigation to booking details screen
        // Navigator.pushNamed(context, '/booking_details', arguments: {'bookingId': bookingId});
      } else {
        // Booking failed
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to book car. Please try again.';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // Add this method to handle opening WhatsApp
  Future<void> _contactSellerViaWhatsApp() async {
    if (_car == null) return;
    
    // Get owner phone number from car data
    final phoneNumber = _car!.ownerPhoneNumber ?? '';
    
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seller phone number not available')),
      );
      return;
    }
    
    // Format phone number (remove any spaces or special characters)
    final formattedPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Create WhatsApp URL
    final whatsappUrl = 'https://wa.me/$formattedPhone?text=Hello, I am interested in your ${_car!.title} listed on AutoLink.';
    
    // Try to launch WhatsApp
    if (await canLaunch(whatsappUrl)) {
      await launch(whatsappUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp. Please make sure it is installed.')),
      );
    }
  }

  // Add this method to handle rating submission
  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() {
      _isSubmittingRating = true;
    });

    try {
      final user = await UserService.getUser();
      if (user == null || user.token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to rate a car')),
        );
        setState(() {
          _isSubmittingRating = false;
        });
        return;
      }
      
      final baseUrl = ApiConfig.baseUrl;
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/cars/${widget.carId}/rate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
        body: jsonEncode({
          'stars': _selectedRating,
          'comment': _ratingController.text.trim(),
        }),
      );
      
      setState(() {
        _isSubmittingRating = false;
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating submitted successfully')),
        );
        _ratingController.clear();
        _selectedRating = 0;
        _fetchCarDetails(); // Refresh to show the new rating
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to submit rating. Please try again.';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmittingRating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // Add this method to handle updating car availability
  Future<void> _updateCarAvailability(bool available) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await UserService.getUser();
      if (user == null || user.token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to update car availability')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      final baseUrl = ApiConfig.baseUrl;
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/v1/cars/${widget.carId}/availability?available=$available'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Car availability updated to ${available ? 'available' : 'unavailable'}')),
        );
        _fetchCarDetails(); // Refresh to show the updated availability
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update car availability. Please try again.')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _ratingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[100],
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _car == null
                  ? const Center(child: Text('Car not found'))
                  : Column(
                      children: [
                        // Custom green header (same as home screen)
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
                        // Back to Cars button below header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.black),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              const Text(
                                'Back to Cars',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Rest of the content
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Car title
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    _car!.title,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Car image carousel
                                Container(
                                  height: 250,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                  ),
                                  child: Stack(
                                    children: [
                                      // Main image
                                      Center(
                                        child: Image.network(
                                          _getCurrentImageUrl(),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Center(
                                              child: Icon(Icons.error, color: Colors.grey),
                                            );
                                          },
                                        ),
                                      ),
                                      // Left arrow
                                      Positioned(
                                        left: 8,
                                        top: 0,
                                        bottom: 0,
                                        child: Center(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.3),
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.chevron_left, color: Colors.white),
                                              onPressed: _previousImage,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Right arrow
                                      Positioned(
                                        right: 8,
                                        top: 0,
                                        bottom: 0,
                                        child: Center(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.3),
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.chevron_right, color: Colors.white),
                                              onPressed: _nextImage,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Thumbnail images
                                SizedBox(
                                  height: 80,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.all(8),
                                    itemCount: _car!.imageUrls.length + 1,
                                    itemBuilder: (context, index) {
                                      final imageUrl = index == 0 ? _car!.coverImageUrl : _car!.imageUrls[index - 1];
                                      final isSelected = _currentImageIndex == index;
                                      
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _currentImageIndex = index;
                                          });
                                        },
                                        child: Container(
                                          width: 60,
                                          margin: const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey[300],
                                                  child: const Center(
                                                    child: Icon(Icons.error, color: Colors.grey, size: 20),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                // About this vehicle
                                Card(
                                  margin: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'About this vehicle',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _car!.description,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Specifications
                                Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Specifications',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Icon(Icons.calendar_today, color: Colors.blue[700], size: 20),
                                                  const SizedBox(width: 8),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text(
                                                        'Year',
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      Text(
                                                        _car!.year.toString(),
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Icon(Icons.settings, color: Colors.blue[700], size: 20),
                                                  const SizedBox(width: 8),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text(
                                                        'Transmission',
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      Text(
                                                        _car!.transmission,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Icon(Icons.local_gas_station, color: Colors.blue[700], size: 20),
                                                  const SizedBox(width: 8),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text(
                                                        'Fuel Type',
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      Text(
                                                        _car!.fuelType,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Icon(Icons.airline_seat_recline_normal, color: Colors.blue[700], size: 20),
                                                  const SizedBox(width: 8),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text(
                                                        'Seats',
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      Text(
                                                        _car!.seatCount.toString(),
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Customer Reviews
                                Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Customer Reviews',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Row(
                                              children: List.generate(5, (index) {
                                                return Icon(
                                                  index < _car!.averageRating.round() ? Icons.star : Icons.star_border,
                                                  color: Colors.amber,
                                                  size: 20,
                                                );
                                              }),
                                            ),
                                            const SizedBox(width: 8),
                                            Text('(${_ratings.length} ratings)'),
                                            const SizedBox(width: 8),
                                            Text('0 completed trips'),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        _ratings.isEmpty
                                            ? const Center(child: Text('No reviews yet'))
                                            : ListView.builder(
                                                shrinkWrap: true,
                                                physics: const NeverScrollableScrollPhysics(),
                                                itemCount: _ratings.length,
                                                itemBuilder: (context, index) {
                                                  final rating = _ratings[index];
                                                  return Padding(
                                                    padding: const EdgeInsets.only(bottom: 16),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            const CircleAvatar(
                                                              backgroundColor: Colors.grey,
                                                              child: Icon(Icons.person, color: Colors.white),
                                                            ),
                                                            const SizedBox(width: 8),
                                                            Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                const Text(
                                                                  'Anonymous User',
                                                                  style: TextStyle(
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  DateFormat('MMM dd, yyyy').format(DateTime.parse(rating.ratedAt)),
                                                                  style: TextStyle(
                                                                    color: Colors.grey[600],
                                                                    fontSize: 12,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Row(
                                                          children: List.generate(5, (starIndex) {
                                                            return Icon(
                                                              starIndex < rating.stars ? Icons.star : Icons.star_border,
                                                              color: Colors.amber,
                                                              size: 16,
                                                            );
                                                          }),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(rating.comment),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (!_isOwner) ...[
                                  // Rate This Car section - only shown to non-owners
                                  Card(
                                    margin: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Rate This Car',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: List.generate(5, (index) {
                                              return IconButton(
                                                icon: Icon(
                                                  index < _selectedRating ? Icons.star : Icons.star_border,
                                                  color: Colors.amber,
                                                  size: 30,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _selectedRating = index + 1;
                                                  });
                                                },
                                              );
                                            }),
                                          ),
                                          const SizedBox(height: 16),
                                          TextField(
                                            controller: _ratingController,
                                            maxLines: 3,
                                            decoration: const InputDecoration(
                                              hintText: 'Write your review here...',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: _isSubmittingRating ? null : _submitRating,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                              child: _isSubmittingRating
                                                  ? const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : const Text('Submit Rating'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                // Price and booking or owner actions
                                Card(
                                  margin: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              _car!.forRent 
                                                  ? 'RWF ${_car!.rentalPricePerDay.toInt()}/day'
                                                  : 'RWF ${_car!.salePrice.toInt()}',
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (_car!.forRent)
                                              const Text(
                                                '/day',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            const SizedBox(width: 8),
                                            Row(
                                              children: List.generate(5, (index) {
                                                return Icon(
                                                  index < _car!.averageRating.round() ? Icons.star : Icons.star_border,
                                                  color: Colors.amber,
                                                  size: 16,
                                                );
                                              }),
                                            ),
                                            const SizedBox(width: 4),
                                            Text('(${_ratings.length})'),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                        
                                        // Show different UI based on whether user is owner or not
                                        if (_isOwner) ...[
                                          // Owner actions
                                          const Text(
                                            'Owner Actions',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          // Add availability toggle
                                          Card(
                                            margin: const EdgeInsets.symmetric(vertical: 8),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Car Availability',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          'Your car is currently ${_car!.available ? 'available' : 'unavailable'} for booking',
                                                          style: TextStyle(
                                                            color: _car!.available ? Colors.green : Colors.red,
                                                          ),
                                                        ),
                                                      ),
                                                      Switch(
                                                        value: _car!.available,
                                                        onChanged: (value) {
                                                          // Show confirmation dialog
                                                          showDialog(
                                                            context: context,
                                                            builder: (context) => AlertDialog(
                                                              title: Text('${value ? 'Enable' : 'Disable'} Availability'),
                                                              content: Text(
                                                                'Are you sure you want to make this car ${value ? 'available' : 'unavailable'} for booking?'
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () => Navigator.of(context).pop(),
                                                                  child: const Text('Cancel'),
                                                                ),
                                                                TextButton(
                                                                  onPressed: () {
                                                                    Navigator.of(context).pop();
                                                                    _updateCarAvailability(value);
                                                                  },
                                                                  child: const Text('Confirm'),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                        activeColor: Colors.green,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: () {
                                                    // Navigate to edit car screen
                                                    Navigator.pushNamed(
                                                      context,
                                                      '/edit_car',
                                                      arguments: {'carId': _car!.id},
                                                    ).then((result) {
                                                      if (result == true) {
                                                        _fetchCarDetails();
                                                      }
                                                    });
                                                  },
                                                  icon: const Icon(Icons.edit),
                                                  label: const Text('Update'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.blue,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: _isDeleting ? null : _deleteCar,
                                                  icon: _isDeleting 
                                                      ? const SizedBox(
                                                          width: 16,
                                                          height: 16,
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: Colors.white,
                                                          ),
                                                        )
                                                      : const Icon(Icons.delete),
                                                  label: Text(_isDeleting ? 'Deleting...' : 'Delete'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                                                                   
                                        ] else if (_car!.forRent) ...[
                                          // Rental booking UI for non-owners
                                          const Text(
                                            'Select Rental Period',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text('Start Date'),
                                                    const SizedBox(height: 4),
                                                    InkWell(
                                                      onTap: () => _selectStartDate(context),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                        decoration: BoxDecoration(
                                                          border: Border.all(color: Colors.grey),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Text(DateFormat('MM/dd/yyyy').format(_startDate)),
                                                            const Icon(Icons.calendar_today, size: 16),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text('End Date'),
                                                    const SizedBox(height: 4),
                                                    InkWell(
                                                      onTap: () => _selectEndDate(context),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                        decoration: BoxDecoration(
                                                          border: Border.all(color: Colors.grey),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Text(DateFormat('MM/dd/yyyy').format(_endDate)),
                                                            const Icon(Icons.calendar_today, size: 16),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 24),
                                          const Text(
                                            'Pricing Details',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Base Rate (${_endDate.difference(_startDate).inDays} days)'),
                                              Text('${(_baseRate * _endDate.difference(_startDate).inDays).toInt()} RWF'),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Service Fee'),
                                              Text('${_serviceFee.toInt()} RWF'),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Security Deposit'),
                                              Text('${_securityDeposit.toInt()} RWF'),
                                            ],
                                          ),
                                          const Divider(height: 24),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Total',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                '${_total.toInt()} RWF',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 24),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: _isLoading ? null : _bookCar,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF00A651),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: _isLoading
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : const Text(
                                                    'Book Now',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        ] else if (_car!.forSale) ...[
                                          // Sale contact UI for non-owners
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: _contactSellerViaWhatsApp,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF00A651),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text(
                                                'Contact Seller',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                // Add some bottom padding
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
      // Add a floating action button for chat
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     // TODO: Implement chat functionality
      //   },
      //   backgroundColor: Colors.white,
      //   child: const Icon(Icons.chat, color: Color(0xFF00A651)),
      // ),
    );
  }
}










