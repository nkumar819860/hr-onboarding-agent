-- Asset Allocation MCP Server Database Initialization
-- Compatible with both H2 and PostgreSQL

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
('desk', 'Office desks and workstations', TRUE),
('chair', 'Office chairs and seating', FALSE),
('access_card', 'Building and system access cards', TRUE),
('parking_pass', 'Parking permits and passes', TRUE);

-- Insert sample asset inventory
INSERT INTO asset_inventory (asset_tag, category_id, name, brand, model, serial_number, status, location, cost) VALUES
-- Laptops
('LAP001', 1, 'MacBook Pro 14"', 'Apple', 'M3 Pro', 'C02ABC123DEF', 'AVAILABLE', 'IT Storage', 2499.00),
('LAP002', 1, 'ThinkPad X1 Carbon', 'Lenovo', '11th Gen', 'PC0ABC123', 'AVAILABLE', 'IT Storage', 1899.00),
('LAP003', 1, 'Dell XPS 13', 'Dell', '2024', 'DELL456789', 'ALLOCATED', 'Employee Desk', 1699.00),
('LAP004', 1, 'Surface Laptop 5', 'Microsoft', '13.5"', 'MS789012', 'AVAILABLE', 'IT Storage', 1299.00),

-- Monitors
('MON001', 2, 'Dell UltraSharp 27"', 'Dell', 'U2723QE', 'DELL-MON-001', 'AVAILABLE', 'IT Storage', 599.00),
('MON002', 2, 'LG 4K Monitor 32"', 'LG', '32UN880', 'LG-MON-002', 'AVAILABLE', 'IT Storage', 799.00),
('MON003', 2, 'Samsung Curved 34"', 'Samsung', 'S34J550WQN', 'SAM-MON-003', 'ALLOCATED', 'Employee Desk', 449.00),

-- Keyboards & Mice
('KEY001', 3, 'Magic Keyboard', 'Apple', 'MK2A3', 'APPLE-KB-001', 'AVAILABLE', 'IT Storage', 179.00),
('KEY002', 3, 'Mechanical Keyboard', 'Logitech', 'MX Keys', 'LOG-KB-002', 'AVAILABLE', 'IT Storage', 119.00),
('MOU001', 4, 'Magic Mouse', 'Apple', 'MK2E3', 'APPLE-MS-001', 'AVAILABLE', 'IT Storage', 79.00),
('MOU002', 4, 'MX Master 3S', 'Logitech', 'MX Master', 'LOG-MS-002', 'AVAILABLE', 'IT Storage', 99.00),

-- Headsets
('HEAD001', 5, 'Noise Cancelling Headphones', 'Sony', 'WH-1000XM5', 'SONY-HP-001', 'AVAILABLE', 'IT Storage', 399.00),
('HEAD002', 5, 'Wireless Headset', 'Jabra', 'Evolve2 85', 'JAB-HS-002', 'AVAILABLE', 'IT Storage', 519.00),

-- Phones
('PHN001', 6, 'iPhone 15 Pro', 'Apple', '256GB', 'APPLE-PH-001', 'AVAILABLE', 'IT Storage', 1199.00),
('PHN002', 6, 'Desk Phone', 'Cisco', 'IP Phone 8851', 'CISCO-PH-002', 'ALLOCATED', 'Employee Desk', 289.00),

-- Access Cards
('ACC001', 9, 'Employee Access Card', 'HID', 'ProxCard II', 'HID-ACC-001', 'AVAILABLE', 'Security Office', 15.00),
('ACC002', 9, 'Employee Access Card', 'HID', 'ProxCard II', 'HID-ACC-002', 'AVAILABLE', 'Security Office', 15.00),
('ACC003', 9, 'Employee Access Card', 'HID', 'ProxCard II', 'HID-ACC-003', 'ALLOCATED', 'Employee', 15.00),

-- Parking Passes
('PARK001', 10, 'Monthly Parking Pass', 'Company', 'Level 1', 'PARK-001', 'AVAILABLE', 'Security Office', 150.00),
('PARK002', 10, 'Monthly Parking Pass', 'Company', 'Level 2', 'PARK-002', 'AVAILABLE', 'Security Office', 150.00);

-- Insert sample allocations
INSERT INTO asset_allocations (asset_id, employee_id, allocated_by, status, notes) VALUES
(3, 1, 'IT Admin', 'ALLOCATED', 'Standard laptop allocation for new employee'),
(7, 1, 'IT Admin', 'ALLOCATED', 'Monitor for workstation setup'),
(12, 2, 'IT Admin', 'ALLOCATED', 'Phone allocation for manager'),
(15, 1, 'Security Admin', 'ALLOCATED', 'Building access for new employee');

-- Create indexes for better performance
CREATE INDEX idx_asset_inventory_status ON asset_inventory(status);
CREATE INDEX idx_asset_inventory_category ON asset_inventory(category_id);
CREATE INDEX idx_asset_allocations_employee ON asset_allocations(employee_id);
CREATE INDEX idx_asset_allocations_status ON asset_allocations(status);
CREATE INDEX idx_asset_allocations_asset ON asset_allocations(asset_id);

-- Insert completion marker
INSERT INTO asset_categories (name, description) VALUES ('_INIT_COMPLETE_', 'Database initialization completed successfully');
