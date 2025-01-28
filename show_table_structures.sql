-- Show structure of all tables in the database

-- Auth Logs table
SHOW CREATE TABLE auth_logs;
DESCRIBE auth_logs;

-- Customers table
SHOW CREATE TABLE Customers;
DESCRIBE Customers;

-- Customer Devices table
SHOW CREATE TABLE customer_devices;
DESCRIBE customer_devices;

-- User Tokens table
SHOW CREATE TABLE user_tokens;
DESCRIBE user_tokens;

-- OTP Codes table
SHOW CREATE TABLE OTP_Codes;
DESCRIBE OTP_Codes;

-- API Keys table
SHOW CREATE TABLE API_Keys;
DESCRIBE API_Keys;

-- Loan Application Details table
SHOW CREATE TABLE loan_application_details;
DESCRIBE loan_application_details;

-- Card Application Details table
SHOW CREATE TABLE card_application_details;
DESCRIBE card_application_details;

-- User Notifications table
SHOW CREATE TABLE user_notifications;
DESCRIBE user_notifications;

-- Notification Templates table
SHOW CREATE TABLE notification_templates;
DESCRIBE notification_templates;

-- Master Config table
SHOW CREATE TABLE master_config;
DESCRIBE master_config;

-- Alternative method using information_schema (more detailed)
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    COLUMN_TYPE,
    IS_NULLABLE,
    COLUMN_KEY,
    COLUMN_DEFAULT,
    EXTRA,
    COLUMN_COMMENT
FROM 
    information_schema.COLUMNS 
WHERE 
    TABLE_SCHEMA = DATABASE()
ORDER BY 
    TABLE_NAME, 
    ORDINAL_POSITION;

-- Show all foreign key relationships
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM
    information_schema.KEY_COLUMN_USAGE
WHERE
    REFERENCED_TABLE_SCHEMA = DATABASE()
    AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY
    TABLE_NAME,
    COLUMN_NAME;

-- Show all indexes
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    COLUMN_NAME,
    NON_UNIQUE
FROM 
    information_schema.STATISTICS
WHERE 
    TABLE_SCHEMA = DATABASE()
ORDER BY 
    TABLE_NAME,
    INDEX_NAME,
    SEQ_IN_INDEX;