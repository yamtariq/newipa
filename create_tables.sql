-- Create all tables with their structures

CREATE TABLE auth_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    national_id VARCHAR(20) NOT NULL,
    deviceId VARCHAR(100),
    auth_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    failure_reason VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

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
    consent BOOLEAN DEFAULT FALSE,
    consent_date TIMESTAMP,
    nafath_status VARCHAR(50),
    nafath_timestamp TIMESTAMP
);

CREATE TABLE customer_devices (
    device_id INT AUTO_INCREMENT PRIMARY KEY,
    national_id VARCHAR(20) NOT NULL,
    deviceId VARCHAR(100) NOT NULL,
    platform VARCHAR(50),
    model VARCHAR(100),
    manufacturer VARCHAR(100),
    biometric_enabled BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP,
    FOREIGN KEY (national_id) REFERENCES Customers(national_id)
);

CREATE TABLE user_tokens (
    token_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(20) NOT NULL,
    national_id VARCHAR(20) NOT NULL,
    refresh_token VARCHAR(255) NOT NULL,
    refresh_expires_at TIMESTAMP,
    access_token VARCHAR(255),
    access_expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (national_id) REFERENCES Customers(national_id)
);

CREATE TABLE OTP_Codes (
    otp_id INT AUTO_INCREMENT PRIMARY KEY,
    national_id VARCHAR(20) NOT NULL,
    otp_code VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (national_id) REFERENCES Customers(national_id)
);

CREATE TABLE API_Keys (
    key_id INT AUTO_INCREMENT PRIMARY KEY,
    api_key VARCHAR(255) NOT NULL UNIQUE,
    description VARCHAR(500),
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP
);

CREATE TABLE loan_application_details (
    loan_id INT AUTO_INCREMENT PRIMARY KEY,
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

CREATE TABLE card_application_details (
    card_id INT AUTO_INCREMENT PRIMARY KEY,
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

CREATE TABLE user_notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    national_id VARCHAR(20) NOT NULL,
    notifications JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (national_id) REFERENCES Customers(national_id)
);

CREATE TABLE notification_templates (
    id INT AUTO_INCREMENT PRIMARY KEY,
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

CREATE TABLE master_config (
    config_id INT AUTO_INCREMENT PRIMARY KEY,
    page VARCHAR(50) NOT NULL,
    key_name VARCHAR(100) NOT NULL,
    value JSON,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_page_key (page, key_name)
);

-- Create indexes for better performance
CREATE INDEX idx_auth_logs_national_id ON auth_logs(national_id);
CREATE INDEX idx_auth_logs_created_at ON auth_logs(created_at);
CREATE INDEX idx_customer_devices_national_id ON customer_devices(national_id);
CREATE INDEX idx_customer_devices_deviceId ON customer_devices(deviceId);
CREATE INDEX idx_user_tokens_national_id ON user_tokens(national_id);
CREATE INDEX idx_user_tokens_refresh_token ON user_tokens(refresh_token);
CREATE INDEX idx_OTP_Codes_national_id ON OTP_Codes(national_id);
CREATE INDEX idx_loan_application_national_id ON loan_application_details(national_id);
CREATE INDEX idx_loan_application_status ON loan_application_details(status);
CREATE INDEX idx_card_application_national_id ON card_application_details(national_id);
CREATE INDEX idx_card_application_status ON card_application_details(status);
CREATE INDEX idx_user_notifications_national_id ON user_notifications(national_id);
CREATE INDEX idx_notification_templates_expiry ON notification_templates(expiry_at);
CREATE INDEX idx_master_config_page ON master_config(page);