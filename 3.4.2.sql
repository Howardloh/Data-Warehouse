-- Formatting
CLEAR SCREEN;
SET SERVEROUTPUT ON
SET LINESIZE 165
SET PAGESIZE 50
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

-- Prompt user to input
ACCEPT input_year NUMBER PROMPT 'Enter the year (YYYY): '

-- Column Formatting
COLUMN spending_segment FORMAT A20 HEADING "Spending Segment"
COLUMN num_customers FORMAT 99999 HEADING "No. of Customers"
COLUMN avg_spent_per_segment FORMAT 999999999.99 HEADING "Avg Spent Per Segment (USD)"
COLUMN total_spent FORMAT 999999999.99 HEADING "Total Spent (USD)"
COLUMN min_spent FORMAT 999999999.99 HEADING "Min Spent (USD)"
COLUMN max_spent FORMAT 999999999.99 HEADING "Max Spent (USD)"
COLUMN avg_orders_per_customer FORMAT 99999.99 HEADING "Avg Orders Per Customer"
COLUMN median_spent FORMAT 999999999.99 HEADING "Median Spent (USD)"

-- Title
TTITLE LEFT 'Generated On: ' _DATE -
       RIGHT 'Page: ' FORMAT 999 SQL.PNO SKIP 2 -
       CENTER 'Customer Segmentation and Spending Analysis Report' SKIP 1 -
       CENTER 'Year: &input_year' SKIP 1 -
       CENTER '=========================================================' SKIP 2

-- Generate Report
WITH customer_spending AS (
  SELECT 
    sf.CustomerKey,
    dc.CompanyName AS customer_name,
    SUM(sf.OrderTotalPrice) AS total_spent,
    COUNT(sf.OrderID) AS num_orders
  FROM Sales_Fact sf
  JOIN Dim_Customer dc ON sf.CustomerKey = dc.CustomerKey
  JOIN Dim_Date dd ON sf.DateKey = dd.DateKey
  WHERE EXTRACT(YEAR FROM dd.CalendarDate) = &input_year
  GROUP BY sf.CustomerKey, dc.CompanyName
),
-- High-value customers: top 10%
high_value AS (
  SELECT 
    CustomerKey,
    customer_name,
    total_spent,
    num_orders,
    'High-value' AS spending_segment
  FROM (
    SELECT 
      CustomerKey,
      customer_name,
      total_spent,
      num_orders,
      NTILE(10) OVER (ORDER BY total_spent DESC) AS decile
    FROM customer_spending
  ) WHERE decile = 1
),
-- Mid-value customers: next 40%
mid_value AS (
  SELECT 
    CustomerKey,
    customer_name,
    total_spent,
    num_orders,
    'Mid-value' AS spending_segment
  FROM (
    SELECT 
      CustomerKey,
      customer_name,
      total_spent,
      num_orders,
      NTILE(5) OVER (ORDER BY total_spent DESC) AS quintile
    FROM customer_spending
  ) WHERE quintile BETWEEN 2 AND 5
),
-- Low-value customers: bottom 50%
low_value AS (
  SELECT 
    CustomerKey,
    customer_name,
    total_spent,
    num_orders,
    'Low-value' AS spending_segment
  FROM (
    SELECT 
      CustomerKey,
      customer_name,
      total_spent,
      num_orders,
      NTILE(2) OVER (ORDER BY total_spent DESC) AS half
    FROM customer_spending
  ) WHERE half = 2
),
-- Combine all segments
combined AS (
  SELECT * FROM high_value
  UNION ALL
  SELECT * FROM mid_value
  UNION ALL
  SELECT * FROM low_value
)
SELECT
  spending_segment,
  COUNT(CustomerKey) AS num_customers,
  ROUND(AVG(total_spent), 2) AS avg_spent_per_segment,
  ROUND(SUM(total_spent), 2) AS total_spent,
  ROUND(MIN(total_spent), 2) AS min_spent,
  ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_spent), 2) AS median_spent,
  ROUND(MAX(total_spent), 2) AS max_spent,
  ROUND(AVG(num_orders), 2) AS avg_orders_per_customer
FROM combined
GROUP BY spending_segment
ORDER BY total_spent DESC;

-- Clear formatting
CLEAR COLUMNS
CLEAR BREAKS
CLEAR COMPUTES
TTITLE OFF
