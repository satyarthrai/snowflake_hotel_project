--- CREATING DB---
create database HOTEL_DB;

--- CREATING FILE FORMAT---
create or replace file format FF_CSV
type='CSV'
field_optionally_enclosed_by='"'
skip_header=1
null_if=('null','NULL','');

--CREATING STAGE BEFORE LOADING--
CREATE OR REPLACE STAGE STG_HOTEL_BOOKINGS
FILE_FORMAT = (FORMAT_NAME = FF_CSV);

--CREATING BROZE TABLE--
CREATE TABLE BRONZE_HOTEL_BOOKING(
    booking_id STRING,
    hotel_id STRING,
    hotel_city STRING,
    customer_id STRING,
    customer_name STRING,
    customer_email STRING,
    check_in_date STRING,
    check_out_date STRING,
    room_type STRING,
    num_guests STRING,
    total_amount STRING,
    currency STRING,
    booking_status STRING
);

--COPYING DATA FROM STAGE TO BRONZE--
COPY INTO BRONZE_HOTEL_BOOKING
FROM @STG_HOTEL_BOOKINGS
FILE_FORMAT = (FORMAT_NAME = FF_CSV)
ON_ERROR = 'CONTINUE';

SELECT * FROM BRONZE_HOTEL_BOOKING LIMIT 5;

-- CREATE SILVER TABLE --

CREATE TABLE SILVER_HOTEL_BOOKINGS (
    booking_id VARCHAR,
    hotel_id VARCHAR,
    hotel_city VARCHAR,
    customer_id VARCHAR,
    customer_name VARCHAR,
    customer_email VARCHAR,
    check_in_date DATE,
    check_out_date DATE,
    room_type VARCHAR,
    num_guests INTEGER,
    total_amount FLOAT,
    currency VARCHAR,
    booking_status VARCHAR
);

---CHECKING ERRORS IN BROZE ---

--ERROS IN BRONZE--
SELECT customer_email
FROM BRONZE_HOTEL_BOOKING
WHERE NOT (customer_email LIKE '%@%.%')
    OR customer_email IS NULL

--NEGATIVE TOTAL AMOUNT--
SELECT total_amount
FROM BRONZE_HOTEL_BOOKING
WHERE TRY_TO_NUMBER(total_amount) < 0;

--ERROR WHEN CHECK OUT BEFORE CHECK IN --
SELECT check_in_date, check_out_date
FROM BRONZE_HOTEL_BOOKING
WHERE TRY_TO_DATE(check_out_date) < TRY_TO_DATE(check_in_date);

-- TYPES OF BOOKING--
SELECT DISTINCT booking_status
FROM BRONZE_HOTEL_BOOKING;

-- Iserting Cleaned data to Silver layer
INSERT INTO SILVER_HOTEL_BOOKINGS
SELECT
    booking_id,
    hotel_id,
    INITCAP(TRIM(hotel_city)) AS hotel_city,
    customer_id,
    INITCAP(TRIM(customer_name)) AS customer_name,
    CASE
        WHEN customer_email LIKE '%@%.%' THEN LOWER(TRIM(customer_email))
        ELSE NULL
    END AS customer_email,
    TRY_TO_DATE(NULLIF(check_in_date, '')) AS check_in_date,
    TRY_TO_DATE(NULLIF(check_out_date, '')) AS check_out_date,
    CASE
    WHEN LOWER(TRIM(room_type)) = 'null' THEN NULL
    ELSE room_type
    END AS room_type,
    num_guests,
    ABS(TRY_TO_NUMBER(total_amount)) AS total_amount,
    currency,
    CASE
        WHEN LOWER(booking_status) in ('confirmeeed', 'confirmd') THEN 'Confirmed'
        ELSE booking_status
    END AS booking_status
    FROM BRONZE_HOTEL_BOOKING
    WHERE
        TRY_TO_DATE(check_in_date) IS NOT NULL
        AND TRY_TO_DATE(check_out_date) IS NOT NULL
        AND TRY_TO_DATE(check_out_date) >= TRY_TO_DATE(check_in_date);

SELECT * FROM SILVER_HOTEL_BOOKINGS LIMIT 5;

-- CREATE GOLD TABLES -- 
CREATE TABLE GOLD_AGG_DAILY_BOOKING AS
SELECT
    check_in_date AS date,
    COUNT(*) AS total_booking,
    SUM(total_amount) AS total_revenue
FROM SILVER_HOTEL_BOOKINGS
GROUP BY check_in_date
ORDER BY date;

CREATE TABLE GOLD_AGG_HOTEL_CITY_SALES AS
SELECT
    hotel_city,
    SUM(total_amount) AS total_revenue
FROM SILVER_HOTEL_BOOKINGS
GROUP BY hotel_city
ORDER BY total_revenue DESC;

CREATE OR REPLACE TABLE GOLD_AGG_MONTHLY_BOOKING AS
SELECT
    DATE_TRUNC('MONTH', check_in_date) AS month,
    COUNT(*) AS total_booking,
    SUM(total_amount) AS total_revenue
FROM SILVER_HOTEL_BOOKINGS
GROUP BY 1
ORDER BY 1;

CREATE TABLE GOLD_BOOKING_CLEAN AS
SELECT
    booking_id,
    hotel_id,
    hotel_city,
    customer_id,
    customer_name,
    customer_email,
    check_in_date,
    check_out_date,
    room_type,
    num_guests,
    total_amount,
    currency,
    booking_status
FROM SILVER_HOTEL_BOOKINGS;

SELECT * FROM GOLD_AGG_DAILY_BOOKING LIMIT 30;

SELECT * FROM GOLD_AGG_HOTEL_CITY_SALES LIMIT 30;
