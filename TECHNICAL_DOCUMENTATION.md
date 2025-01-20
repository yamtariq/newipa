# Nayifat Mobile Application - Technical Documentation
Version: 1.0.1 | Last Updated: 2024-03-XX

## Version History
| Version | Date | Description | Author |
|---------|------|-------------|---------|
| 1.0.0 | 2024-03-XX | Initial documentation | Development Team |


## System Architecture

### 1. Application Layer Structure
```
nayifat_app_2025_new/
├── lib/
│   ├── main.dart           # Application entry point, theme configuration
│   ├── models/
│   │   ├── slide.dart      # Carousel slide model
│   │   └── contact_details.dart  # Contact information model
│   ├── screens/
│   │   ├── main_page.dart        # Main application screen
│   │   ├── main_page_ar.dart     # Arabic version of main page
│   │   ├── loan_calculator_page.dart
│   │   ├── branch_locator_page.dart
│   │   ├── support_page.dart
│   │   ├── cards_page.dart
│   │   └── registration_page.dart
│   ├── services/
│   │   └── api_service.dart      # API communication handling
│   └── widgets/
│       └── slide_media.dart      # Media display widget
├── assets/
│   ├── images/
│   │   ├── slide1.jpg
│   │   ├── slide2.jpg
│   │   ├── slide3.jpg
│   │   └── nayifat-logo.svg
│   └── fonts/
│       └── Roboto/
```

### 2. Current State Management
- Local state management using Flutter's `setState`
- Persistent storage using `shared_preferences` for:
  - Language preferences
  - Cached data
  - User settings

### 3. Network Layer Implementation
```dart
class ApiService {
  static const String baseUrl = 'https://icreditdept.com/api/master_fetch.php';
  static const String registrationBaseUrl = 'https://icreditdept.com/api/auth';
  final bool useMockData = false;

  // API Endpoints
  static const String validateIdentityEndpoint = '$registrationBaseUrl/validate-identity';
  static const String verifyOtpEndpoint = '$registrationBaseUrl/verify-otp';
  static const String setPasswordEndpoint = '$registrationBaseUrl/set-password';
  static const String setQuickAccessPinEndpoint = '$registrationBaseUrl/set-quick-access-pin';
  static const String resendOtpEndpoint = '$registrationBaseUrl/resend-otp';
}
```

## Core Functionality Implementation

### 1. Authentication System

#### Registration Flow
```dart
// Step 1: Identity Validation
Future<Map<String, dynamic>> validateUserIdentity(String id, String phone) async {
  try {
    final response = await http.post(
      Uri.parse(validateIdentityEndpoint),
      body: json.encode({
        'id': id,
        'phone': phone,
      }),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Flutter/1.0',
      },
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw ApiException('Failed', statusCode: response.statusCode);
  } catch (e) {
    throw ApiException('Network error: $e');
  }
}

// Step 2: OTP Verification
Future<bool> verifyOtp(String id, String otp) async {
  // Implementation as shown in api_service.dart
}

// Step 3: Password Setup
Future<Map<String, dynamic>> setPassword(String id, String password) async {
  // Implementation as shown in api_service.dart
}

// Step 4: Quick Access PIN Setup
Future<Map<String, dynamic>> setQuickAccessPin(String id, String pin) async {
  // Implementation as shown in api_service.dart
}
```

### 2. Loan Calculator Implementation
```dart
class _LoanCalculatorPageState extends State<LoanCalculatorPage> {
  double _loanAmount = 0;
  double _interestRate = 0;
  int _tenureInMonths = 0;
  double _emi = 0;
  double _totalPayment = 0;
  double _totalInterest = 0;

  void _calculateLoan() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _loanAmount = double.parse(_amountController.text);
        _interestRate = double.parse(_interestController.text);
        _tenureInMonths = int.parse(_tenureController.text);

        // Monthly interest rate
        double monthlyRate = (_interestRate / 12) / 100;

        // EMI calculation using formula: P * r * (1 + r)^n / ((1 + r)^n - 1)
        _emi = (_loanAmount * monthlyRate * pow(1 + monthlyRate, _tenureInMonths)) /
            (pow(1 + monthlyRate, _tenureInMonths) - 1);

        _totalPayment = _emi * _tenureInMonths;
        _totalInterest = _totalPayment - _loanAmount;
      });
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      symbol: 'SAR ',
      decimalDigits: 2,
    ).format(amount);
  }
}
```

