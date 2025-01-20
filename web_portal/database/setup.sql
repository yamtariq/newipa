- Create portal_employees table
CREATE TABLE IF NOT EXISTS portal_employees (
    employee_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    phone VARCHAR(15),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_login DATETIME,
    status ENUM('active', 'inactive') DEFAULT 'active'
);

-- Create portal_roles table
CREATE TABLE IF NOT EXISTS portal_roles (
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT NOT NULL,
    role VARCHAR(50) NOT NULL,
    assigned_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (employee_id) REFERENCES portal_employees(employee_id) ON DELETE CASCADE
);

-- Create portal_activity_log table
CREATE TABLE IF NOT EXISTS portal_activity_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT NOT NULL,
    action VARCHAR(100) NOT NULL,
    details TEXT,
    ip_address VARCHAR(45),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (employee_id) REFERENCES portal_employees(employee_id)
);

-- Insert default super admin
INSERT INTO portal_employees (name, email, password, phone, created_at) VALUES (
    'Super Admin',
    'admin@nayifat.com',
    '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- password: 'password'
    '0501234567',
    NOW()
);

-- Assign super admin role
INSERT INTO portal_roles (employee_id, role)
SELECT employee_id, 'super_admin'
FROM portal_employees
WHERE email = 'admin@nayifat.com'
LIMIT 1;
