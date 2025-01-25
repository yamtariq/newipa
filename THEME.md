# Nayifat App Theme System Documentation

## Overview
The Nayifat App implements a dynamic theming system that supports both light and dark modes. The system is built with centralized color management, persistent theme preferences, and seamless mode switching.

## Color System

### Theme Colors
Located in `lib/utils/constants.dart`, we define six main colors:

#### Light Theme
- `lightPrimaryColor (0xFF0077B6)`: Primary brand color
- `lightBackgroundColor (0xFFFFFFFF)`: Main background
- `lightSurfaceColor (0xFFF5F5F5)`: Surface elements like cards

#### Dark Theme
- `darkPrimaryColor (0xFF0099E6)`: Primary brand color for dark mode
- `darkBackgroundColor (0xFF121212)`: Dark background
- `darkSurfaceColor (0xFF242424)`: Surface elements in dark mode

## Implementation

### 1. Theme Provider (`lib/providers/theme_provider.dart`)
- Manages theme state using `ChangeNotifier`
- Handles theme persistence using `SharedPreferences`
- Provides theme-related getters:
  ```dart
  Color get primaryColor
  Color get backgroundColor
  Color get surfaceColor
  ```
- Offers theme control methods:
  ```dart
  Future<void> toggleTheme()
  Future<void> setDarkMode(bool value)
  ```

### 2. Theme Data Configuration
The provider configures complete `ThemeData` including:
- Material 3 support
- Font family (Roboto)
- Color scheme
- AppBar theme
- Light/Dark mode specific configurations

### 3. Usage in Screens
To use the theme colors in any screen:
```dart
final themeProvider = Provider.of<ThemeProvider>(context);
final primaryColor = themeProvider.primaryColor;
final backgroundColor = themeProvider.backgroundColor;
final surfaceColor = themeProvider.surfaceColor;
```

### 4. Theme Persistence
- Theme preference is saved automatically when changed
- Loads last used theme on app startup
- Storage key: `is_dark_mode`

## How to Use

### 1. Accessing Theme Provider
```dart
// Get theme provider
final themeProvider = Provider.of<ThemeProvider>(context);

// Check current theme mode
bool isDarkMode = themeProvider.isDarkMode;

// Get theme colors
Color primary = themeProvider.primaryColor;
Color background = themeProvider.backgroundColor;
Color surface = themeProvider.surfaceColor;
```

### 2. Switching Themes
```dart
// Toggle theme
await themeProvider.toggleTheme();

// Set specific theme
await themeProvider.setDarkMode(true); // For dark mode
await themeProvider.setDarkMode(false); // For light mode
```

### 3. Using in Widgets
```dart
Container(
  color: themeProvider.backgroundColor,
  child: Text(
    'Sample Text',
    style: TextStyle(
      color: themeProvider.primaryColor,
    ),
  ),
)
```

## Best Practices

1. **Color References**
   - Always use theme provider colors instead of hardcoded values
   - Reference colors through the provider for consistency

2. **Theme Switching**
   - Use the provider's methods for theme changes
   - Allow changes to propagate through the widget tree

3. **Responsive Theming**
   - Listen to theme changes using `Consumer` or `Provider.of`
   - Update UI elements when theme changes

## Migration Guide

To migrate existing hardcoded colors to the theme system:

1. Replace hardcoded colors with theme provider references:
   ```dart
   // Before
   color: const Color(0xFF0077B6)
   
   // After
   color: themeProvider.primaryColor
   ```

2. Update background colors:
   ```dart
   // Before
   backgroundColor: const Color(0xFF121212)
   
   // After
   backgroundColor: themeProvider.backgroundColor
   ```

3. Update surface colors:
   ```dart
   // Before
   color: const Color(0xFF242424)
   
   // After
   color: themeProvider.surfaceColor
   ```

## Future Improvements

1. Add support for custom theme colors
2. Implement theme presets
3. Add animation during theme switching
4. Create color palette generator
5. Add support for additional theme attributes (radius, spacing, etc.)

## Component Theming

### Navigation Bar
The app uses a custom-themed `CircleNavBar` with dynamic colors and 3D effects:

#### 1. Navbar Colors
Located in `lib/utils/constants.dart`:

##### Light Theme Navbar
```dart
static const int lightNavbarBackground = 0xFFFFFFFF;     // White background
static const int lightNavbarPageBackground = 0xFFFFFFFF;  // White page background
static const int lightNavbarGradientStart = 0x1A0077B6;  // Primary blue with 10% opacity
static const int lightNavbarGradientEnd = 0x0D0077B6;    // Primary blue with 5% opacity
static const int lightNavbarShadowPrimary = 0x330077B6;  // Primary blue with 20% opacity
static const int lightNavbarShadowSecondary = 0x1A0077B6;// Primary blue with 10% opacity
static const int lightNavbarActiveIcon = 0xFF0077B6;     // Primary blue (full opacity)
static const int lightNavbarInactiveIcon = 0xFF0077B6;   // Primary blue with 50% opacity
static const int lightNavbarActiveText = 0xFF0077B6;     // Primary blue (full opacity)
static const int lightNavbarInactiveText = 0xFF0077B6;   // Primary blue with 50% opacity
```

