# Database Tables Documentation

This document provides a comprehensive overview of all database tables used in the Nayifat application.

## Authentication & Security Tables

### 1. auth_logs
Tracks all authentication attempts and security-related events.
- `log_id` - Unique identifier for the log entry
- `national_id` - National ID of the user attempting authentication
- `deviceId` - Device identifier if authentication is from a mobile device
- `auth_type` - Type of authentication (password, biometric, device_registration)
- `status` - Status of the authentication attempt (success, failed)
- `ip_address` - IP address of the request
- `user_agent` - Browser/device user agent
- `failure_reason` - Reason for failure if authentication failed
- `created_at` - Timestamp of the log entry

### 2. API_Keys
Manages API keys for secure access to endpoints.
- `key_id` - Unique identifier for the API key
- `api_key` - The actual API key
- `description` - Purpose or owner of the API key
- `expires_at` - Expiration date of the API key
- `created_at` - When the key was created
- `last_used_at` - Last time the key was used

### 3. user_tokens
Manages authentication tokens for user sessions.
- `token_id` - Unique identifier for the token
- `user_id` - User identifier
- `national_id` - National ID of the user
- `refresh_token` - Token used to refresh access tokens
- `refresh_expires_at` - When the refresh token expires
- `access_token` - Current access token
- `access_expires_at` - When the access token expires

## User Management Tables

### 4. Customers
Primary table storing customer information.
- `national_id` (Primary Key) - Unique national ID
- `first_name_en`, `second_name_en`, `third_name_en`, `family_name_en` - English name components
- `first_name_ar`, `second_name_ar`, `third_name_ar`, `family_name_ar` - Arabic name components
- `date_of_birth` - Customer's birth date
- `id_expiry_date` - National ID expiry date
- `email` - Email address
- `phone` - Phone number
- `building_no`, `street`, `district`, `city`, `zipcode`, `add_no` - Address components
- `iban` - Bank account number
- `dependents` - Number of dependents
- `salary_dakhli` - Salary from Dakhli
- `salary_customer` - Customer declared salary
- `los` - Length of service
- `sector` - Employment sector
- `employer` - Employer name
- `password` - Hashed password
- `registration_date` - When account was created
- `consent`, `consent_date` - Marketing consent status
- `nafath_status`, `nafath_timestamp` - Nafath verification details

### 5. customer_devices
Manages registered mobile devices for customers.
- `device_id` - Unique identifier for the device
- `national_id` - Customer's national ID
- `deviceId` - Unique device identifier
- `platform` - Operating system (iOS/Android)
- `model` - Device model
- `manufacturer` - Device manufacturer
- `biometric_enabled` - Whether biometric auth is enabled
- `status` - Device status (active/disabled)
- `created_at` - When device was registered
- `last_used_at` - Last authentication time

## Application Tables

### 6. loan_application_details
Tracks loan applications and their status.
- `loan_id` - Unique identifier for the loan application
- `application_no` - Application reference number
- `national_id` - Applicant's national ID
- `status` - Application status
- `status_date` - Last status update date
- `loan_amount` - Requested loan amount
- `tenure` - Loan duration in months
- `monthly_payment` - Calculated monthly payment
- `interest_rate` - Applied interest rate
- `created_at` - Application submission date
- `last_updated` - Last modification date

### 7. card_application_details
Tracks credit card applications and their status.
- `card_id` - Unique identifier for the card application
- `application_no` - Application reference number
- `national_id` - Applicant's national ID
- `card_type` - Type of card (GOLD/REWARD)
- `card_limit` - Approved credit limit
- `status` - Application status
- `status_date` - Last status update date
- `created_at` - Application submission date
- `last_updated` - Last modification date

## Security & Verification Tables

### 8. OTP_Codes
Manages one-time passwords for verification.
- `otp_id` - Unique identifier for the OTP
- `national_id` - Customer's national ID
- `otp_code` - Hashed OTP code
- `expires_at` - OTP expiration time
- `is_used` - Whether OTP has been used
- `created_at` - When OTP was generated

## Notification Tables

### 9. user_notifications
Stores notifications for users.
- `notification_id` - Unique identifier for the notification record
- `national_id` - Customer's national ID
- `notifications` - JSON array of notifications
- `created_at` - Record creation date
- `last_updated` - Last modification date

### 10. notification_templates
Stores notification templates for various scenarios.
- `id` - Unique identifier for the template
- `title`, `body` - Default template content
- `title_en`, `body_en` - English template content
- `title_ar`, `body_ar` - Arabic template content
- `route` - App route for notification action
- `additional_data` - JSON with additional template data
- `expiry_at` - Template expiration date
- `created_at` - Template creation date
- `last_updated` - Last modification date

## Content Management Tables

### 11. master_config
Manages application content and configurations.
- `config_id` - Unique identifier for the config
- `page` - Related page/section
- `key_name` - Configuration key
- `value` - JSON configuration value
- `last_updated` - Last modification date

## Table Relationships

1. All tables with `national_id` have a foreign key relationship to the `Customers` table
2. `customer_devices` links devices to customers for authentication
3. `user_tokens` manages active sessions for authenticated customers
4. `loan_application_details` and `card_application_details` track customer applications
5. `user_notifications` links notifications to customers
6. `OTP_Codes` provides verification codes for customer actions

## Indexing Strategy

The following indexes are maintained for performance:
- National ID indexes on all related tables
- Status indexes on application tables
- Device ID index on customer_devices
- Token indexes on user_tokens
- Expiry date index on notification_templates
- Page/key indexes on master_config

This indexing strategy ensures optimal performance for common queries while maintaining data integrity through proper constraints.