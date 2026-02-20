-- Employee Onboarding MCP Server Database Initialization
-- Compatible with both H2 and PostgreSQL

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
('EMP003', 'Robert', 'Wilson', 'robert.wilson@company.com', '+1-555-0301', 1, 'HR Specialist', '2024-01-20', 'ACTIVE', 60000.00, '789 Pine Rd, City, State 12347', 'Nancy Wilson', '+1-555-0302'),
('EMP004', 'Jennifer', 'Brown', 'jennifer.brown@company.com', '+1-555-0401', 4, 'Financial Analyst', '2024-02-15', 'PENDING', 65000.00, '321 Elm St, City, State 12348', 'Tom Brown', '+1-555-0402'),
('EMP005', 'Alex', 'Davis', 'alex.davis@company.com', '+1-555-0501', 2, 'Junior Developer', '2024-03-01', 'PENDING', 55000.00, '654 Maple Dr, City, State 12349', 'Sam Davis', '+1-555-0502');

-- Insert sample employee documents
INSERT INTO employee_documents (employee_id, document_type, document_name, document_status) VALUES
(1, 'ID_PROOF', 'drivers_license.pdf', 'VERIFIED'),
(1, 'ADDRESS_PROOF', 'utility_bill.pdf', 'VERIFIED'),
(1, 'EDUCATION', 'degree_certificate.pdf', 'VERIFIED'),
(2, 'ID_PROOF', 'passport.pdf', 'VERIFIED'),
(2, 'ADDRESS_PROOF', 'lease_agreement.pdf', 'PENDING'),
(3, 'ID_PROOF', 'drivers_license.pdf', 'VERIFIED'),
(3, 'EDUCATION', 'hr_certification.pdf', 'VERIFIED'),
(4, 'ID_PROOF', 'state_id.pdf', 'PENDING'),
(4, 'EDUCATION', 'mba_certificate.pdf', 'PENDING'),
(5, 'ID_PROOF', 'drivers_license.pdf', 'PENDING');

-- Create indexes for better performance
CREATE INDEX idx_employees_employee_id ON employees(employee_id);
CREATE INDEX idx_employees_email ON employees(email);
CREATE INDEX idx_employees_department ON employees(department_id);
CREATE INDEX idx_employees_status ON employees(status);
CREATE INDEX idx_employee_documents_employee_id ON employee_documents(employee_id);
CREATE INDEX idx_employee_documents_type ON employee_documents(document_type);
CREATE INDEX idx_employee_documents_status ON employee_documents(document_status);

-- Insert completion marker
INSERT INTO departments (name, description) VALUES ('_INIT_COMPLETE_', 'Database initialization completed successfully');