##### Dark Theme Navbar
```dart
static const int darkNavbarBackground = 0xFF242424;      // Dark surface color
static const int darkNavbarGradientStart = 0x1A0099E6;   // Dark blue with 10% opacity
static const int darkNavbarGradientEnd = 0x0D0099E6;     // Dark blue with 5% opacity
static const int darkNavbarShadowPrimary = 0x330099E6;   // Dark blue with 20% opacity
static const int darkNavbarShadowSecondary = 0x1A0099E6; // Dark blue with 10% opacity
static const int darkNavbarActiveIcon = 0xFF0099E6;      // Dark blue (full opacity)
static const int darkNavbarInactiveIcon = 0x800099E6;    // Dark blue with 50% opacity
static const int darkNavbarActiveText = 0xFF0099E6;      // Dark blue (full opacity)
static const int darkNavbarInactiveText = 0x800099E6;    // Dark blue with 50% opacity
```

#### 2. Container Styling
```dart
Container(
  decoration: BoxDecoration(
    color: Color(themeProvider.isDarkMode 
        ? Constants.darkNavbarBackground 
        : Constants.lightNavbarBackground),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(themeProvider.isDarkMode 
            ? Constants.darkNavbarGradientStart
            : Constants.lightNavbarGradientStart),
        Color(themeProvider.isDarkMode 
            ? Constants.darkNavbarGradientEnd
            : Constants.lightNavbarGradientEnd),
      ],
    ),
    boxShadow: [
      BoxShadow(
        color: Color(themeProvider.isDarkMode 
            ? Constants.darkNavbarShadowPrimary
            : Constants.lightNavbarShadowPrimary),
        offset: const Offset(0, -2),
        blurRadius: 6,
        spreadRadius: 2,
      ),
      BoxShadow(
        color: Color(themeProvider.isDarkMode 
            ? Constants.darkNavbarShadowSecondary
            : Constants.lightNavbarShadowSecondary),
        offset: const Offset(0, -1),
        blurRadius: 4,
        spreadRadius: 0,
      ),
    ],
  ),
)
```

#### 3. CircleNavBar Configuration
```dart
CircleNavBar(
  // Icons
  activeIcons: [
    Icon(Icons.settings, 
        color: Color(themeProvider.isDarkMode 
            ? Constants.darkNavbarActiveIcon
            : Constants.lightNavbarActiveIcon)),
    // ... other icons
  ],
  inactiveIcons: [
    Icon(Icons.settings, 
        color: Color(themeProvider.isDarkMode 
            ? Constants.darkNavbarInactiveIcon
            : Constants.lightNavbarInactiveIcon)),
    // ... other icons
  ],
  
  // Text Styling
  activeLevelsStyle: TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Color(themeProvider.isDarkMode 
        ? Constants.darkNavbarActiveText
        : Constants.lightNavbarActiveText),
  ),
  inactiveLevelsStyle: TextStyle(
    fontSize: 14,
    color: Color(themeProvider.isDarkMode 
        ? Constants.darkNavbarInactiveText
        : Constants.lightNavbarInactiveText),
  ),
  
  // Base Properties
  color: Color(themeProvider.isDarkMode 
      ? Constants.darkNavbarBackground 
      : Constants.lightNavbarBackground),
  height: 70,
  circleWidth: 60,
  elevation: 8,
)
```

#### 4. Design Elements
- **White Background**: Clean, modern look in light mode
- **Dark Surface Background**: Consistent with dark theme
- **Gradient Background**: Creates depth using primary color with different opacities
- **Dual Shadows**: Layered shadows for 3D effect using primary color
- **Active/Inactive States**: Different opacities for better state indication
- **3D Effect Components**:
  - Top shadow: 20% opacity, larger spread
  - Bottom shadow: 10% opacity, subtle spread
  - Gradient: 10% to 5% opacity transition
  - Base elevation: 8dp

#### 5. Usage Guidelines
- Always use `Constants` color values instead of hardcoded values
- Maintain consistent opacity levels:
  - Primary shadows: 0.2 (20%)
  - Secondary shadows: 0.1 (10%)
  - Gradient top: 0.1 (10%)
  - Gradient bottom: 0.05 (5%)
- Active icons/text: Full opacity for emphasis
- Inactive icons/text: 50% opacity for subtle indication
- Keep navbar background white in light mode for clean look
- Use dark surface color in dark mode for consistency

### Form Styling
The app uses consistent form styling across all screens:

