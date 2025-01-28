class Branch {
  final String nameEn;
  final String nameAr;
  final double latitude;
  final double longitude;
  final String address;

  Branch({
    required this.nameEn,
    required this.nameAr,
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      nameEn: json['nameEn'] ?? '',
      nameAr: json['nameAr'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      address: json['address'] ?? '',
    );
  }
} 