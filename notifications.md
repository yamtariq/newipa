# Nayifat App Notification System

## System Overview

The notification system uses a two-table approach for efficient notification management:
- `notification_templates`: Stores the notification templates with targeting criteria
- `user_notifications`: Stores individual user notifications

## Features

- Multi-language support (Arabic/English)
- Expiration dates for notifications
- Background notification fetching
- Advanced filtering with AND/OR operations
- Automatic cleanup of expired notifications
- Efficient storage and delivery

## API Endpoints

### 1. Send Notification (`send_notification.php`)

Sends notifications to users based on specified criteria.

**Request Body:**
```json
{
  "title": "Notification Title",
  "body": "Notification Body",
  "title_en": "English Title",
  "body_en": "English Body",
  "title_ar": "العنوان بالعربي",
  "body_ar": "المحتوى بالعربي",
  "route": "/specific_screen",
  "additional_data": {
    "key": "value"
  },
  "filters": {
    "loan_application_status": "approved",
    "user_name": "John"
  },
  "filter_operation": "OR",
  "expiry_at": "2024-03-20 12:00:00"
}
```

**Notes:**
- `expiry_at` is optional (defaults to 30 days)
- `filter_operation` can be "AND" (default) or "OR"
- Filters are combined based on `filter_operation`

### 2. Get Notifications (`get_notifications.php`)

Retrieves notifications for the authenticated user.

**Request Body:**
```json
{
  "mark_as_read": true,
  "national_id": "1234567890"
}
```

**Response:**
```json
{
  "status": "success",
  "notifications": [
    {
      "id": 1,
      "title": "Notification Title",
      "body": "Notification Body",
      "route": "/specific_screen",
      "additional_data": {},
      "created_at": "2024-03-01 10:00:00",
      "expires_at": "2024-03-31 10:00:00",
      "status": "unread"
    }
  ]
}
```

## Background Processing

### Android
- Uses WorkManager for background processing
- Minimum interval: 15 minutes
- Persists across app restarts and device reboots
- Battery-efficient operation

### iOS
- Uses Background App Refresh
- Minimum interval: 15 minutes
- Respects system settings for background refresh
- Battery-efficient operation

## Testing

The notification system includes comprehensive tests:
- Background fetch functionality
- Localization testing
- Expiration handling
- Minimum interval compliance

Run tests using:
```bash
flutter test test/notification_test.dart
```

## Best Practices

1. **Storage Efficiency**
   - Templates stored once, referenced by many
   - Automatic cleanup of expired notifications

2. **Multi-language Support**
   - Store notifications in multiple languages
   - Deliver in user's preferred language

3. **Filtering**
   - Use targeted filters to reach specific users
   - Combine filters with AND/OR operations

4. **Performance**
   - Background fetch optimized for battery life
   - Efficient database queries
   - Automatic cleanup of old notifications 