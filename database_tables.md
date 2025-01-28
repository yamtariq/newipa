# Database Tables Documentation

This document provides a comprehensive overview of all database tables used in the Nayifat application, with both MySQL and MSSQL implementations.

## Authentication & Security Tables

### AuditTrail
Tracks all system audit events.

#### MySQL
```sql
CREATE TABLE AuditTrail (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(20),
    action_description VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    details TEXT
);
```

#### MSSQL
```sql
CREATE TABLE AuditTrail (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id NVARCHAR(20),
    action_description NVARCHAR(255) NOT NULL,
    ip_address NVARCHAR(45) NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    details NVARCHAR(MAX)
);
```

### auth_logs
Tracks authentication attempts and security events.

#### MySQL
```sql
CREATE TABLE auth_logs (
    national_id VARCHAR(20) NOT NULL,
    deviceId VARCHAR(100),
    auth_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    failure_reason VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### MSSQL
```sql
CREATE TABLE auth_logs (
    national_id NVARCHAR(20) NOT NULL,
    deviceId NVARCHAR(100),
    auth_type NVARCHAR(50) NOT NULL,
    status NVARCHAR(20) NOT NULL,
    ip_address NVARCHAR(45),
    user_agent NVARCHAR(500),
    failure_reason NVARCHAR(500),
    created_at DATETIME2 DEFAULT GETDATE()
);
```

### API_Keys
Manages API authentication keys.

#### MySQL
```sql
CREATE TABLE API_Keys (
    api_key VARCHAR(255) NOT NULL UNIQUE,
    description VARCHAR(500),
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP
);
```

#### MSSQL
```sql
CREATE TABLE API_Keys (
    api_key NVARCHAR(255) NOT NULL UNIQUE,
    description NVARCHAR(500),
    expires_at DATETIME2,
    created_at DATETIME2 DEFAULT GETDATE(),
    last_used_at DATETIME2
);
```

## User Management Tables

### Customers
Primary customer information table.

#### MySQL
```sql
CREATE TABLE Customers (
    national_id VARCHAR(20) PRIMARY KEY,
    first_name_en VARCHAR(50),
    second_name_en VARCHAR(50),
    third_name_en VARCHAR(50),
    family_name_en VARCHAR(50),
    first_name_ar VARCHAR(50),
    second_name_ar VARCHAR(50),
    third_name_ar VARCHAR(50),
    family_name_ar VARCHAR(50),
    date_of_birth DATE,
    id_expiry_date DATE,
    email VARCHAR(100),
    phone VARCHAR(20),
    building_no VARCHAR(20),
    street VARCHAR(100),
    district VARCHAR(100),
    city VARCHAR(100),
    zipcode VARCHAR(10),
    add_no VARCHAR(20),
    iban VARCHAR(50),
    dependents INT,
    salary_dakhli DECIMAL(18,2),
    salary_customer DECIMAL(18,2),
    los INT,
    sector VARCHAR(100),
    employer VARCHAR(200),
    password VARCHAR(255),
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    consent TINYINT(1) DEFAULT 0,
    consent_date TIMESTAMP,
    nafath_status VARCHAR(50),
    nafath_timestamp TIMESTAMP
);
```

#### MSSQL
```sql
CREATE TABLE Customers (
    national_id NVARCHAR(20) PRIMARY KEY,
    first_name_en NVARCHAR(50),
    second_name_en NVARCHAR(50),
    third_name_en NVARCHAR(50),
    family_name_en NVARCHAR(50),
    first_name_ar NVARCHAR(50),
    second_name_ar NVARCHAR(50),
    third_name_ar NVARCHAR(50),
    family_name_ar NVARCHAR(50),
    date_of_birth DATE,
    id_expiry_date DATE,
    email NVARCHAR(100),
    phone NVARCHAR(20),
    building_no NVARCHAR(20),
    street NVARCHAR(100),
    district NVARCHAR(100),
    city NVARCHAR(100),
    zipcode NVARCHAR(10),
    add_no NVARCHAR(20),
    iban NVARCHAR(50),
    dependents INT,
    salary_dakhli DECIMAL(18,2),
    salary_customer DECIMAL(18,2),
    los INT,
    sector NVARCHAR(100),
    employer NVARCHAR(200),
    password NVARCHAR(255),
    registration_date DATETIME2 DEFAULT GETDATE(),
    consent BIT DEFAULT 0,
    consent_date DATETIME2,
    nafath_status NVARCHAR(50),
    nafath_timestamp DATETIME2
);
```

### customer_devices
Manages customer device registrations.

#### MySQL
```sql
CREATE TABLE customer_devices (
    national_id VARCHAR(20) NOT NULL,
    deviceId VARCHAR(100) NOT NULL,
    platform VARCHAR(50),
    model VARCHAR(100),
    manufacturer VARCHAR(100),
    biometric_enabled TINYINT(1) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP,
    FOREIGN KEY (national_id) REFERENCES Customers(national_id)
);
```

#### MSSQL
```sql
CREATE TABLE customer_devices (
    national_id NVARCHAR(20) NOT NULL,
    deviceId NVARCHAR(100) NOT NULL,
    platform NVARCHAR(50),
    model NVARCHAR(100),
    manufacturer NVARCHAR(100),
    biometric_enabled BIT DEFAULT 0,
    status NVARCHAR(20) DEFAULT 'active',
    created_at DATETIME2 DEFAULT GETDATE(),
    last_used_at DATETIME2,
    CONSTRAINT FK_customer_devices_national_id FOREIGN KEY (national_id) 
        REFERENCES Customers(national_id)
);
```

### OTP_Codes
Manages one-time passwords.

#### MySQL
```sql
CREATE TABLE OTP_Codes (
    national_id VARCHAR(20) NOT NULL,
    otp_code VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    is_used TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (national_id) REFERENCES Customers(national_id)
);
```

#### MSSQL
```sql
CREATE TABLE OTP_Codes (
    national_id NVARCHAR(20) NOT NULL,
    otp_code NVARCHAR(255) NOT NULL,
    expires_at DATETIME2 NOT NULL,
    is_used BIT DEFAULT 0,
    created_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_OTP_Codes_national_id FOREIGN KEY (national_id) 
        REFERENCES Customers(national_id)
);
```

## Application Tables

### loan_application_details
Tracks loan applications.

#### MySQL
```sql
CREATE TABLE loan_application_details (
    loan_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    application_no VARCHAR(20) NOT NULL UNIQUE,
    national_id VARCHAR(20) NOT NULL,
    status VARCHAR(50) NOT NULL,
    status_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    loan_amount DECIMAL(18,2),
    tenure INT,
    monthly_payment DECIMAL(18,2),
    interest_rate DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (national_id) REFERENCES Customers(national_id)
);
```

#### MSSQL
```sql
CREATE TABLE loan_application_details (
    loan_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    application_no NVARCHAR(20) NOT NULL UNIQUE,
    national_id NVARCHAR(20) NOT NULL,
    status NVARCHAR(50) NOT NULL,
    status_date DATETIME2 DEFAULT GETDATE(),
    loan_amount DECIMAL(18,2),
    tenure INT,
    monthly_payment DECIMAL(18,2),
    interest_rate DECIMAL(5,2),
    created_at DATETIME2 DEFAULT GETDATE(),
    last_updated DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_loan_application_national_id FOREIGN KEY (national_id) 
        REFERENCES Customers(national_id)
);
```

### card_application_details
Tracks credit card applications.

#### MySQL
```sql
CREATE TABLE card_application_details (
    card_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    application_no VARCHAR(20) NOT NULL UNIQUE,
    national_id VARCHAR(20) NOT NULL,
    card_type VARCHAR(50) NOT NULL,
    card_limit DECIMAL(18,2),
    status VARCHAR(50) NOT NULL,
    status_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (national_id) REFERENCES Customers(national_id)
);
```

#### MSSQL
```sql
CREATE TABLE card_application_details (
    card_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    application_no NVARCHAR(20) NOT NULL UNIQUE,
    national_id NVARCHAR(20) NOT NULL,
    card_type NVARCHAR(50) NOT NULL,
    card_limit DECIMAL(18,2),
    status NVARCHAR(50) NOT NULL,
    status_date DATETIME2 DEFAULT GETDATE(),
    created_at DATETIME2 DEFAULT GETDATE(),
    last_updated DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_card_application_national_id FOREIGN KEY (national_id) 
        REFERENCES Customers(national_id)
);
```

## Notification Tables

### user_notifications
Stores user notifications.

#### MySQL
```sql
CREATE TABLE user_notifications (
    notification_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    national_id VARCHAR(20) NOT NULL,
    notifications JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (national_id) REFERENCES Customers(national_id)
);
```

#### MSSQL
```sql
CREATE TABLE user_notifications (
    notification_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    national_id NVARCHAR(20) NOT NULL,
    notifications NVARCHAR(MAX), -- JSON data
    created_at DATETIME2 DEFAULT GETDATE(),
    last_updated DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_user_notifications_national_id FOREIGN KEY (national_id) 
        REFERENCES Customers(national_id)
);
```

### notification_templates
Stores notification templates.

#### MySQL
```sql
CREATE TABLE notification_templates (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200),
    body VARCHAR(1000),
    title_en VARCHAR(200),
    body_en VARCHAR(1000),
    title_ar VARCHAR(200),
    body_ar VARCHAR(1000),
    route VARCHAR(100),
    additional_data JSON,
    expiry_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

