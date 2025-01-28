class FinnoneCustomerResponse {
  final bool success;
  final String message;
  final String? finnoneReference;
  final String? status;
  final DateTime? processedAt;
  final Map<String, String>? additionalData;

  FinnoneCustomerResponse({
    required this.success,
    required this.message,
    this.finnoneReference,
    this.status,
    this.processedAt,
    this.additionalData,
  });

  factory FinnoneCustomerResponse.fromJson(Map<String, dynamic> json) {
    return FinnoneCustomerResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      finnoneReference: json['finnoneReference'],
      status: json['status'],
      processedAt: json['processedAt'] != null 
          ? DateTime.parse(json['processedAt']) 
          : null,
      additionalData: json['additionalData'] != null 
          ? Map<String, String>.from(json['additionalData'])
          : null,
    );
  }
}

class FinnoneStatusResponse {
  final String applicationNo;
  final String? finnoneReference;
  final String status;
  final String statusDescription;
  final DateTime lastUpdated;
  final Map<String, String>? statusDetails;

  FinnoneStatusResponse({
    required this.applicationNo,
    this.finnoneReference,
    required this.status,
    required this.statusDescription,
    required this.lastUpdated,
    this.statusDetails,
  });

  factory FinnoneStatusResponse.fromJson(Map<String, dynamic> json) {
    return FinnoneStatusResponse(
      applicationNo: json['applicationNo'] ?? '',
      finnoneReference: json['finnoneReference'],
      status: json['status'] ?? '',
      statusDescription: json['statusDescription'] ?? '',
      lastUpdated: DateTime.parse(json['lastUpdated']),
      statusDetails: json['statusDetails'] != null 
          ? Map<String, String>.from(json['statusDetails'])
          : null,
    );
  }
} 