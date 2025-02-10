# Nayifat App Notification System Documentation

## System Overview
The notification system uses a two-table approach:
1. `notification_templates` - Stores the notification content and targeting criteria
2. `user_notifications` - Stores user-specific notification references in JSON format
3. `audit_log` - Tracks all notification operations for auditing purposes

## Audit Events
The system logs the following events:
1. **notification_sent**:
   - When a notification template is created
   - When notifications are sent to users
   - Includes target criteria and recipient count

2. **notification_delivered**:
   - When a user fetches their notifications
   - Includes notification IDs and fetch timestamp

3. **notification_read**:
   - When notifications are marked as read
   - Includes notification IDs and read timestamp

4. **notification_expired**:
   - When notifications reach their expiry date
   - Includes notification IDs and expiry timestamp

Example Audit Log Entry:
```json
{
    "national_id": "1000000001",
    "action": "notification_sent",
    "details": {
        "template_id": 123,
        "recipient_count": 50,
        "target_criteria": {
            "loan_application_details.status": "declined"
        },
        "timestamp": "2024-03-20 15:30:00"
    }
}
```

## API Endpoints

### 1. Send Notification
- **URL**: `https://icreditdept.com/api/send_notification.php`
- **Method**: POST
- **Headers**:
  ```
  Content-Type: application/json
  api-key: 7ca7427b418bdbd0b3b23d7debf69bf7
  ```

### 2. Get Notifications
- **URL**: `https://icreditdept.com/api/get_notifications.php`
- **Method**: POST
- **Headers**:
  ```
  Content-Type: application/json
  api-key: 7ca7427b418bdbd0b3b23d7debf69bf7
  ```
- **Request Body**:
  ```json
  {
      "national_id": "string",     // Required: User's national ID
      "mark_as_read": boolean      // Optional: Whether to mark fetched notifications as read
  }
  ```

## Send Notification Request Structure
```json
{
    // Target Users (use ONE of these options)
    "national_id": "string",           // For single user
    "national_ids": ["string"],        // For multiple users
    "filters": {                       // For filtered users
        "table.column": {              // Use table prefix: Users, loan_application_details, card_application_details
            "operator": "string",      // =, !=, >, <, >=, <=, LIKE, IN, BETWEEN
            "value": "any"             // String, number, or array for IN/BETWEEN
        }
    },
    "filter_operation": "string",      // Optional: "AND" (default) or "OR" for multiple filters

    // Notification Content (multi-language recommended)
    "title_en": "string",             // English title
    "body_en": "string",              // English content
    "title_ar": "string",             // Arabic title
    "body_ar": "string",              // Arabic content

    // Optional Fields
    "route": "string",                // App route to navigate to
    "additionalData": {},             // Extra data
    "expiry_at": "datetime"           // When the notification expires (default: 30 days)
}
```

## Filter Examples

### 1. Simple Status Filter
```json
{
    "filters": {
        "loan_application_details.status": {
            "operator": "=",
            "value": "declined"
        }
    },
    "title_en": "Loan Update",
    "body_en": "Your loan application status has changed",
    "title_ar": "تحديث التمويل",
    "body_ar": "تم تغيير حالة طلب التمويل الخاص بك"
}
```

### 2. Multiple Conditions (AND)
```json
{
    "filters": {
        "loan_application_details.status": {
            "operator": "=",
            "value": "declined"
        },
        "Users.salary": {
            "operator": "BETWEEN",
            "value": [5000, 15000]
        }
    },
    "title_en": "New Offer",
    "body_en": "Special financing options available",
    "title_ar": "عرض جديد",
    "body_ar": "خيارات تمويل خاصة متاحة"
}
```

### 3. Multiple Conditions (OR)
```json
{
    "filter_operation": "OR",
    "filters": {
        "loan_application_details.status": {
            "operator": "=",
            "value": "declined"
        },
        "card_application_details.status": {
            "operator": "=",
            "value": "declined"
        }
    },
    "title_en": "Application Update",
    "body_en": "Important update about your application",
    "title_ar": "تحديث الطلب",
    "body_ar": "تحديث مهم بخصوص طلبك"
}
```

### 4. Complex Search
```json
{
    "filters": {
        "Users.name": {
            "operator": "LIKE",
            "value": "%ahmed%"
        },
        "Users.salary": {
            "operator": ">=",
            "value": 10000
        },
        "loan_application_details.amount": {
            "operator": "BETWEEN",
            "value": [50000, 100000]
        }
    },
    "title_en": "Special Offer",
    "body_en": "Exclusive financing options for you",
    "title_ar": "عرض خاص",
    "body_ar": "خيارات تمويل حصرية لك"
}
```

## Get Notifications Response
```json
{
    "status": "success",
    "notifications": [
        {
            "id": 123,
            "title_en": "Loan Update",
            "body_en": "Your application status has changed",
            "title_ar": "تحديث التمويل",
            "body_ar": "تم تغيير حالة طلبك",
            "route": "/applications",
            "additional_data": {
                "application_id": "ABC123",
                "status": "declined"
            },
            "created_at": "2024-03-20 15:30:00",
            "expires_at": "2024-04-19 15:30:00",
            "status": "unread"
        }
    ]
}
```

## Notes
1. **Storage Efficiency**:
   - Templates are stored once in `notification_templates`
   - User notifications store only references in JSON format
   - Maximum 50 notifications per user

2. **Expiration**:
   - Default expiry is 30 days from creation
   - Custom expiry can be set using `expiry_at`
   - Expired notifications are not returned in get_notifications

3. **Multi-Language**:
   - Always use multi-language format (title_en, title_ar, etc.)
   - App automatically shows correct language based on user settings
   - Language selection happens on device

4. **Filters**:
   - Can combine multiple conditions
   - Supports complex queries across Users, loan_application_details, and card_application_details tables
   - Use table prefix for clarity (e.g., Users.name, loan_application_details.status)

5. **Performance**:
   - JSON storage optimizes database size
   - Automatic cleanup of old notifications (>50 per user)
   - Efficient querying with template references 