# Users Table Documentation

## Table Structure
The `Users` table stores essential user information and financial details.

## Columns

| Column Name     | Data Type      | Nullable | Key | Default | Extra          | Description |
|----------------|----------------|----------|-----|---------|----------------|-------------|
| user_id        | int(11)        | NO       | PRI | NULL    | auto_increment | Unique identifier for each user |
| national_id    | varchar(50)    | NO       |     | NULL    |                | User's national identification number |
| name           | varchar(100)   | NO       |     | NULL    |                | User's full name in English |
| arabic_name    | varchar(255)   | NO       |     | NULL    |                | User's full name in Arabic |
| email          | varchar(100)   | NO       |     | NULL    |                | User's email address |
| password       | varchar(255)   | NO       |     | NULL    |                | Hashed password |
| phone          | varchar(15)    | NO       |     | NULL    |                | User's phone number |
| created_at     | datetime       | YES      |     | NULL    |                | Timestamp of account creation |
| dob            | date           | NO       |     | NULL    |                | Date of Birth |
| doe            | date           | NO       |     | NULL    |                | Date of Expiry (possibly for ID/documents) |

### Financial Information
| Column Name     | Data Type      | Nullable | Key | Default | Extra | Description |
|----------------|----------------|----------|-----|---------|-------|-------------|
| finPurpose     | varchar(10)    | NO       |     | NULL    |       | Purpose of financing |
| finAmount      | int(11)        | NO       |     | NULL    |       | Amount of financing requested |
| effRate        | decimal(5,2)   | NO       |     | NULL    |       | Effective interest rate |
| ibanNo         | varchar(24)    | YES      |     | NULL    |       | International Bank Account Number |
| income         | int(11)        | NO       |     | NULL    |       | User's income |

### Preferences and Settings
| Column Name     | Data Type      | Nullable | Key | Default | Extra | Description |
|----------------|----------------|----------|-----|---------|-------|-------------|
| language       | int(11)        | NO       |     | NULL    |       | User's preferred language |
| productType    | int(11)        | NO       |     | NULL    |       | Type of financial product |
| tenure         | int(11)        | NO       |     | NULL    |       | Duration/tenure of financial product |
| propertyStatus | char(1)        | NO       |     | NULL    |       | Status of property (if applicable) |

## Key Information
- Primary Key: `user_id` (auto-incrementing)
- The `national_id` field should be unique although not marked as a unique key in this schema
- Password field stores hashed values, not plain text
- All date/time fields use MySQL's native date/time formats

## Important Notes
1. Most fields are required (NOT NULL), except:
   - created_at
   - ibanNo

2. Field Constraints:
   - phone: Limited to 15 characters (international format)
   - email: Standard email format, 100 characters max
   - national_id: 50 characters max
   - ibanNo: Follows IBAN format (24 characters)
   - effRate: Allows for 2 decimal places
   - propertyStatus: Single character status code

3. Financial Information:
   - finAmount and income are stored as integers
   - effRate allows for decimal values up to 5 digits with 2 decimal places
   - finPurpose is limited to 10 characters

4. Naming Conventions:
   - Mixed camelCase naming used for some columns
   - Some abbreviations used (fin = financial, eff = effective, doe = date of expiry)

## Related Tables
This table is referenced in:
- user_devices
- user_sessions
- auth_logs

## Usage Context
This table is central to the authentication system and is queried during:
- Sign-in process
- User profile management
- Financial operations
- Device registration 