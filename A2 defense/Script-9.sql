CREATE SCHEMA IF NOT EXISTS restaurant_managment;

CREATE TABLE IF NOT EXISTS restaurant_managment.categories (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE IF NOT EXISTS restaurant_managment.customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(100) UNIQUE
);

CREATE TABLE IF NOT EXISTS restaurant_managment.employees (
    employee_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    ROLE VARCHAR(50)
                     CHECK (ROLE IN ('Waiter', 'Chef', 'Manager', 'Cashier', 'Host')),
    
    iin CHAR(12) UNIQUE,
                     
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS restaurant_managment.tables (
    table_id SERIAL PRIMARY KEY,
    table_number INT NOT NULL UNIQUE,
    capacity INT NOT NULL CHECK (capacity > 0)
);

CREATE TABLE IF NOT EXISTS restaurant_managment.menu_items (
    menu_item_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),

    category_id INT NOT NULL,
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_menu_items_category FOREIGN KEY (category_id)
        REFERENCES restaurant_managment.categories(category_id)
);

CREATE TABLE IF NOT EXISTS restaurant_managment.orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    employee_id INT NOT NULL,

    order_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                      CHECK (order_time > '2026-01-01 00:00:00'),
    order_status VARCHAR(50) DEFAULT 'open'
                      CHECK (order_status IN ('open', 'served', 'paid', 'cancelled')),
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES restaurant_managment.customers(customer_id),
    CONSTRAINT fk_orders_employee FOREIGN KEY (employee_id) REFERENCES restaurant_managment.employees(employee_id)
);

CREATE TABLE IF NOT EXISTS restaurant_managment.reservations (
    reservation_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    table_id INT NOT NULL,
    reservation_time TIMESTAMP NOT NULL
                          CHECK (reservation_time > '2026-01-01 00:00:00'),
    notes TEXT,
    CONSTRAINT fk_reservations_customer FOREIGN KEY (customer_id) REFERENCES restaurant_managment.customers(customer_id),
    CONSTRAINT fk_reservations_table FOREIGN KEY (table_id) REFERENCES restaurant_managment.tables(table_id)
);

CREATE TABLE IF NOT EXISTS restaurant_managment.order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    menu_item_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
  
    total_price DECIMAL(10, 2) GENERATED ALWAYS AS (quantity * price) STORED,
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES restaurant_managment.orders(order_id),
    CONSTRAINT fk_order_items_menu_item FOREIGN KEY (menu_item_id) REFERENCES restaurant_managment.menu_items(menu_item_id)
);

CREATE TABLE IF NOT EXISTS restaurant_managment.payments (
    payment_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL CHECK (amount >= 0),
    payment_method VARCHAR(50) NOT NULL DEFAULT 'cash'
                        CHECK (payment_method IN ('cash', 'card', 'online', 'crypto')),
    payment_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES restaurant_managment.orders(order_id)
    );
);

INSERT INTO restaurant_managment.categories (name, description)
VALUES 
('Main Course', 'Main dishes'),
('Drinks', 'Beverages'),
('Dessert', 'Sweet items');

);
-- Set default order status
ALTER TABLE restaurant_managment.orders
ALTER COLUMN order_status SET DEFAULT 'open';

-- Ensure one payment per order 
ALTER TABLE restaurant_managment.payments
ADD CONSTRAINT unique_order_payment UNIQUE (order_id);

-- Make employee role NOT NULL
ALTER TABLE restaurant_managment.employees
ALTER COLUMN role SET NOT NULL;

-- Add default for reservation notes
ALTER TABLE restaurant_managment.reservations
ALTER COLUMN notes SET DEFAULT 'No notes';

-- Enforce email format basic check
ALTER TABLE restaurant_managment.customers
ADD CONSTRAINT chk_email_format CHECK (email LIKE '%@%');
);
TRUNCATE TABLE 
restaurant_managment.order_items,
restaurant_managment.payments,
restaurant_managment.orders,
restaurant_managment.menu_items,
restaurant_managment.categories,
restaurant_managment.reservations,
restaurant_managment.tables,
restaurant_managment.customers,
restaurant_managment.employees
CASCADE;
);

