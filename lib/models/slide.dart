class Slide {
  final int id;
  final String imageUrl;
  final String link;
  final String leftTitle;
  final String rightTitle;
  final List<int>? imageBytes;

  Slide({
    required this.id,
    required this.imageUrl,
    required this.link,
    required this.leftTitle,
    required this.rightTitle,
    this.imageBytes,
  });

  factory Slide.fromJson(Map<String, dynamic> json) {
    return Slide(
      id: json['slide_id'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      link: json['link'] ?? '',
      leftTitle: json['leftTitle'] ?? '',
      rightTitle: json['rightTitle'] ?? '',
      imageBytes: json['image_bytes'] as List<int>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slide_id': id,
      'image_url': imageUrl,
      'link': link,
      'leftTitle': leftTitle,
      'rightTitle': rightTitle,
      'image_bytes': imageBytes,
    };
  }

  Slide copyWith({
    int? id,
    String? imageUrl,
    String? link,
    String? leftTitle,
    String? rightTitle,
    List<int>? imageBytes,
  }) {
    return Slide(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      link: link ?? this.link,
      leftTitle: leftTitle ?? this.leftTitle,
      rightTitle: rightTitle ?? this.rightTitle,
      imageBytes: imageBytes ?? this.imageBytes,
    );
  }
} 