# Dark Mode Implementation Reference Guide

This document serves as a comprehensive reference for implementing dark mode across different UI elements in the Nayifat app.

## Setup
```dart
final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
final themeColor = isDarkMode ? Colors.black : const Color(0xFF0077B6);
```

## 1. Headers & Titles
```dart
Text(
  'Title',
  style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: themeColor,
  ),
)
```

## 2. Logos & SVG Images
```dart
isDarkMode 
  ? ColorFiltered(
      colorFilter: const ColorFilter.mode(
        Colors.black,
        BlendMode.srcIn,
      ),
      child: SvgPicture.asset(
        'assets/images/logo.svg',
        height: 40,
      ),
    )
  : SvgPicture.asset(
      'assets/images/logo.svg',
      height: 40,
    )
```

## 3. Containers & Cards
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
        color: isDarkMode ? Colors.grey[400]! : Colors.black.withOpacity(0.05),
        blurRadius: 5,
        offset: const Offset(0, 2),
      ),
    ],
  ),
)
```

## 4. Text Form Fields
```dart
TextFormField(
  decoration: InputDecoration(
    labelText: 'Label',
    border: InputBorder.none,
    contentPadding: const EdgeInsets.all(12),
    prefixIcon: Icon(Icons.icon, color: themeColor),
    labelStyle: TextStyle(color: themeColor.withOpacity(0.7)),
  ),
  style: TextStyle(color: isDarkMode ? Colors.black87 : Colors.black87),
)
```

## 5. Buttons

### Primary Button
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: isDarkMode ? Colors.black.withOpacity(0.1) : const Color(0xFF0077B6),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(
        color: isDarkMode ? Colors.black : Colors.transparent,
      ),
    ),
  ),
  child: Text(
    'Button',
    style: TextStyle(
      color: isDarkMode ? Colors.black : Colors.white,
      fontWeight: FontWeight.bold,
    ),
  ),
)
```

### Secondary/Cancel Button
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: isDarkMode ? Colors.black.withOpacity(0.1) : Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(
        color: themeColor.withOpacity(0.5),
      ),
    ),
  ),
  child: Text(
    'Cancel',
    style: TextStyle(
      color: themeColor,
      fontWeight: FontWeight.bold,
    ),
  ),
)
```

## 6. Navigation Bar
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
)
```

## 7. Icons
```dart
Icon(
  Icons.icon_name,
  color: isDarkMode ? Colors.grey[400] : const Color(0xFF0077B6),
)
```

## 8. Dividers
```dart
Divider(
  color: themeColor.withOpacity(0.2),
)
```

## 9. Scaffold Background
```dart
Scaffold(
  backgroundColor: isDarkMode ? Colors.grey[100] : Colors.white,
)
```

## 10. Status Indicators/Tags
```dart
Container(
  decoration: BoxDecoration(
    color: isDarkMode ? Colors.black.withOpacity(0.1) : Colors.grey[100],
    borderRadius: BorderRadius.circular(8.0),
    border: Border.all(
      color: themeColor.withOpacity(0.3),
    ),
  ),
)
```

## 11. Result/Info Tiles
```dart
Text(
  'Label',
  style: const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  ),
),
Text(
  'Value',
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: themeColor,
  ),
)
```

## 12. Error Messages
```dart
Text(
  'Error message',
  style: TextStyle(
    color: isDarkMode ? Colors.red[300] : Colors.red,
    fontSize: 12,
  ),
)
```

## 13. Form Container Borders
```dart
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: themeColor.withOpacity(0.2),
    ),
  ),
)
```

## Key Principles

1. **Color Usage**
   - Use `themeColor` (black in dark mode, primary color in light mode)
   - Apply opacity for subtle variations
   - Use grey shades for backgrounds and shadows

2. **Contrast & Readability**
   - Maintain proper contrast in both modes
   - Ensure text remains readable
   - Use appropriate opacity levels for different elements

3. **Consistency**
   - Keep styling consistent across similar elements
   - Use the same color patterns throughout the app
   - Maintain consistent spacing and sizing

4. **RTL Support**
   - Consider text alignment for Arabic version
   - Adjust icon and content positioning for RTL
   - Maintain proper padding and margins

5. **Accessibility**
   - Ensure sufficient color contrast
   - Maintain proper text sizing
   - Keep interactive elements easily identifiable

## Common Color Values

- Primary Color (Light Mode): `const Color(0xFF0077B6)`
- Dark Mode Base Color: `Colors.black`
- Background (Dark): `Colors.grey[100]`
- Background (Light): `Colors.white`
- Shadow (Dark): `Colors.grey[400]`
- Shadow (Light): `Colors.black.withOpacity(0.05)`
- Navigation Bar (Dark): `Colors.grey[700]`
- Icon Color (Dark): `Colors.grey[400]`
