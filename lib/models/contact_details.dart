class ContactDetails {
  final String email;
  final String phone;
  final String workHours;
  final Map<String, String> socialLinks;

  ContactDetails({
    required this.email,
    required this.phone,
    required this.workHours,
    required this.socialLinks,
  });

  factory ContactDetails.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> socialData = json['social_links'] ?? {};
    return ContactDetails(
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      workHours: json['work_hours'] ?? '',
      socialLinks: Map<String, String>.from(socialData),
    );
  }

  // Mock data
  factory ContactDetails.mock() {
    return ContactDetails(
      email: 'CustomerCare@nayifat.com',
      phone: '8001000088',
      workHours: 'Sun-Thu: 8.00-17.00',
      socialLinks: {
        'linkedin': 'https://www.linkedin.com/company/nayifat-instalment-company',
        'instagram': 'https://www.instagram.com/nayifatcompany',
        'twitter': 'https://twitter.com/nayifatco',
        'facebook': 'https://www.facebook.com/nayifatcompany',
      },
    );
  }
} 