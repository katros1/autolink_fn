import 'package:flutter/material.dart';
import '../../models/car.dart';
// import '../../screens/car/car_details_screen.dart';
// import '../../screens/owner/owner_cars_screen.dart';

class CarCard extends StatelessWidget {
  final Car car;

  const CarCard({
    Key? key,
    required this.car,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          // Navigate to car details and wait for result
          final result = await Navigator.pushNamed(
            context,
            '/car_details',
            arguments: car.id,
          );
          
          // If returned with refresh flag, refresh the owner cars list
          if (result == true) {
            // Find the nearest OwnerCarsScreen and refresh it
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed('/owner_cars');
            }
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car image with carousel
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  Image.network(
                    car.coverImageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.error, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                  // Label for rent/sale
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A651),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        car.forRent && car.forSale 
                            ? 'Rent/Buy' 
                            : car.forRent 
                                ? 'For Rent' 
                                : 'For Sale',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Car details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    car.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    car.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${car.forRent ? "RWF ${car.rentalPricePerDay.toInt()}/day" : "RWF ${car.salePrice.toInt()}"}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to car details screen when the button is pressed
                          Navigator.pushNamed(
                            context,
                            '/car_details',
                            arguments: {'carId': car.id},
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A651), // Green color
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('View Details'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}







