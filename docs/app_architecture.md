# Nayifat App Architecture Documentation

## Core Features

### Global App States
- **Language Support (isArabic)**
  - Bilingual support (Arabic/English)
  - Affects all UI elements and content
  - Controlled through language toggle
  - Persisted across app sessions

- **Theme Management (isDarkMode)**
  - Light/Dark theme support
  - Affects all UI components
  - Controlled through theme toggle
  - Theme colors defined in constants.dart
  - Persisted across app sessions

## Cross-Platform Compatibility
### Critical Requirement
- **Platform Parity**
  - All features MUST work identically on both Android and iOS
  - No platform-specific feature limitations
  - Consistent user experience across platforms

### Platform-Specific Considerations
- **Authentication**
  - Biometric authentication (TouchID/FaceID on iOS, Fingerprint/Face Unlock on Android)
  - Secure storage implementation
  - Device registration handling

- **UI/UX**
  - Native design patterns respect
  - Platform-specific gestures
  - Consistent theming across platforms
  - Proper keyboard handling

- **Security**
  - Platform-specific encryption
  - Secure storage mechanisms
  - Certificate handling
  - App signing requirements

- **Device Features**
  - Camera access
  - File system operations
  - Push notifications
  - Deep linking

- **Testing Requirements**
  - Must be tested on both platforms
  - Platform-specific edge cases
  - Different screen sizes and resolutions
  - OS version compatibility

## Page Structure

### 1. Splash Page
- Initial loading screen
- Handles:
  - App initialization
  - Content pre-loading
  - Cache initialization
  - Session status check
  - Dynamic content updates

### 2. Main Page
#### Components
- **Theme & Language Controls**
  - Dark mode toggle
  - Language switch (Arabic/English)

- **User Welcome Section**
  - Displays "Welcome" message
  - Shows user's first name when signed in
  - Localized based on current language

- **Authentication Controls**
  - Sign in button
  - Register button
  - Sign off button
  - Sign out button
  - Dynamic display based on auth status

- **Dynamic Content**
  - Slideshow (cached from update contents API)
  - Product application buttons
    - Cards application
    - Loans application
  - Loan calculator widget with navigation
  - Contact information section (cached from update contents API)

### 3. Account Page
#### Settings & Controls
- **Theme Control**
  - Dark mode toggle
  - Custom popup window
  - No API dependency

- **Security Settings**
  - Biometric enable/disable toggle
  - MPIN change functionality
  - Password change (API dependent)
    - Current password verification
    - New password validation
    - Server-side update
    - follow the registration process after password setup

- **Language Settings**
  - Language toggle
  - Custom popup window
  - No API dependency

- **Session Management**
  - Sign off functionality
  - sign out functionality
  - quick sign in (biometrics/MPIN) functionality
  - full sign in (password) functionality
  - Session cleanup
  - Cache management

### 4. Customer Services Page
#### Components
- **Contact Information**
  - Dynamically loaded from cache
  - Updated through content update API
  - Displays:
    - Phone numbers
    - Email addresses
    - Social media links

- **Support Form** 
  - Form design 
  - (Phase 2)
    - Form submission functionality
    - API integration pending
    - Future implementation planned

### 5. Cards Page
#### Components
- **Advertisement Banner**
  - Dynamically loaded from cache
  - Updated through content update API

- **Card Management**
  - Session-dependent display
  - Non-authenticated state:
    - Sign-in prompt
    - Sign-in button
  - Authenticated state:
    - Application status display
    - New card application button
    - Existing cards information

#### Card Actions
- Transaction history view
- Statement download
- Dispute application
- Clearance letter request
- Card status management:
  - Lock/Unlock
  - Block with reason
  - PIN change
  - Card cancellation

### 6. Loans Page
#### Components
- **Advertisement Banner**
  - Dynamically loaded from cache
  - Updated through content update API

- **Loan Management**
  - Session-dependent display
  - Non-authenticated state:
    - Sign-in prompt
    - Sign-in button
  - Authenticated state:
    - Application status display
    - New loan application button
    - Existing loans information

#### Loan Actions
- Similar to card actions
- Specific to loan products
- Status tracking
- Document management

## Navigation
### Bottom Navigation Bar
- Present across all main pages
- Consistent styling
- Theme-aware design
- Language-aware layout
- Smooth navigation handling

## Technical Implementation

### API Integration
- Centralized API configuration in constants.dart
- Endpoint definitions
- Header management
- Authentication handling
- Error management

### State Management
- Session state tracking
- Authentication state
- Theme state
- Language state
- Cache state

### Cache Management
- Dynamic content caching
  - Slideshow data
  - Contact information
  - Advertisement content
- Cache invalidation
- Update mechanisms

### Theme Implementation
- Color definitions in constants.dart
- Dark/Light variants
- Dynamic switching
- Component-specific theming
- Consistent application

### Localization
- Dual language support
- RTL/LTR handling
- Dynamic content loading
- Format adaptations

### Security
- Biometric authentication
- MPIN management
- Password security
- Session management
- Secure storage

## Data Flow

### Content Update Process
1. App initialization
2. API content fetch
3. Cache update
4. UI refresh
5. Regular update checks

### Authentication Flow
1. User authentication
2. Session establishment
3. Secure storage
4. State management
5. UI updates

### Cache Management Flow
1. Initial load
2. Regular updates
3. Content validation
4. Storage optimization
5. Cleanup procedures

## Future Enhancements (Phase 2)
- Customer service form implementation
- Enhanced security features
- Additional payment options (samsung pay, apple pay, google pay, etc.)
- Extended product features
- Advanced user preferences

## Dependencies
- API services
- Secure storage
- State management
- UI components
- Network handling
- Cache management
- Biometric services
- Navigation services 