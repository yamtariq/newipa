# Dark Mode Implementation Reference Guide

## Setup Code

```dart
// Import theme provider
import '../providers/theme_provider.dart';

// Get dark mode state in widget
final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
final themeColor = isDarkMode ? Colors.black : const Color(0xFF0077B6);
```

## UI Elements

### Headers & Titles
```dart
// Title text
Text(
  'Title',
  style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: themeColor,
  ),
)

// Section titles
Text(
  'Section Title',
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: isDarkMode ? Colors.black : const Color(0xFF0077B6),
  ),
)
```

### Logos & SVG Images
```dart
isDarkMode 
  ? ColorFiltered(
      colorFilter: const ColorFilter.mode(
        Colors.black,
        BlendMode.srcIn,
      ),
      child: Image.asset(
        'assets/images/logo.png',
        height: screenHeight * 0.06,
      ),
    )
  : Image.asset(
      'assets/images/logo.png',
      height: screenHeight * 0.06,
    )
```

### Containers & Cards
```dart
Container(
  decoration: BoxDecoration(
    color: isDarkMode ? Colors.grey[100] : Colors.white,
    borderRadius: BorderRadius.circular(12.0),
    border: Border.all(
      color: themeColor.withOpacity(0.2),
    ),
    boxShadow: [
      BoxShadow(
        color: isDarkMode ? Colors.grey[400]! : Colors.black.withOpacity(0.1),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
  ),
)
```

### Primary Buttons
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: isDarkMode ? Colors.black : const Color(0xFF0077B6),
    padding: const EdgeInsets.symmetric(vertical: 16.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
  ),
  child: Text(
    'Button Text',
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
)
```

### Secondary Buttons (Sign In)
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: isDarkMode ? Colors.black.withOpacity(0.1) : Colors.red[50],
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
    side: BorderSide(
      color: isDarkMode ? Colors.black : Colors.red,
    ),
  ),
  child: Text(
    'Sign In',
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: isDarkMode ? Colors.black : Colors.red,
    ),
  ),
)
```

### Navigation Bar
```dart
Container(
  decoration: BoxDecoration(
    color: isDarkMode ? Colors.grey[700] : const Color(0xFF0077B6),
    boxShadow: [
      BoxShadow(
        color: isDarkMode ? Colors.grey[900]! : const Color(0xFF0077B6),
        blurRadius: isDarkMode ? 10 : 8,
        offset: const Offset(0, -2),
      ),
    ],
  ),
  child: CircleNavBar(
    activeIcons: [
      Icon(Icons.icon, color: isDarkMode ? Colors.grey[400] : const Color(0xFF0077B6)),
    ],
    color: isDarkMode ? Colors.black : Colors.white,
  ),
)
```

### Status Containers
```dart
Container(
  decoration: BoxDecoration(
    color: isDarkMode ? Colors.grey[100] : Colors.grey[100],
    borderRadius: BorderRadius.circular(8.0),
    border: Border.all(
      color: themeColor.withOpacity(0.3),
    ),
  ),
  child: Text(
    'Status Text',
    style: TextStyle(
      color: isDarkMode ? Colors.black87 : Colors.black87,
    ),
  ),
)
```

### Empty State Messages
```dart
Text(
  'No items available',
  style: TextStyle(
    color: isDarkMode ? Colors.black54 : Colors.grey[600],
    fontSize: 16,
  ),
)
```

## Key Principles

1. **Color Usage**
   - Dark mode primary color: `Colors.black`
   - Light mode primary color: `const Color(0xFF0077B6)`
   - Use opacity for subtle variations
   - Maintain consistent color hierarchy

2. **Contrast & Readability**
   - Use `Colors.white` text on dark backgrounds
   - Use appropriate opacity levels for secondary text
   - Ensure sufficient contrast for all text elements

3. **Consistency**
   - Apply same styling patterns across similar components
   - Maintain consistent spacing and padding
   - Use same border radius values (8.0 or 12.0)

4. **RTL Support**
   - Wrap Scaffold with `Directionality` for Arabic pages
   - Use `textDirection: TextDirection.rtl` for Arabic text
   - Position elements correctly for both RTL and LTR

5. **Accessibility**
   - Maintain readable font sizes (14-20)
   - Use bold text for important elements
   - Ensure sufficient touch targets

## Common Color Values

```dart
// Primary Colors
final themeColor = isDarkMode ? Colors.black : const Color(0xFF0077B6);

// Background Colors
backgroundColor: isDarkMode ? Colors.grey[100] : Colors.white,

// Text Colors
color: isDarkMode ? Colors.black87 : Colors.black87,  // Primary text
color: isDarkMode ? Colors.black54 : Colors.grey[600],  // Secondary text

// Border Colors
color: themeColor.withOpacity(0.2),  // Subtle borders
color: themeColor.withOpacity(0.3),  // Medium emphasis borders

// Shadow Colors
color: isDarkMode ? Colors.grey[400]! : Colors.black.withOpacity(0.1),
``` 