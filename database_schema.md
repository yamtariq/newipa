# Nayifat App Database Schema (SQL Server)

## Core Tables

### Customers Table
```sql
CREATE TABLE Customers (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    NationalId NVARCHAR(10) UNIQUE NOT NULL,
    FullName NVARCHAR(100) NOT NULL,
    ArabicName NVARCHAR(100) NOT NULL,
    Phone NVARCHAR(15) NOT NULL,
    Email NVARCHAR(100),
    DateOfBirth DATE,
    IdExpiryDate DATE,
    EmployerName NVARCHAR(100),
    DakhliSalary BIGINT,           -- Rounded down, no decimals
    UserSalary BIGINT,             -- User entered salary
    LastSalaryUpdateDate DATETIME2,
    -- Application Fields
    ApplicationNo NVARCHAR(50),
    ApplicationType NVARCHAR(20),  -- LOAN, CARD
    ApplicationStatus NVARCHAR(20),
    -- Consent Fields
    ConsentValue BIT,
    ConsentDate DATETIME2,
    -- Nafath Fields
    NafathStatus NVARCHAR(20),
    NafathTransId NVARCHAR(100),
    NafathDate DATETIME2,
    -- Tracking Fields
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2,
    LastLoginAt DATETIME2,
    Status NVARCHAR(20) DEFAULT 'ACTIVE',
    -- Indexes
    INDEX idx_national_id (NationalId),
    INDEX idx_application (ApplicationNo, ApplicationType),
    INDEX idx_phone (Phone),
    INDEX idx_salaries (DakhliSalary, UserSalary)
)
```

### Applications Table
```sql
CREATE TABLE Applications (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    CustomerId BIGINT NOT NULL,
    ApplicationNo NVARCHAR(50) UNIQUE NOT NULL,
    ApplicationType NVARCHAR(20) NOT NULL,  -- LOAN, CARD
    Status NVARCHAR(20) NOT NULL,
    Amount DECIMAL(18,2),
    Tenure INT,
    MonthlyPayment DECIMAL(18,2),
    DecisionStatus NVARCHAR(20),
    DecisionDate DATETIME2,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2,
    FOREIGN KEY (CustomerId) REFERENCES Customers(Id),
    INDEX idx_customer_apps (CustomerId, ApplicationType, Status)
)
```

## Notification System

### Notification Templates
```sql
CREATE TABLE NotificationTemplates (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    Title NVARCHAR(255),
    Body NVARCHAR(MAX),
    TitleEn NVARCHAR(255),
    BodyEn NVARCHAR(MAX),
    TitleAr NVARCHAR(255),
    BodyAr NVARCHAR(MAX),
    Route NVARCHAR(255),
    AdditionalData NVARCHAR(MAX),      -- JSON data
    TargetCriteria NVARCHAR(MAX),      -- JSON data
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    ExpiryAt DATETIME2,
    INDEX idx_template_expiry (ExpiryAt)
)
```

### Notifications
```sql
CREATE TABLE Notifications (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    NationalId NVARCHAR(10) NOT NULL,  -- Link to Customers
    Title NVARCHAR(255) NOT NULL,
    Body NVARCHAR(MAX) NOT NULL,
    Route NVARCHAR(255) DEFAULT '/home',
    IsArabic BIT DEFAULT 1,
    AdditionalData NVARCHAR(MAX),      -- JSON data
    Status NVARCHAR(10) DEFAULT 'unread' CHECK (Status IN ('unread', 'read')),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    INDEX idx_national_status (NationalId, Status),
    FOREIGN KEY (NationalId) REFERENCES Customers(NationalId)
)
```

## Admin Portal (Windows Authentication)

### Admin Users
```sql
CREATE TABLE AdminUsers (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    WindowsUsername NVARCHAR(100) UNIQUE NOT NULL,  -- Domain\Username
    EmployeeId NVARCHAR(20) UNIQUE NOT NULL,       -- Company employee ID
    FullName NVARCHAR(100) NOT NULL,
    ArabicName NVARCHAR(100),
    Email NVARCHAR(100) UNIQUE NOT NULL,
    Department NVARCHAR(50),
    Position NVARCHAR(50),
    Status NVARCHAR(20) DEFAULT 'ACTIVE' CHECK (Status IN ('ACTIVE', 'INACTIVE', 'BLOCKED')),
    LastLoginAt DATETIME2,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2,
    CreatedBy BIGINT,
    UpdatedBy BIGINT,
    INDEX idx_windows_user (WindowsUsername),
    INDEX idx_employee_id (EmployeeId),
    INDEX idx_status (Status)
)
```

### Admin Roles
```sql
CREATE TABLE AdminRoles (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(50) UNIQUE NOT NULL,
    Description NVARCHAR(255),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2,
    CreatedBy BIGINT,
    UpdatedBy BIGINT,
    FOREIGN KEY (CreatedBy) REFERENCES AdminUsers(Id),
    FOREIGN KEY (UpdatedBy) REFERENCES AdminUsers(Id)
)
```

### Admin Action Logs
```sql
CREATE TABLE AdminActionLogs (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserId BIGINT NOT NULL,
    WindowsUsername NVARCHAR(100) NOT NULL,
    Action NVARCHAR(50) NOT NULL,      -- LOGIN, LOGOUT, CREATE, UPDATE, DELETE, VIEW
    Module NVARCHAR(50) NOT NULL,      -- Which part of the system
    EntityType NVARCHAR(50),           -- e.g., CUSTOMER, APPLICATION, USER
    EntityId NVARCHAR(100),            -- ID of the affected entity
    Details NVARCHAR(MAX),             -- JSON format for action details
    IpAddress NVARCHAR(45),            -- Support IPv6
    HostName NVARCHAR(100),            -- Windows machine name
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (UserId) REFERENCES AdminUsers(Id),
    INDEX idx_user_action (UserId, Action, CreatedAt),
    INDEX idx_windows_user (WindowsUsername)
)
```

## Configuration

### Master Config
```sql
CREATE TABLE MasterConfig (
    ConfigId BIGINT IDENTITY(1,1) PRIMARY KEY,
    Page NVARCHAR(255) NOT NULL,
    KeyName NVARCHAR(255) NOT NULL,
    Value NVARCHAR(MAX) NOT NULL,      -- JSON data
    LastUpdated DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT UQ_Page_KeyName UNIQUE (Page, KeyName),
    INDEX idx_page_key (Page, KeyName)
)
```

Example configuration:
```sql
-- App version settings
INSERT INTO MasterConfig (Page, KeyName, Value) VALUES
(
    'app',
    'version_settings',
    '{
        "min_version": "1.0.0",
        "latest_version": "1.2.0",
        "force_update": false,
        "update_message": {
            "en": "Please update your app",
            "ar": "يرجى تحديث التطبيق"
        }
    }'
)
```

## Notes

1. All string fields use `NVARCHAR` for proper Arabic text support
2. JSON data is stored in `NVARCHAR(MAX)` fields
3. Dates use `DATETIME2` for better precision
4. Appropriate indexes are created for common queries
5. Windows Authentication is used for admin portal
6. Salaries are stored as `BIGINT` without decimals 