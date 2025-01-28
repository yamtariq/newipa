/*
===========================================
Authentication & Security Tables
===========================================
*/

-- AuditTrail Table Structure
CREATE TABLE AuditTrail (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id NVARCHAR(20),
    action_description NVARCHAR(255) NOT NULL,
    ip_address NVARCHAR(45) NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    details NVARCHAR(MAX)
);

-- auth_logs Table Structure
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

-- API_Keys Table Structure
CREATE TABLE API_Keys (
    api_key NVARCHAR(255) NOT NULL UNIQUE,
    description NVARCHAR(500),
    expires_at DATETIME2,
    created_at DATETIME2 DEFAULT GETDATE(),
    last_used_at DATETIME2
);

/*
===========================================
User Management Tables
===========================================
*/

-- Customers Table Structure
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

-- customer_devices Table Structure
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

-- OTP_Codes Table Structure
CREATE TABLE OTP_Codes (
    national_id NVARCHAR(20) NOT NULL,
    otp_code NVARCHAR(255) NOT NULL,
    expires_at DATETIME2 NOT NULL,
    is_used BIT DEFAULT 0,
    created_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_OTP_Codes_national_id FOREIGN KEY (national_id) 
        REFERENCES Customers(national_id)
);

/*
===========================================
Application Tables
===========================================
*/

-- loan_application_details Table Structure
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

-- card_application_details Table Structure
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

/*
===========================================
Notification Tables
===========================================
*/

-- user_notifications Table Structure
CREATE TABLE user_notifications (
    notification_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    national_id NVARCHAR(20) NOT NULL,
    notifications NVARCHAR(MAX), -- JSON data
    created_at DATETIME2 DEFAULT GETDATE(),
    last_updated DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_user_notifications_national_id FOREIGN KEY (national_id) 
        REFERENCES Customers(national_id)
);

-- notification_templates Table Structure
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

/*
===========================================
Content Management Tables
===========================================
*/

-- master_config Table Structure
CREATE TABLE master_config (
    config_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    page NVARCHAR(50) NOT NULL,
    key_name NVARCHAR(100) NOT NULL,
    value NVARCHAR(MAX), -- JSON data
    last_updated DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT UQ_master_config_page_key UNIQUE (page, key_name)
);

-- Create indexes for better performance
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