### 3. Offline Support Implementation

#### Data Caching System
```dart
class CacheManager {
  static const String SLIDES_CACHE_KEY = 'slides_cache';
  static const String CONTACT_CACHE_KEY = 'contact_cache';
  static const Duration CACHE_DURATION = Duration(hours: 24);

  Future<void> cacheData(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheItem = {
      'data': json.encode(data),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await prefs.setString(key, json.encode(cacheItem));
  }

  Future<dynamic> getCachedData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedString = prefs.getString(key);
    if (cachedString == null) return null;

    final cacheItem = json.decode(cachedString);
    final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheItem['timestamp']);
    if (DateTime.now().difference(timestamp) > CACHE_DURATION) {
      await prefs.remove(key);
      return null;
    }
    return json.decode(cacheItem['data']);
  }
}
```

### 4. Multilingual Support
- Complete Arabic/English language support
- RTL layout handling
- Language toggle with persistent storage
- Localized content for:
  - UI elements
  - Error messages
  - Carousel slides
  - Contact information

## API Documentation

### 1. Current Endpoints

#### Authentication
- `POST /auth/validate-identity`
  ```json
  Request:
  {
    "id": "string",
    "phone": "string"
  }
  Response:
  {
    "success": boolean,
    "message": "string",
    "data": {
      "isValid": boolean,
      "nextStep": "string"
    }
  }
  ```

- `POST /auth/verify-otp`
  ```json
  Request:
  {
    "id": "string",
    "otp": "string"
  }
  Response:
  {
    "success": boolean,
    "message": "string"
  }
  ```

- `POST /auth/set-password`
  ```json
  Request:
  {
    "id": "string",
    "password": "string"
  }
  ```

- `POST /auth/set-quick-access-pin`
  ```json
  Request:
  {
    "id": "string",
    "pin": "string"
  }
  ```

#### Content
- `GET /master_fetch.php`
  ```json
  Parameters:
  {
    "page": "home",
    "key_name": "slideshow_content" or "slideshow_content_ar"
  }
  Response:
  {
    "success": boolean,
    "data": [
      {
        "id": number,
        "imageUrl": "string",
        "link": "string",
        "leftTitle": "string",
        "rightTitle": "string"
      }
    ]
  }
  ```

### 2. Error Handling
```dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? endpoint;

  ApiException(this.message, {this.statusCode, this.endpoint});

  @override
  String toString() => 
    'ApiException: $message ${statusCode != null ? '(Status: $statusCode)' : ''} ${endpoint != null ? 'at $endpoint' : ''}';
}
```

## Current Features

### 1. Home Screen
- Bilingual interface (Arabic/English)
- Interactive carousel slider
- Quick access navigation
- Service categories
- Account overview
- Latest offers and promotions

### 2. Loan Calculator
- Principal amount input (SAR)
- Interest rate calculation
- Loan tenure in months
- EMI calculation
- Total payment breakdown
- Interest calculation

### 3. Contact & Support
- Customer care email: CustomerCare@nayifat.com
- Toll-free number: 8001000088
- Social media integration:
  - LinkedIn: https://www.linkedin.com/company/nayifat-instalment-company
  - Instagram: https://www.instagram.com/nayifatcompany
  - Twitter: https://twitter.com/nayifatco
  - Facebook: https://www.facebook.com/nayifatcompany

## Testing

### Current Test Coverage
```dart
void main() {
  group('LoanCalculator Tests', () {
    final calculator = LoanCalculator();
    
    test('Monthly Payment Calculation', () {
      final result = calculator.calculateMonthlyPayment(
        principal: 10000,
        annualInterestRate: 5,
        termInMonths: 12,
      );
      expect(result, closeTo(856.07, 0.01));
    });
  });
}
```

## Current Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  carousel_slider: ^5.0.0
  circle_nav_bar: ^2.1.1
  flutter_svg: ^2.0.10
  font_awesome_flutter: ^10.6.0
  http: ^1.1.0
  url_launcher: ^6.2.5
  video_player: ^2.8.2
  shared_preferences: ^2.2.2
  intl: ^0.18.1
```

## Known Issues and Limitations
1. Offline mode limited to cached data only
2. Branch locator functionality in development
3. Limited test coverage

---

*Note: This documentation reflects the current implementation as of March 2024. For any technical issues or questions, please contact the development team.* 