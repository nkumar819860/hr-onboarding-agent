-- HR Onboarding Agent - Combined Database Initialization
-- This script initializes both Employee and Asset databases

-- Create databases if they don't exist (PostgreSQL)
-- Note: In PostgreSQL, we'll use schemas instead of separate databases for simplicity

-- Employee Onboarding Schema
CREATE SCHEMA IF NOT EXISTS employee_schema;
SET search_path TO employee_schema;

-- Drop tables if they exist (for clean restart)
DROP TABLE IF EXISTS employee_documents CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;

-- Create departments table
CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    manager_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create employees table
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    employee_id VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    department_id INTEGER REFERENCES departments(id),
    position VARCHAR(100),
    hire_date DATE,
    status VARCHAR(20) DEFAULT 'PENDING',
    salary DECIMAL(10,2),
    manager_id INTEGER REFERENCES employees(id),
    address TEXT,
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create employee_documents table
CREATE TABLE employee_documents (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    document_type VARCHAR(50) NOT NULL,
    document_name VARCHAR(100) NOT NULL,
    document_path VARCHAR(255),
    document_status VARCHAR(20) DEFAULT 'PENDING',
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    verified_at TIMESTAMP NULL,
    verified_by VARCHAR(100)
);

-- Insert sample departments
INSERT INTO departments (name, description, manager_name) VALUES
('Human Resources', 'Employee management and relations', 'Sarah Johnson'),
('Engineering', 'Software development and technical operations', 'Michael Chen'),
('Marketing', 'Brand promotion and customer engagement', 'Emily Rodriguez'),
('Finance', 'Financial planning and accounting', 'David Kim'),
('Operations', 'Business operations and logistics', 'Lisa Thompson');

-- Insert sample employees
INSERT INTO employees (employee_id, first_name, last_name, email, phone, department_id, position, hire_date, status, salary, address, emergency_contact_name, emergency_contact_phone) VALUES
('EMP001', 'John', 'Smith', 'john.smith@company.com', '+1-555-0101', 2, 'Senior Software Engineer', '2024-01-15', 'ACTIVE', 85000.00, '123 Main St, City, State 12345', 'Jane Smith', '+1-555-0102'),
('EMP002', 'Maria', 'Garcia', 'maria.garcia@company.com', '+1-555-0201', 3, 'Marketing Manager', '2024-02-01', 'ACTIVE', 75000.00, '456 Oak Ave, City, State 12346', 'Carlos Garcia', '+1-555-0202'),
('EMP003', 'Robert', 'Wilson', 'robert.wilson@company.com', '+1-555-0301', 1, 'HR Specialist', '2024-01-20', 'ACTIVE', 60000.00, '789 Pine Rd, City, State 12347', 'Nancy Wilson', '+1-555-0302');

-- Insert sample employee documents
INSERT INTO employee_documents (employee_id, document_type, document_name, document_status) VALUES
(1, 'ID_PROOF', 'drivers_license.pdf', 'VERIFIED'),
(1, 'ADDRESS_PROOF', 'utility_bill.pdf', 'VERIFIED'),
(1, 'EDUCATION', 'degree_certificate.pdf', 'VERIFIED'),
(2, 'ID_PROOF', 'passport.pdf', 'VERIFIED'),
(2, 'ADDRESS_PROOF', 'lease_agreement.pdf', 'PENDING'),
(3, 'ID_PROOF', 'drivers_license.pdf', 'VERIFIED');

-- Asset Allocation Schema
CREATE SCHEMA IF NOT EXISTS asset_schema;
SET search_path TO asset_schema;

-- Drop tables if they exist (for clean restart)
DROP TABLE IF EXISTS asset_allocations CASCADE;
DROP TABLE IF EXISTS asset_inventory CASCADE;
DROP TABLE IF EXISTS asset_categories CASCADE;

-- Create asset categories table
CREATE TABLE asset_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255),
    requires_approval BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create asset inventory table
CREATE TABLE asset_inventory (
    id SERIAL PRIMARY KEY,
    asset_tag VARCHAR(20) UNIQUE NOT NULL,
    category_id INTEGER REFERENCES asset_categories(id),
    name VARCHAR(100) NOT NULL,
    brand VARCHAR(50),
    model VARCHAR(50),
    serial_number VARCHAR(100),
    purchase_date DATE,
    warranty_expires DATE,
    cost DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'AVAILABLE',
    location VARCHAR(100),
    condition_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create asset allocations table
CREATE TABLE asset_allocations (
    id SERIAL PRIMARY KEY,
    asset_id INTEGER REFERENCES asset_inventory(id),
    employee_id INTEGER NOT NULL,
    allocated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expected_return_date DATE,
    actual_return_date TIMESTAMP NULL,
    status VARCHAR(20) DEFAULT 'ALLOCATED',
    allocated_by VARCHAR(100),
    return_condition VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert asset categories
INSERT INTO asset_categories (name, description, requires_approval) VALUES
('laptop', 'Laptop computers and notebooks', TRUE),
('monitor', 'Desktop monitors and displays', FALSE),
('keyboard', 'Keyboards and input devices', FALSE),
('mouse', 'Computer mice and pointing devices', FALSE),
('headset', 'Headphones and communication devices', FALSE),
('phone', 'Mobile phones and desk phones', TRUE),
('access_card', 'Building and system access cards', TRUE);

-- Insert sample asset inventory
INSERT INTO asset_inventory (asset_tag, category_id, name, brand, model, serial_number, status, location, cost) VALUES
('LAP001', 1, 'MacBook Pro 14"', 'Apple', 'M3 Pro', 'C02ABC123DEF', 'AVAILABLE', 'IT Storage', 2499.00),
('LAP002', 1, 'ThinkPad X1 Carbon', 'Lenovo', '11th Gen', 'PC0ABC123', 'AVAILABLE', 'IT Storage', 1899.00),
('MON001', 2, 'Dell UltraSharp 27"', 'Dell', 'U2723QE', 'DELL-MON-001', 'AVAILABLE', 'IT Storage', 599.00),
('KEY001', 3, 'Magic Keyboard', 'Apple', 'MK2A3', 'APPLE-KB-001', 'AVAILABLE', 'IT Storage', 179.00),
('MOU001', 4, 'Magic Mouse', 'Apple', 'MK2E3', 'APPLE-MS-001', 'AVAILABLE', 'IT Storage', 79.00),
('ACC001', 7, 'Employee Access Card', 'HID', 'ProxCard II', 'HID-ACC-001', 'AVAILABLE', 'Security Office', 15.00);

-- Create indexes for better performance
CREATE INDEX idx_employees_employee_id ON employee_schema.employees(employee_id);
CREATE INDEX idx_employees_email ON employee_schema.employees(email);
CREATE INDEX idx_asset_inventory_status ON asset_schema.asset_inventory(status);
CREATE INDEX idx_asset_allocations_employee ON asset_schema.asset_allocations(employee_id);

-- Reset search path to public
SET search_path TO public;

-- Grant permissions (adjust as needed for your security requirements)
GRANT ALL PRIVILEGES ON SCHEMA employee_schema TO postgres;
GRANT ALL PRIVILEGES ON SCHEMA asset_schema TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA employee_schema TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA asset_schema TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA employee_schema TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA asset_schema TO postgres;
