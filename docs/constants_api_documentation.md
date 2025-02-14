# Constants API Documentation

## Overview
The Constants API provides endpoints to manage application-wide constants with support for both English and Arabic values. This API allows you to store, retrieve, and update configuration values that need to be accessible across the application.

## Authentication
All endpoints require API key authentication using the `x-api-key` header.

```http
x-api-key: your_api_key_here
```

## Database Schema
The constants are stored in the `Constants` table with the following structure:

```sql
CREATE TABLE Constants (
    id INT PRIMARY KEY IDENTITY(1,1),
    ConstantName NVARCHAR(255) NOT NULL,  -- Supports Arabic
    ConstantValue NVARCHAR(255) NOT NULL,  -- Supports Arabic
    ConstantValue_ar NVARCHAR(255) NULL,  -- Arabic value
    Description NVARCHAR(255) NULL,  -- Optional description
    LastUpdated DATETIME DEFAULT GETDATE()
)
```

## API Endpoints

### 1. Get All Constants
Retrieves all constants from the database.

**Request:**
```http
GET /api/constants
```

**Response:**
```json
{
    "success": true,
    "data": [
        {
            "name": "MAX_LOAN_AMOUNT",
            "value": "500000",
            "valueAr": "٥٠٠٠٠٠",
            "description": "Maximum loan amount in SAR",
            "lastUpdated": "2024-03-20T10:00:00Z"
        },
        {
            "name": "MIN_LOAN_AMOUNT",
            "value": "5000",
            "valueAr": "٥٠٠٠",
            "description": "Minimum loan amount in SAR",
            "lastUpdated": "2024-03-20T10:00:00Z"
        }
    ]
}
```

### 2. Get Constant by Name
Retrieves a specific constant by its name.

**Request:**
```http
GET /api/constants/{name}
```

**Response:**
```json
{
    "success": true,
    "data": {
        "name": "MAX_LOAN_AMOUNT",
        "value": "500000",
        "valueAr": "٥٠٠٠٠٠",
        "description": "Maximum loan amount in SAR",
        "lastUpdated": "2024-03-20T10:00:00Z"
    }
}
```

### 3. Create New Constant
Creates a new constant in the database.

**Request:**
```http
POST /api/constants
Content-Type: application/json

{
    "name": "MAX_LOAN_AMOUNT",
    "value": "500000",
    "valueAr": "٥٠٠٠٠٠",
    "description": "Maximum loan amount in SAR"
}
```

**Response:**
```json
{
    "success": true,
    "data": {
        "name": "MAX_LOAN_AMOUNT",
        "value": "500000",
        "valueAr": "٥٠٠٠٠٠",
        "description": "Maximum loan amount in SAR",
        "lastUpdated": "2024-03-20T10:00:00Z"
    }
}
```

### 4. Update Constant
Updates an existing constant by its name.

**Request:**
```http
PUT /api/constants/{name}
Content-Type: application/json

{
    "value": "600000",
    "valueAr": "٦٠٠٠٠٠",
    "description": "Updated maximum loan amount in SAR"
}
```

**Response:**
```json
{
    "success": true,
    "data": {
        "name": "MAX_LOAN_AMOUNT",
        "value": "600000",
        "valueAr": "٦٠٠٠٠٠",
        "description": "Updated maximum loan amount in SAR",
        "lastUpdated": "2024-03-20T10:00:00Z"
    }
}
```

## Error Responses
All endpoints return standardized error responses:

```json
{
    "success": false,
    "error": "Error message here"
}
```

Common error status codes:
- `400` - Bad Request (e.g., invalid input, duplicate constant name)
- `401` - Unauthorized (invalid or missing API key)
- `404` - Not Found (constant doesn't exist)
- `500` - Internal Server Error

## Using in Flutter App

### Setup
1. Add the `constants_service.dart` file to your project
2. Ensure you have the `http` package in your `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.1.0
```

### Usage Examples

1. **Get All Constants:**
```dart
try {
  final constants = await ConstantsService.getAllConstants();
  
  // Access values
  final maxLoanAmount = constants['MAX_LOAN_AMOUNT']['value'];
  final maxLoanAmountAr = constants['MAX_LOAN_AMOUNT']['valueAr'];
  final description = constants['MAX_LOAN_AMOUNT']['description'];
  final lastUpdated = constants['MAX_LOAN_AMOUNT']['lastUpdated'];
  
  print('Max Loan Amount: $maxLoanAmount');
  print('Max Loan Amount (Arabic): $maxLoanAmountAr');
} catch (e) {
  print('Error loading constants: $e');
}
```

2. **Get Single Constant:**
```dart
try {
  final constant = await ConstantsService.getConstant('MAX_LOAN_AMOUNT');
  
  // Access values
  final value = constant['value'];
  final valueAr = constant['valueAr'];
  final description = constant['description'];
  final lastUpdated = constant['lastUpdated'];
  
  print('Value: $value');
  print('Arabic Value: $valueAr');
} catch (e) {
  print('Error loading constant: $e');
}
```

### Error Handling
The service methods throw exceptions with descriptive messages. Always wrap calls in try-catch blocks:

```dart
try {
  final constants = await ConstantsService.getAllConstants();
  // Use constants...
} catch (e) {
  // Handle error appropriately
  if (e.toString().contains('401')) {
    // Handle unauthorized
  } else if (e.toString().contains('404')) {
    // Handle not found
  } else {
    // Handle other errors
  }
}
```

## Best Practices

1. **Naming Constants:**
   - Use UPPER_SNAKE_CASE for constant names
   - Be descriptive and clear
   - Use prefixes to group related constants (e.g., `LOAN_`, `CARD_`)

2. **Values:**
   - Keep values in appropriate formats (numbers as strings if they need to be parsed)
   - Ensure Arabic values are properly formatted
   - Include units in descriptions when applicable

3. **Error Handling:**
   - Always implement proper error handling
   - Log errors appropriately
   - Show user-friendly error messages

4. **Caching:**
   - Consider implementing local caching for frequently used constants
   - Implement a refresh mechanism based on `lastUpdated` timestamp

5. **Security:**
   - Never expose the API key in client-side code
   - Use environment variables or secure storage for API keys
   - Validate input before sending to the API

## Example Constants

Here are some example constants you might want to store:

```json
[
    {
        "name": "MAX_LOAN_AMOUNT",
        "value": "500000",
        "valueAr": "٥٠٠٠٠٠",
        "description": "Maximum loan amount in SAR"
    },
    {
        "name": "MIN_LOAN_AMOUNT",
        "value": "5000",
        "valueAr": "٥٠٠٠",
        "description": "Minimum loan amount in SAR"
    },
    {
        "name": "LOAN_TENURE_MAX",
        "value": "60",
        "valueAr": "٦٠",
        "description": "Maximum loan tenure in months"
    },
    {
        "name": "CARD_LIMIT_MAX",
        "value": "100000",
        "valueAr": "١٠٠٠٠٠",
        "description": "Maximum card limit in SAR"
    }
]
``` 