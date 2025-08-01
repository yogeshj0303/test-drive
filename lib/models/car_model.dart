class Car {
  final int id;
  final String name;
  final String modelNumber;
  final String? description;
  final String mainImage;
  final List<String> images;
  final ShowroomInfo showroom;
  final String price;
  final String? discountPrice;
  final String fuelType;
  final String transmission;
  final int yearOfManufacture;
  final String color;
  final String? drivetrain;
  final int seatingCapacity;
  final String? bodyType;
  final String? lastClosingKm;

  Car({
    required this.id,
    required this.name,
    required this.modelNumber,
    this.description,
    required this.mainImage,
    required this.images,
    required this.showroom,
    required this.price,
    this.discountPrice,
    required this.fuelType,
    required this.transmission,
    required this.yearOfManufacture,
    required this.color,
    this.drivetrain,
    required this.seatingCapacity,
    this.bodyType,
    this.lastClosingKm,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      modelNumber: json['model_number'] ?? '',
      description: json['description'],
      mainImage: json['main_image'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      showroom: ShowroomInfo.fromJson(json['showroom'] ?? {}),
      price: json['price'] ?? '0',
      discountPrice: json['discount_price'],
      fuelType: json['fuel_type'] ?? '',
      transmission: json['transmission'] ?? '',
      yearOfManufacture: json['year_of_manufacture'] ?? 0,
      color: json['color'] ?? '',
      drivetrain: json['drivetrain'],
      seatingCapacity: json['seating_capacity'] ?? 0,
      bodyType: json['body_type'],
      lastClosingKm: json['last_closing_km']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'model_number': modelNumber,
      'description': description,
      'main_image': mainImage,
      'images': images,
      'showroom': showroom.toJson(),
      'price': price,
      'discount_price': discountPrice,
      'fuel_type': fuelType,
      'transmission': transmission,
      'year_of_manufacture': yearOfManufacture,
      'color': color,
      'drivetrain': drivetrain,
      'seating_capacity': seatingCapacity,
      'body_type': bodyType,
      'last_closing_km': lastClosingKm,
    };
  }

  // Helper method to get formatted price
  String get formattedPrice {
    final priceValue = double.tryParse(price) ?? 0;
    return '₹${priceValue.toStringAsFixed(0)}';
  }

  // Helper method to get formatted discount price
  String? get formattedDiscountPrice {
    if (discountPrice == null) return null;
    final discountValue = double.tryParse(discountPrice!) ?? 0;
    return '₹${discountValue.toStringAsFixed(0)}';
  }

  // Helper method to check if car has discount
  bool get hasDiscount => discountPrice != null && discountPrice != price;

  // Helper method to get discount percentage
  double? get discountPercentage {
    if (!hasDiscount) return null;
    final originalPrice = double.tryParse(price) ?? 0;
    final discountValue = double.tryParse(discountPrice!) ?? 0;
    if (originalPrice == 0) return null;
    return ((originalPrice - discountValue) / originalPrice) * 100;
  }
}

class ShowroomInfo {
  final int id;
  final String name;
  final String pincode;

  ShowroomInfo({
    required this.id,
    required this.name,
    required this.pincode,
  });

  factory ShowroomInfo.fromJson(Map<String, dynamic> json) {
    return ShowroomInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      pincode: json['pincode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pincode': pincode,
    };
  }
}
