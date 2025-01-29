/*
===========================================
Authentication & Security Tables
===========================================
*/

-- AuditTrail Table Structure
-- -------------------------
Field                Type                Null    Key     Default  Extra
id                  bigint              NO      PRI     NULL     auto_increment
user_id             varchar(20)          YES            NULL
action_description  varchar(255)         NO             NULL
ip_address          varchar(45)          NO             NULL
created_at          datetime2           NO             CURRENT_TIMESTAMP
details             text                YES            NULL

-- auth_logs Table Structure
-- ------------------------
Field                Type                Null    Key     Default  Extra
national_id         varchar(20)          NO      MUL     NULL
deviceId            varchar(100)         YES            NULL
auth_type           varchar(50)          NO             NULL
status              varchar(20)          NO             NULL
ip_address          varchar(45)          YES            NULL
user_agent          varchar(500)         YES            NULL
failure_reason      varchar(500)         YES            NULL
created_at          datetime2            NO             CURRENT_TIMESTAMP

-- API_Keys Table Structure
-- -----------------------
Field                Type                Null    Key     Default  Extra
api_key             varchar(255)         NO      UNI     NULL
description         varchar(500)         YES            NULL
expires_at          datetime2           YES            NULL
created_at          datetime2           NO             CURRENT_TIMESTAMP
last_used_at        datetime2           YES            NULL


/*
===========================================
User Management Tables
===========================================
*/

-- Customers Table Structure
-- ------------------------
Field                Type                Null    Key     Default  Extra
national_id         varchar(20)          NO      PRI     NULL
first_name_en       varchar(50)          YES            NULL
second_name_en      varchar(50)          YES            NULL
third_name_en       varchar(50)          YES            NULL
family_name_en      varchar(50)          YES            NULL
first_name_ar       varchar(50)          YES            NULL
second_name_ar      varchar(50)          YES            NULL
third_name_ar       varchar(50)          YES            NULL
family_name_ar      varchar(50)          YES            NULL
date_of_birth       date                YES            NULL
id_expiry_date      date                YES            NULL
email               varchar(100)         YES            NULL
phone               varchar(20)          YES            NULL
building_no         varchar(20)          YES            NULL
street              varchar(100)         YES            NULL
district            varchar(100)         YES            NULL
city                varchar(100)         YES            NULL
zipcode             varchar(10)          YES            NULL
add_no              varchar(20)          YES            NULL
iban                varchar(50)          YES            NULL
dependents          int                 YES            NULL
salary_dakhli       decimal(18,2)       YES            NULL
salary_customer     decimal(18,2)       YES            NULL
los                 int                 YES            NULL
sector              varchar(100)         YES            NULL
employer            varchar(200)         YES            NULL
password            varchar(255)         YES            NULL
registration_date   datetime2           NO             CURRENT_TIMESTAMP
consent             tinyint(1)          NO             0
consent_date        datetime2           YES            NULL
nafath_status       varchar(50)         YES            NULL
nafath_timestamp    datetime2           YES            NULL

-- customer_devices Table Structure
-- -------------------------------
Field                Type                Null    Key     Default  Extra
national_id         varchar(20)          NO      MUL     NULL
deviceId            varchar(100)         NO             NULL
platform            varchar(50)          YES            NULL
model               varchar(100)         YES            NULL
manufacturer        varchar(100)         YES            NULL
biometric_enabled   tinyint(1)          NO             0
status              varchar(20)          NO             'active'
created_at          datetime2           NO             CURRENT_TIMESTAMP
last_used_at        datetime2           YES            NULL

-- OTP_Codes Table Structure
-- ------------------------
Field                Type                Null    Key     Default  Extra
national_id         varchar(20)          NO      MUL     NULL
otp_code            varchar(255)         NO             NULL
expires_at          datetime2           NO             NULL
is_used             tinyint(1)          NO             0
created_at          datetime2           NO             CURRENT_TIMESTAMP


/*
===========================================
Application Tables
===========================================
*/

-- loan_application_details Table Structure
-- --------------------------------------
Field                Type                Null    Key     Default  Extra
loan_id             bigint              NO      PRI     NULL     auto_increment
application_no      varchar(20)         NO      UNI     NULL
national_id         varchar(20)          NO      MUL     NULL
status              varchar(50)          NO             NULL
status_date         datetime2           NO             CURRENT_TIMESTAMP
loan_amount         decimal(18,2)       YES            NULL
tenure              int                 YES            NULL
monthly_payment     decimal(18,2)       YES            NULL
interest_rate       decimal(5,2)        YES            NULL
created_at          datetime2           NO             CURRENT_TIMESTAMP
last_updated        datetime2           NO             CURRENT_TIMESTAMP

-- card_application_details Table Structure
-- --------------------------------------
Field                Type                Null    Key     Default  Extra
card_id             bigint              NO      PRI     NULL     auto_increment
application_no      varchar(20)         NO      UNI     NULL
national_id         varchar(20)          NO      MUL     NULL
card_type           varchar(50)          NO             NULL
card_limit          decimal(18,2)       YES            NULL
status              varchar(50)          NO             NULL
status_date         datetime2           NO             CURRENT_TIMESTAMP
created_at          datetime2           NO             CURRENT_TIMESTAMP
last_updated        datetime2           NO             CURRENT_TIMESTAMP


/*
===========================================
Notification Tables
===========================================
*/

-- user_notifications Table Structure
-- --------------------------------
Field                Type                Null    Key     Default  Extra
notification_id     bigint              NO      PRI     NULL     auto_increment
national_id         varchar(20)          NO      MUL     NULL
notifications       json                YES            NULL
created_at          datetime2           NO             CURRENT_TIMESTAMP
last_updated        datetime2           NO             CURRENT_TIMESTAMP

-- notification_templates Table Structure
-- ------------------------------------
Field                Type                Null    Key     Default  Extra
id                  bigint              NO      PRI     NULL     auto_increment
title               varchar(200)         YES            NULL
body                varchar(1000)        YES            NULL
title_en            varchar(200)         YES            NULL
body_en             varchar(1000)        YES            NULL
title_ar            varchar(200)         YES            NULL
body_ar             varchar(1000)        YES            NULL
route               varchar(100)         YES            NULL
additional_data     json                YES            NULL
expiry_at           datetime2           YES            NULL
created_at          datetime2           NO             CURRENT_TIMESTAMP
last_updated        datetime2           NO             CURRENT_TIMESTAMP


/*
===========================================
Content Management Tables
===========================================
*/

-- master_config Table Structure
-- ----------------------------
Field                Type                Null    Key     Default  Extra
config_id           bigint              NO      PRI     NULL     auto_increment
page                varchar(50)          NO      MUL     NULL
key_name            varchar(100)         NO             NULL
value               json                YES            NULL
last_updated        datetime2           NO             CURRENT_TIMESTAMP