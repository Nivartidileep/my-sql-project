DROP DATABASE IF EXISTS event_ticket_db;
CREATE DATABASE event_ticket_db;
USE event_ticket_db;


USE event_ticket_db;

CREATE TABLE events (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    event_name VARCHAR(100) NOT NULL,
    event_date DATE NOT NULL,
    venue VARCHAR(100),
    ticket_price DECIMAL(10,2) NOT NULL,
    total_tickets INT NOT NULL,
    available_tickets INT NOT NULL,
    CHECK (ticket_price >= 0),
    CHECK (total_tickets >= 0),
    CHECK (
        available_tickets >= 0
        AND available_tickets <= total_tickets
    )
) ENGINE=InnoDB;

INSERT INTO events (event_name, event_date, venue, ticket_price, total_tickets, available_tickets) VALUES
('Python Workshop', '2026-11-15', 'Vizag Tech Hall', 500.00, 100, 100),
('Music Concert',   '2026-11-20', 'Beach Arena', 1200.00, 200, 200),
('College Fest',    '2026-11-25', 'College Ground', 300.00, 150, 150),
('AI Conference',   '2026-12-05', 'City Convention Center', 800.00, 120, 120),
('Dance Show',      '2026-12-10', 'Open Air Theatre', 400.00, 80, 80);


-- 2. CUSTOMERS
CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(15)
) ENGINE=InnoDB;


INSERT INTO customers (customer_name, email, phone) VALUES
('dileep',   'dileep@gmail.com',   '9658125634'),
('lokesh',   'lokesh@gmail.com',   '9182645536'),
('dhavan',   'dhavan@gmail.com',   '9876543210'),
('druvan',   'druvan@gmail.com',   '6548923017'),
('rambabu',  'rambabu@gmail.com',  '6301542895');

SHOW TABLES;


-- 3. BOOKINGS
USE event_ticket_db;

CREATE TABLE bookings (
    booking_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    event_id INT NOT NULL,
    tickets_booked INT NOT NULL,
    booking_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    booking_status ENUM('CONFIRMED', 'CANCELLED')
        NOT NULL DEFAULT 'CONFIRMED',
    total_amount DECIMAL(10,2) NOT NULL,

    CONSTRAINT chk_tickets_booked
        CHECK (tickets_booked > 0),

    CONSTRAINT chk_total_amount
        CHECK (total_amount >= 0),

    CONSTRAINT fk_bookings_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),

    CONSTRAINT fk_bookings_event
        FOREIGN KEY (event_id)
        REFERENCES events(event_id),

    INDEX idx_booking_date (booking_date)
) ENGINE=InnoDB;


-- 4. PAYMENTS
USE event_ticket_db;

CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL,
    payment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payment_method ENUM(
        'UPI',
        'CARD',
        'CASH',
        'NET_BANKING'
    ) NOT NULL,
    payment_amount DECIMAL(10,2) NOT NULL,
    payment_status ENUM(
        'PENDING',
        'PAID',
        'FAILED',
        'REFUNDED'
    ) NOT NULL DEFAULT 'PENDING',

    CONSTRAINT chk_payment_amount
        CHECK (payment_amount >= 0),

    CONSTRAINT fk_payments_booking
        FOREIGN KEY (booking_id)
        REFERENCES bookings(booking_id)
) ENGINE=InnoDB;




-- 5. TRIGGERS
USE event_ticket_db;

DELIMITER $$

-- Trigger 1: Validate booking before insert
CREATE TRIGGER before_booking_insert
BEFORE INSERT ON bookings
FOR EACH ROW
BEGIN
    DECLARE v_available INT DEFAULT NULL;

    IF NEW.tickets_booked IS NULL OR NEW.tickets_booked <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tickets must be greater than zero';
    END IF;

    SELECT available_tickets
    INTO v_available
    FROM events
    WHERE event_id = NEW.event_id;

    IF v_available IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Event not found';
    END IF;

    IF NEW.booking_status = 'CONFIRMED'
       AND NEW.tickets_booked > v_available THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Not enough tickets available';
    END IF;
END$$



-- Trigger 2: Update ticket availability after insert
CREATE TRIGGER after_booking_insert
AFTER INSERT ON bookings
FOR EACH ROW
BEGIN
    IF NEW.booking_status = 'CONFIRMED' THEN
        UPDATE events
        SET available_tickets = available_tickets - NEW.tickets_booked
        WHERE event_id = NEW.event_id;
    END IF;
END$$

-- Trigger 3: Update availability when booking status changes
CREATE TRIGGER after_booking_update
BEFORE UPDATE ON bookings
FOR EACH ROW
BEGIN
    DECLARE v_available INT DEFAULT NULL;

    IF OLD.booking_status = 'CONFIRMED'
       AND NEW.booking_status = 'CANCELLED' THEN

        UPDATE events
        SET available_tickets = available_tickets + OLD.tickets_booked
        WHERE event_id = OLD.event_id;

    ELSEIF OLD.booking_status = 'CANCELLED'
       AND NEW.booking_status = 'CONFIRMED' THEN

        SELECT available_tickets
        INTO v_available
        FROM events
        WHERE event_id = NEW.event_id;

        IF v_available IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Event not found';
        END IF;

        IF NEW.tickets_booked > v_available THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Not enough tickets available';
        END IF;

        UPDATE events
        SET available_tickets = available_tickets - NEW.tickets_booked
        WHERE event_id = NEW.event_id;
    END IF;
