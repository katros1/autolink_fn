import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:intl/intl.dart';
import '../../../services/user_service.dart';
import '../../models/booking.dart';
import '../../../utils/api_config.dart';

class BookingDetailsScreen extends StatefulWidget {
  final Booking booking;

  const BookingDetailsScreen({super.key, required this.booking});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  bool _isLoading = false;

  Future<void> _approveBooking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await UserService.getUser();
      if (user == null || user.token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to approve bookings')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      final baseUrl = ApiConfig.baseUrl;
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/v1/bookings/${widget.booking.bookingId}/approve'),
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
          const SnackBar(content: Text('Booking approved successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate refresh needed
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to approve booking. Please try again.')),
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

  Future<void> _rejectBooking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await UserService.getUser();
      if (user == null || user.token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to reject bookings')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      final baseUrl = ApiConfig.baseUrl;
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/v1/bookings/${widget.booking.bookingId}/reject'),
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
          const SnackBar(content: Text('Booking rejected successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate refresh needed
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to reject booking. Please try again.')),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'PENDING':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Add this method to calculate total price
  double _calculateTotalPrice() {
    final days = widget.booking.endDate.difference(widget.booking.startDate).inDays;
    // If less than a day, charge for a full day
    return widget.booking.rentalPricePerDay * (days > 0 ? days : 1);
  }

  // Add this method to handle marking a car as returned
  Future<void> _markCarAsReturned() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await UserService.getUser();
      if (user == null || user.token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to mark a car as returned')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      final baseUrl = ApiConfig.baseUrl;
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/v1/bookings/${widget.booking.bookingId}/return'),
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
          const SnackBar(content: Text('Car marked as returned successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate refresh needed
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to mark car as returned. Please try again.')),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: _getStatusColor(widget.booking.bookingStatus),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Status: ${widget.booking.bookingStatus}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Car details section
            _buildSectionTitle('Car Details'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.booking.carPicUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: const Icon(Icons.car_rental, size: 40),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.booking.carName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Car ID: ${widget.booking.carId}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Renter details section
            _buildSectionTitle('Renter Details'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: widget.booking.renterPicUrl != null && widget.booking.renterPicUrl!.isNotEmpty
                          ? NetworkImage(widget.booking.renterPicUrl!)
                          : null,
                      onBackgroundImageError: (exception, stackTrace) {
                        // Handle error loading image
                      },
                      child: widget.booking.renterPicUrl?.isEmpty ?? true
                          ? const Icon(Icons.person, size: 30)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.booking.renterName ?? 'Unknown Renter',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.email, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(widget.booking.renterEmail ?? 'No email provided'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(widget.booking.renterPhone ?? 'No phone provided'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(widget.booking.renterAddress ?? 'No address provided'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Booking details section
            _buildSectionTitle('Booking Details'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow(
                      'Booking Date',
                      DateFormat('MMM dd, yyyy - HH:mm').format(widget.booking.bookingDate),
                      Icons.calendar_today,
                    ),
                    const Divider(),
                    _buildDetailRow(
                      'Start Date',
                      DateFormat('MMM dd, yyyy - HH:mm').format(widget.booking.startDate),
                      Icons.play_circle_outline,
                    ),
                    const Divider(),
                    _buildDetailRow(
                      'End Date',
                      DateFormat('MMM dd, yyyy - HH:mm').format(widget.booking.endDate),
                      Icons.stop_circle_outlined,
                    ),
                    const Divider(),
                    _buildDetailRow(
                      'Duration',
                      _calculateDuration(widget.booking.startDate, widget.booking.endDate),
                      Icons.timelapse,
                    ),
                    const Divider(),
                    _buildDetailRow(
                      'Price per Day',
                      'RWF ${widget.booking.rentalPricePerDay.toInt()}',
                      Icons.attach_money,
                    ),
                    const Divider(),
                    _buildDetailRow(
                      'Total Price',
                      'RWF ${_calculateTotalPrice().toInt()}',
                      Icons.monetization_on,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Action buttons for PENDING bookings
            if (widget.booking.bookingStatus == 'PENDING')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _rejectBooking,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.red,
                              ),
                            )
                          : const Text('REJECT'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _approveBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A651),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('APPROVE'),
                    ),
                  ),
                ],
              ),
            
            // Add "Mark as Returned" button for approved bookings
            if (widget.booking.bookingStatus == 'APPROVED')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _markCarAsReturned,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('MARK AS RETURNED'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF00A651),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _calculateDuration(DateTime start, DateTime end) {
    final difference = end.difference(start);
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    
    if (days > 0) {
      return '$days days${hours > 0 ? ', $hours hours' : ''}';
    } else {
      return '${difference.inHours} hours';
    }
  }
}
