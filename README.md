# Hotel Booking Analytics Pipeline

End-to-end Snowflake Data Engineering project using Bronze, Silver, and Gold architecture with a Streamlit analytics dashboard.

## Tech Stack

- Snowflake
- SQL
- Streamlit
- Snowpark
- Pandas

## Architecture

### Bronze Layer
Raw hotel booking data ingestion.

### Silver Layer
Data cleaning and transformation:
- email validation
- date validation
- null handling
- typo correction
- standardization

### Gold Layer
Business-ready analytics tables:
- monthly revenue
- booking trends
- city sales
- booking status analysis

## Dashboard Features

- KPI cards
- Monthly revenue trend
- Monthly booking trend
- Top cities by revenue
- Booking status distribution
- Room type analysis

## Project Structure

```text
hotel-booking-analytics/
│
├── hotel_pipeline.sql
├── streamlit_app.py
├── requirements.txt
└── README.md