END$$

DELIMITER ;

-- Check your customer and event IDs first
USE event_ticket_db;

SELECT * FROM customers;
SELECT event_id, event_name, available_tickets
FROM events;

SHOW TRIGGERS FROM event_ticket_db;
-- 6. SAMPLE BOOKINGS
INSERT INTO bookings
    (customer_id, event_id, tickets_booked, total_amount)
VALUES
    (1, 1, 2, 1000.00),
    (2, 2, 1, 1200.00),
    (3, 3, 3, 900.00),
    (4, 4, 2, 1600.00),
    (5, 1, 1, 500.00),
    (1, 5, 2, 800.00);


-- 7. SAMPLE PAYMENTS
INSERT INTO payments
    (booking_id, payment_method, payment_amount, payment_status)
VALUES
    (1, 'UPI', 1000.00, 'PAID'),
    (2, 'CARD', 1200.00, 'PAID'),
    (3, 'CASH', 900.00, 'PENDING'),
    (4, 'UPI', 1600.00, 'PAID'),
    (5, 'CARD', 500.00, 'PAID'),
    (6, 'UPI', 800.00, 'PENDING');
    
    -- 8. VIEW
CREATE VIEW booking_details AS
SELECT
    b.booking_id,
    c.customer_name,
    e.event_name,
    b.tickets_booked,
    b.total_amount,
    b.booking_status,
    b.booking_date
FROM bookings AS b
JOIN customers AS c ON c.customer_id = b.customer_id
JOIN events AS e ON e.event_id = b.event_id;


-- 8. VIEW
USE event_ticket_db;

CREATE OR REPLACE VIEW booking_details AS
SELECT
    b.booking_id,
    c.customer_name,
    e.event_name,
    b.tickets_booked,
    b.total_amount,
    b.booking_status,
    b.booking_date
FROM bookings AS b
INNER JOIN customers AS c
    ON c.customer_id = b.customer_id
INNER JOIN events AS e
    ON e.event_id = b.event_id;

SELECT * FROM booking_details;



USE event_ticket_db;
-- 9. STORED PROCEDURES

DROP PROCEDURE IF EXISTS GetCustomerBookings;
DROP PROCEDURE IF EXISTS BookTickets;


USE event_ticket_db;

DELIMITER $$

CREATE PROCEDURE GetCustomerBookings(
    IN p_customer_id INT
)
BEGIN
    SELECT *
    FROM booking_details
    WHERE booking_id IN (
        SELECT booking_id
        FROM bookings
        WHERE customer_id = p_customer_id
    );
END$$

DELIMITER ;


USE event_ticket_db;

DELIMITER $$

CREATE PROCEDURE BookTickets(
    IN p_customer_id INT,
    IN p_event_id INT,
    IN p_tickets INT
)
BEGIN
    DECLARE v_price DECIMAL(10,2) DEFAULT NULL;
    DECLARE v_available INT DEFAULT NULL;
    DECLARE v_total DECIMAL(10,2);
    DECLARE v_booking_id INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_tickets IS NULL OR p_tickets <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tickets must be greater than zero';
    END IF;

    START TRANSACTION;

    SELECT ticket_price, available_tickets
    INTO v_price, v_available
    FROM events
    WHERE event_id = p_event_id
    FOR UPDATE;

    IF v_price IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Event not found';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM customers
        WHERE customer_id = p_customer_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Customer not found';
    END IF;

    IF p_tickets > v_available THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Not enough tickets available';
    END IF;

    SET v_total = v_price * p_tickets;

    INSERT INTO bookings (
        customer_id,
        event_id,
        tickets_booked,
        booking_status,
        total_amount
    )
    VALUES (
        p_customer_id,
        p_event_id,
        p_tickets,
        'CONFIRMED',
        v_total
    );

    SET v_booking_id = LAST_INSERT_ID();

    COMMIT;

    SELECT
        'Booking successful' AS message,
        v_booking_id AS booking_id,
        v_total AS total_amount;
END$$

DELIMITER ;

SELECT event_id, event_name, available_tickets
FROM events;

CALL BookTickets(1, 1, 1);


-- 1. Check events and ticket availability
SELECT * FROM events;

-- 2. Check customers
SELECT * FROM customers;

-- 3. Check bookings
SELECT * FROM bookings;

-- 4. Check payments
SELECT * FROM payments;

-- 5. Check the booking details view
SELECT * FROM booking_details;

-- 6. Check both stored procedures
SHOW PROCEDURE STATUS
WHERE Db = 'event_ticket_db';


SELECT
    e.event_name,
    e.total_tickets,
    e.available_tickets,
    COALESCE(
        SUM(
            CASE
                WHEN b.booking_status = 'CONFIRMED'
                THEN b.tickets_booked
                ELSE 0
            END
        ),
        0
    ) AS confirmed_tickets
FROM events e
LEFT JOIN bookings b
    ON e.event_id = b.event_id
GROUP BY
    e.event_id,
    e.event_name,
    e.total_tickets,
    e.available_tickets
ORDER BY e.event_id;

USE event_ticket_db;

SELECT * FROM events;

SELECT * FROM customers;

SELECT * FROM bookings;

SELECT * FROM payments;

SELECT * FROM booking_details;
SHOW TABLES;





