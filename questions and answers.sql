USE event_ticket_db;
-- Basic Quiers

-- Display events with available tickets greater than zero.
SELECT *
FROM events
WHERE available_tickets > 0;

-- Find events where the ticket price is greater than ₹500.
SELECT event_name, ticket_price
FROM events
WHERE ticket_price > 500;
-- Display confirmed bookings only.
SELECT *
FROM bookings
WHERE booking_status = 'CONFIRMED';
-- Display cancelled bookings only.
SELECT *
FROM bookings
WHERE booking_status = 'CANCELLED';


-- Aggregate functions and GROUP BY

-- Count the total number of customers.
SELECT COUNT(*) AS total_customers
FROM customers;
-- Calculate the total revenue from confirmed bookings.
SELECT SUM(total_amount) AS total_revenue
FROM bookings
WHERE booking_status = 'CONFIRMED';
-- Find the total tickets booked for each event.
SELECT
    e.event_name,
    COALESCE(SUM(
        CASE
            WHEN b.booking_status = 'CONFIRMED'
            THEN b.tickets_booked
            ELSE 0
        END
    ), 0) AS total_booked
FROM events e
LEFT JOIN bookings b ON e.event_id = b.event_id
GROUP BY e.event_id, e.event_name;
-- Find events with ticket prices between ₹500 and ₹1500.
SELECT event_name, ticket_price
FROM events
WHERE ticket_price BETWEEN 500 AND 1500;

-- JOIN queries

-- Display customer names with their bookings.
SELECT
    c.customer_name,
    b.booking_id,
    b.tickets_booked,
    b.total_amount,
    b.booking_status
FROM customers c
INNER JOIN bookings b
    ON c.customer_id = b.customer_id;
-- Display event names with customer names.
SELECT
    c.customer_name,
    e.event_name,
    b.tickets_booked
FROM bookings b
INNER JOIN customers c
    ON b.customer_id = c.customer_id
INNER JOIN events e
    ON b.event_id = e.event_id;
-- Display booking details along with payment information.
SELECT
    b.booking_id,
    c.customer_name,
    e.event_name,
    p.payment_method,
    p.payment_amount,
    p.payment_status
FROM bookings b
JOIN customers c ON b.customer_id = c.customer_id
JOIN events e ON b.event_id = e.event_id
LEFT JOIN payments p ON b.booking_id = p.booking_id;

-- Subqueries
-- Find events priced above the average ticket price.
SELECT event_name, ticket_price
FROM events
WHERE ticket_price > (
    SELECT AVG(ticket_price)
    FROM events
);
-- Find customers who have made bookings.
SELECT customer_name
FROM customers
WHERE customer_id IN (
    SELECT customer_id
    FROM bookings
);
-- Find customers who have never booked tickets.
SELECT c.customer_id, c.customer_name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM bookings b
    WHERE b.customer_id = c.customer_id
);

-- UPDATE and DELETE
-- Cancel booking number 1.
UPDATE bookings
SET booking_status = 'CANCELLED'
WHERE booking_id = 1;
-- Change a customer's phone number.
UPDATE customers
SET phone = '9123456780'
WHERE customer_id = 1;
-- Display the updated ticket availability.
SELECT event_name, total_tickets, available_tickets
FROM events;

-- Views, triggers and stored procedures.
-- Display the booking details view.
SELECT * FROM booking_details;
-- Display all triggers.
SHOW TRIGGERS FROM event_ticket_db;
-- Display stored procedures.
SHOW PROCEDURE STATUS
WHERE Db = 'event_ticket_db';
-- Get bookings for customer ID 1.
CALL GetCustomerBookings(1);
-- Book one ticket for customer 1 and event 1.
CALL BookTickets(1, 1, 1);
