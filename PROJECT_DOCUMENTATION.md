# Nayifat Mobile Application 2025 - Project Documentation

## Version History
| Version | Date | Description | Author |
|---------|------|-------------|---------|
| 1.0.0 | 2024-03-XX | Initial documentation | Development Team |

## Project Overview
The Nayifat Mobile Application is a modern, bilingual (Arabic/English) financial services application developed using Flutter framework. It serves as a digital platform for Nayifat Finance Company, providing various financial services and products to customers.

## Technical Specifications

### Development Framework & Environment
- **Framework**: Flutter
- **SDK Version**: ^3.6.0
- **Platform Support**: iOS and Android
- **Architecture**: Material Design

### Key Dependencies
- **UI Components**: 
  - `carousel_slider`: ^5.0.0
  - `circle_nav_bar`: ^2.1.1
  - `flutter_svg`: ^2.1.1
  - `font_awesome_flutter`: ^10.6.0
- **Networking**: 
  - `http`: ^1.1.0
  - `url_launcher`: ^6.2.5
- **Media**: 
  - `video_player`: ^2.8.2
- **Data Management**:
  - `shared_preferences`: ^2.2.2
- **Localization**:
  - `intl`: ^0.18.1

## Core Features

### 1. Multilingual Support
- Complete bilingual support (Arabic/English)
- RTL/LTR layout handling
- Language toggle functionality
- Localized content and UI elements

### 2. Authentication System
- User registration process
- Identity validation
- Phone number verification
- Secure login system
- Guest mode access

### 3. Main Features
- **Personal Loans**
  - Loan application process
  - Loan calculator
  - Various loan types
  - Application status tracking

- **Credit Cards**
  - Card application
  - Card management
  - Card benefits and features
  - Digital card services

- **Branch Services**
  - Branch locator
  - Branch information
  - Working hours
  - Contact details

- **Support Services**
  - Customer support access
  - Help center
  - FAQ section
  - Direct contact options

### 4. Home Screen Features
- Interactive carousel slider with promotional content
- Quick access navigation menu
- Service categories
- Account overview
- Latest offers and promotions

### 5. Contact & Support
- Customer care email: CustomerCare@nayifat.com
- Toll-free number: 8001000088
- Social media integration:
  - LinkedIn: https://www.linkedin.com/company/nayifat-instalment-company
  - Instagram: https://www.instagram.com/nayifatcompany
  - Twitter: https://twitter.com/nayifatco
  - Facebook: https://www.facebook.com/nayifatcompany

## Technical Architecture

### 1. API Integration
- Base URL: https://icreditdept.com/api
- RESTful API architecture
- JSON data format
- Secure authentication endpoints
- Offline mode support with fallback data

### 2. Navigation Structure
- Bottom navigation with 5 main sections:
  1. Support
  2. Cards
  3. Home
  4. Loans
  5. Account

### 3. Security Features
- Secure API communication
- Data encryption
- Session management
- Secure storage of user preferences

### 4. User Interface
- Modern and clean design
- Responsive layouts
- Custom fonts (Roboto)
- Material Design components
- Interactive elements
- Loading states and error handling

## Future Enhancements (Planned)
1. Enhanced branch locator with map integration
2. Advanced loan calculator features
3. Real-time chat support
4. Push notification system
5. Digital document upload capability
6. Biometric authentication

## Technical Requirements
- Internet connectivity for main features
- Minimum OS versions (to be specified)
- Device permissions:
  - Internet access
  - Location services (for branch locator)
  - Storage access (for document handling)

## Data Management
- Local storage for user preferences
- Caching system for offline access
- Secure storage for sensitive information
- API response handling and error management

## Development Guidelines

### Code Structure
```
lib/
  ├── main.dart
  ├── models/
  │   ├── slide.dart
  │   └── contact_details.dart
  ├── screens/
  │   ├── main_page.dart
  │   ├── main_page_ar.dart
  │   ├── loan_calculator_page.dart
  │   ├── branch_locator_page.dart
  │   ├── support_page.dart
  │   ├── cards_page.dart
  │   └── registration_page.dart
  ├── services/
  │   └── api_service.dart
  └── widgets/
      └── slide_media.dart
```

### Coding Standards
1. Follow Flutter's official style guide
2. Use meaningful variable and function names
3. Comment complex logic
4. Create reusable widgets
5. Implement proper error handling
6. Follow SOLID principles

### Testing Guidelines
- Unit tests for business logic
- Widget tests for UI components
- Integration tests for feature flows
- Performance testing benchmarks

## Deployment Process
1. Version control using Git
2. CI/CD pipeline setup (to be implemented)
3. Testing environments
4. Release management
5. App store submission guidelines

---

*Note: This documentation is a living document and will be updated as the project evolves. For any changes, please add a new entry in the Version History table at the top of this document.* 