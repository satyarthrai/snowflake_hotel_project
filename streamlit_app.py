import streamlit as st
import pandas as pd
from snowflake.snowpark.context import get_active_session

# -----------------------------------
# SNOWFLAKE SESSION
# -----------------------------------
session = get_active_session()

# -----------------------------------
# PAGE CONFIG
# -----------------------------------
st.set_page_config(
    page_title="Hotel Booking Dashboard",
    layout="wide"
)

# -----------------------------------
# TITLE
# -----------------------------------
st.title("🏨 Hotel Booking Analytics Dashboard")

st.markdown("Built using Snowflake + Streamlit")

# -----------------------------------
# QUERY FUNCTION
# -----------------------------------
def run_query(query):
    return session.sql(query).to_pandas()

# -----------------------------------
# LOAD KPI DATA
# -----------------------------------
avg_booking = run_query("""
SELECT AVG(total_amount) AS avg_booking_value
FROM GOLD_BOOKING_CLEAN
""")

total_guests = run_query("""
SELECT SUM(num_guests) AS total_guests
FROM GOLD_BOOKING_CLEAN
""")

total_bookings = run_query("""
SELECT COUNT(*) AS total_bookings
FROM GOLD_BOOKING_CLEAN
""")

total_revenue = run_query("""
SELECT SUM(total_amount) AS total_revenue
FROM GOLD_BOOKING_CLEAN 
""")

# -----------------------------------
# KPI SECTION
# -----------------------------------
st.subheader("📌 Key Metrics")

col1, col2, col3, col4 = st.columns(4)

col1.metric(
    "Total Revenue",
    f"${total_revenue.iloc[0,0]:,.2f}"
)

col2.metric(
    "Total Bookings",
    f"{int(total_bookings.iloc[0,0]):,}"
)

col3.metric(
    "Avg Booking Value",
    f"${avg_booking.iloc[0,0]:,.2f}"
)

col4.metric(
    "Total Guests",
    f"{int(total_guests.iloc[0,0]):,}"
)

# -----------------------------------
# REVENUE TREND
# -----------------------------------
revenue_df = run_query("""
SELECT
    month,
    total_revenue
FROM GOLD_AGG_MONTHLY_BOOKING
ORDER BY month
""")

st.subheader("📈 Monthly Revenue Trend")

st.line_chart(
    revenue_df,
    x="MONTH",
    y="TOTAL_REVENUE",
    use_container_width=True
)

# -----------------------------------
# BOOKING TREND
# -----------------------------------
booking_df = run_query("""
SELECT
    month,
    total_booking
FROM GOLD_AGG_MONTHLY_BOOKING
ORDER BY month
""")

st.subheader("📊 Monthly Booking Trend")

st.line_chart(
    booking_df,
    x="MONTH",
    y="TOTAL_BOOKING",
    use_container_width=True
)

# -----------------------------------
# TOP CITIES BY REVENUE
# -----------------------------------
city_df = run_query("""
SELECT
    hotel_city,
    total_revenue
FROM GOLD_AGG_HOTEL_CITY_SALES
WHERE total_revenue IS NOT NULL
ORDER BY total_revenue DESC
LIMIT 5
""")

st.subheader("🏙️ Top Cities by Revenue")

st.bar_chart(
    city_df,
    x="HOTEL_CITY",
    y="TOTAL_REVENUE",
    use_container_width=True
)

# -----------------------------------
# BOOKING STATUS
# -----------------------------------
status_df = run_query("""
SELECT
    booking_status,
    COUNT(*) AS total
FROM GOLD_BOOKING_CLEAN
GROUP BY booking_status
""")

st.subheader("📋 Booking Status Distribution")

st.bar_chart(
    status_df,
    x="BOOKING_STATUS",
    y="TOTAL",
    use_container_width=True
)

# -----------------------------------
# ROOM TYPE DISTRIBUTION
# -----------------------------------
room_df = run_query("""
SELECT
    room_type,
    COUNT(*) AS total_bookings
FROM GOLD_BOOKING_CLEAN
WHERE room_type IS NOT NULL
GROUP BY room_type
ORDER BY total_bookings DESC
""")

st.subheader("🛏️ Room Type Distribution")

st.bar_chart(
    room_df,
    x="ROOM_TYPE",
    y="TOTAL_BOOKINGS",
    use_container_width=True
)

# -----------------------------------
# RAW DATA TABLE
# -----------------------------------
st.subheader("📄 Booking Data")

booking_clean_df = run_query("""
SELECT *
FROM GOLD_BOOKING_CLEAN
LIMIT 100
""")

st.dataframe(
    booking_clean_df,
    use_container_width=True
)
