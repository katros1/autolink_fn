class Car {
  final String id;
  final String ownerId;
  final String? ownerName;
  final String? ownerPhoneNumber;
  final String title;
  final String description;
  final String brand;
  final String model;
  final int year;
  final String color;
  final String transmission;
  final String fuelType;
  final int mileage;
  final int seatCount;
  final String bodyType;
  final String plateNumber;
  final bool forRent;
  final bool forSale;
  final double rentalPricePerDay;
  final double salePrice;
  final String city;
  final String state;
  final String country;
  final String address;
  final String coverImageUrl;
  final List<String> imageUrls;
  final String status;
  final double averageRating;
  final int totalRatings;
  final bool available;

  Car({
    required this.id,
    required this.ownerId,
    this.ownerName,
    this.ownerPhoneNumber,
    required this.title,
    required this.description,
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    required this.transmission,
    required this.fuelType,
    required this.mileage,
    required this.seatCount,
    required this.bodyType,
    required this.plateNumber,
    required this.forRent,
    required this.forSale,
    required this.rentalPricePerDay,
    required this.salePrice,
    required this.city,
    required this.state,
    required this.country,
    required this.address,
    required this.coverImageUrl,
    required this.imageUrls,
    required this.status,
    required this.averageRating,
    required this.totalRatings,
    required this.available,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    // Debug print to see what we're getting
    print('Parsing Car from JSON: ${json.keys}');
    
    return Car(
      id: json['id'] ?? '',
      ownerId: json['ownerId'] ?? '',
      ownerName: json['ownerName'],
      ownerPhoneNumber: json['ownerPhoneNumber'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      year: json['year'] ?? 0,
      color: json['color'] ?? '',
      transmission: json['transmission'] ?? '',
      fuelType: json['fuelType'] ?? '',
      mileage: json['mileage'] ?? 0,
      seatCount: json['seatCount'] ?? 0,
      bodyType: json['bodyType'] ?? '',
      plateNumber: json['plateNumber'] ?? '',
      forRent: json['forRent'] ?? false,
      forSale: json['forSale'] ?? false,
      rentalPricePerDay: (json['rentalPricePerDay'] ?? 0).toDouble(),
      salePrice: (json['salePrice'] ?? 0).toDouble(),
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      address: json['address'] ?? '',
      coverImageUrl: json['coverImageUrl'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      status: json['status'] ?? '',
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      available: json['available'] ?? false,
    );
  }
}


