class Booking {
  final String bookingId;
  final String carId;
  final String carName;
  final String carPicUrl;
  
  // Fields for owner view (when client makes booking)
  final String? renterId;
  final String? renterName;
  final String? renterPicUrl;
  final String? renterPhone;
  final String? renterEmail;
  final String? renterAddress;
  
  // Fields for client view (when viewing own bookings)
  final String? ownerId;
  final String? ownerName;
  final String? ownerPicUrl;
  final String? ownerPhone;
  final String? ownerEmail;
  final String? ownerAddress;
  
  final DateTime bookingDate;
  final String bookingStatus;
  final DateTime startDate;
  final DateTime endDate;
  final double rentalPricePerDay;

  Booking({
    required this.bookingId,
    required this.carId,
    required this.carName,
    required this.carPicUrl,
    this.renterId,
    this.renterName,
    this.renterPicUrl,
    this.renterPhone,
    this.renterEmail,
    this.renterAddress,
    this.ownerId,
    this.ownerName,
    this.ownerPicUrl,
    this.ownerPhone,
    this.ownerEmail,
    this.ownerAddress,
    required this.bookingDate,
    required this.bookingStatus,
    required this.startDate,
    required this.endDate,
    required this.rentalPricePerDay,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      bookingId: json['bookingId'] ?? json['id'] ?? '', // Try alternative field names and provide default
      carId: json['carId'] ?? '',
      carName: json['carName'] ?? '',
      carPicUrl: json['carPicUrl'] ?? '',
      renterId: json['renterId'],
      renterName: json['renterName'],
      renterPicUrl: json['renterPicUrl'],
      renterPhone: json['renterPhone'],
      renterEmail: json['renterEmail'],
      renterAddress: json['renterAddress'],
      ownerId: json['ownerId'],
      ownerName: json['ownerName'],
      ownerPicUrl: json['ownerPicUrl'],
      ownerPhone: json['ownerPhone'],
      ownerEmail: json['ownerEmail'],
      ownerAddress: json['ownerAddress'],
      bookingDate: DateTime.parse(json['bookingDate'] ?? DateTime.now().toIso8601String()),
      bookingStatus: json['bookingStatus'] ?? 'PENDING',
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate'] ?? DateTime.now().add(const Duration(days: 1)).toIso8601String()),
      rentalPricePerDay: (json['rentalPricePerDay'] ?? 0).toDouble(),
    );
  }
}