#### MSSQL
```sql
CREATE TABLE notification_templates (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    title NVARCHAR(200),
    body NVARCHAR(1000),
    title_en NVARCHAR(200),
    body_en NVARCHAR(1000),
    title_ar NVARCHAR(200),
    body_ar NVARCHAR(1000),
    route NVARCHAR(100),
    additional_data NVARCHAR(MAX), -- JSON data
    expiry_at DATETIME2,
    created_at DATETIME2 DEFAULT GETDATE(),
    last_updated DATETIME2 DEFAULT GETDATE()
);
```

## Content Management Tables

### master_config
Manages system configuration and content.

#### MySQL
```sql
CREATE TABLE master_config (
    config_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    page VARCHAR(50) NOT NULL,
    key_name VARCHAR(100) NOT NULL,
    value JSON,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_page_key (page, key_name)
);
```

#### MSSQL
```sql
CREATE TABLE master_config (
    config_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    page NVARCHAR(50) NOT NULL,
    key_name NVARCHAR(100) NOT NULL,
    value NVARCHAR(MAX), -- JSON data
    last_updated DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT UQ_master_config_page_key UNIQUE (page, key_name)
);
```

## Indexes

The following indexes are maintained for performance optimization:

```sql
CREATE INDEX IX_auth_logs_national_id ON auth_logs(national_id);
CREATE INDEX IX_auth_logs_created_at ON auth_logs(created_at);
CREATE INDEX IX_customer_devices_national_id ON customer_devices(national_id);
CREATE INDEX IX_customer_devices_deviceId ON customer_devices(deviceId);
CREATE INDEX IX_OTP_Codes_national_id ON OTP_Codes(national_id);
CREATE INDEX IX_loan_application_national_id ON loan_application_details(national_id);
CREATE INDEX IX_loan_application_status ON loan_application_details(status);
CREATE INDEX IX_card_application_national_id ON card_application_details(national_id);
CREATE INDEX IX_card_application_status ON card_application_details(status);
CREATE INDEX IX_user_notifications_national_id ON user_notifications(national_id);
CREATE INDEX IX_notification_templates_expiry ON notification_templates(expiry_at);
CREATE INDEX IX_master_config_page ON master_config(page);
```

## Key Differences Between MySQL and MSSQL Implementations

1. **Data Types**:
   - MySQL's `VARCHAR` → MSSQL's `NVARCHAR` for better Unicode/Arabic support
   - MySQL's `TIMESTAMP` → MSSQL's `DATETIME2` for timestamps
   - MySQL's `TINYINT(1)` → MSSQL's `BIT` for boolean values
   - MySQL's `JSON` → MSSQL's `NVARCHAR(MAX)` for JSON data

2. **Auto-Increment**:
   - MySQL: `AUTO_INCREMENT`
   - MSSQL: `IDENTITY(1,1)`

3. **Default Values**:
   - MySQL: `CURRENT_TIMESTAMP`
   - MSSQL: `GETDATE()`

4. **Constraint Naming**:
   - MSSQL uses explicit constraint names (e.g., `FK_customer_devices_national_id`)
   - MySQL uses implicit constraint names

5. **JSON Support**:
   - MySQL has native JSON type
   - MSSQL uses NVARCHAR(MAX) with JSON functions