#### 1. Text Field Styling
```dart
TextFormField(
  decoration: InputDecoration(
    labelText: 'Field Label',
    alignLabelWithHint: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: themeProvider.primaryColor.withOpacity(0.2),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: themeProvider.primaryColor.withOpacity(0.2),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: themeProvider.primaryColor,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: Colors.red.withOpacity(0.5),
      ),
    ),
    filled: true,
    fillColor: themeProvider.isDarkMode
        ? themeProvider.primaryColor.withOpacity(0.05)  // Dark mode: subtle primary color
        : Color.lerp(Colors.white, themeProvider.primaryColor, 0.03)!,  // Light mode: very light primary tint
    labelStyle: TextStyle(
      color: themeProvider.primaryColor.withOpacity(0.8),
    ),
    hintStyle: TextStyle(
      color: themeProvider.primaryColor.withOpacity(0.5),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
  ),
  style: TextStyle(
    color: themeProvider.primaryColor,
    fontSize: 16,
  ),
  cursorColor: themeProvider.primaryColor,  // Cursor color matches theme
)
```

#### 2. Form Container Styling
```dart
Container(
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  decoration: BoxDecoration(
    color: themeProvider.isDarkMode
        ? themeProvider.primaryColor.withOpacity(0.08)  // Dark mode: stronger primary color
        : Color.lerp(Colors.white, themeProvider.primaryColor, 0.05)!,  // Light mode: lighter primary tint
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: themeProvider.primaryColor.withOpacity(0.1),
    ),
    boxShadow: [
      BoxShadow(
        color: themeProvider.primaryColor.withOpacity(0.05),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  padding: const EdgeInsets.all(16),
)
```

#### 3. Design Elements
- **Text Fields**:
  - Outlined border style
  - 8px border radius
  - Primary color for borders and labels
  - Surface color for background
  - Consistent padding and spacing

- **Form Containers**:
  - 12px border radius
  - Subtle border with primary color
  - Light shadow for depth
  - Surface color background
  - Consistent margin and padding

#### 4. Color Opacity Guidelines
- **Dark Mode**:
  - Cell Background: Primary color at 5% opacity
  - Container Background: Primary color at 8% opacity
  - Label Text: Primary color at 80% opacity
  - Hint Text: Primary color at 50% opacity
  - Borders: Primary color at 20% opacity
  - Focus Border: Primary color at 100% opacity

- **Light Mode**:
  - Cell Background: White with 3% primary color blend
  - Container Background: White with 5% primary color blend
  - Label Text: Primary color at 80% opacity
  - Hint Text: Primary color at 50% opacity
  - Borders: Primary color at 20% opacity
  - Focus Border: Primary color at 100% opacity

- **Usage Guidelines**:
  - Use `primaryColor` for interactive elements
  - Use `surfaceColor` for backgrounds
  - Use opacity for borders (20% for enabled, 100% for focused)
  - Use red with 50% opacity for errors

- **Spacing**:
  - 16px horizontal padding
  - 12px vertical padding for fields
  - 8px vertical margin between fields
  - 16px padding for form containers

- **Typography**:
  - 16px font size for input text
  - Use primary color for text
  - Bold labels for emphasis
  - Error text in red

- **Validation**:
  - Show red borders for errors
  - Use consistent error message styling
  - Maintain spacing with error text 

## Form Fields

### Container Styling
```dart
Container(
  margin: const EdgeInsets.symmetric(vertical: 8),
  decoration: BoxDecoration(
    color: themeProvider.isDarkMode
        ? themeProvider.primaryColor.withOpacity(0.08)
        : themeProvider.primaryColor.withOpacity(0.04),
    borderRadius: BorderRadius.circular(12),
  ),
  child: TextFormField(...),
)
```

### TextFormField Styling
```dart
TextFormField(
  decoration: InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: themeProvider.primaryColor.withOpacity(0.3),
        width: 1,
      ),
    ),
    labelStyle: TextStyle(color: themeProvider.primaryColor.withOpacity(0.8)),
    filled: true,
    fillColor: Colors.transparent,
  ),
  style: TextStyle(
    color: themeProvider.primaryColor,
    fontSize: 16,
  ),
)
```

## Toggle Switches

### Dark Mode Toggle
```dart
Switch.adaptive(
  value: isDarkMode,
  onChanged: onChanged,
  activeColor: themeProvider.primaryColor,
  activeTrackColor: themeProvider.primaryColor.withOpacity(0.3),
  inactiveThumbColor: themeProvider.primaryColor.withOpacity(0.7),
  inactiveTrackColor: themeProvider.primaryColor.withOpacity(0.1),
  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
)
```

### Opacity Guidelines

#### Form Fields
- **Container Background**
  - Dark mode: Primary color with 8% opacity
  - Light mode: Primary color with 4% opacity
- **Border**
  - Normal state: No border
  - Focused state: Primary color with 30% opacity, 1px width
- **Label Text**: Primary color with 80% opacity
- **Input Text**: Solid primary color

#### Toggle Switches
- **Active State**
  - Thumb: Solid primary color
  - Track: Primary color with 30% opacity
- **Inactive State**
  - Thumb: Primary color with 70% opacity
  - Track: Primary color with 10% opacity

### Usage Notes
1. Form fields use transparent backgrounds with a tinted container
2. Borders only appear on focus for better visual feedback
3. Toggle switches use adaptive styling for platform consistency
4. All colors are derived from the primary theme color
5. Opacity levels are carefully chosen for both dark and light modes 