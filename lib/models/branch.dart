class Branch {
  final String nameEn;
  final String nameAr;
  final double latitude;
  final double longitude;

  Branch({
    required this.nameEn,
    required this.nameAr,
    required this.latitude,
    required this.longitude,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      nameEn: json['nameEn'] ?? '',
      nameAr: json['nameAr'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }
} 