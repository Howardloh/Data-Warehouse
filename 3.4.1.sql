-- Formatting
CLEAR SCREEN;
SET SERVEROUTPUT ON
SET LINESIZE 150
SET PAGESIZE 50
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

-- Prompt user to input
ACCEPT input_year DATE FORMAT 'YYYY' PROMPT 'Enter the year (YYYY): '

-- Column Formatting
COLUMN customer_name FORMAT A30 HEADING "Customer Name"
COLUMN country FORMAT A15 HEADING "Country"
COLUMN churn_status FORMAT A12 HEADING "Churn Status"
COLUMN total_orders FORMAT 99999 HEADING "Total Orders"
COLUMN total_spent FORMAT 999999999.99 HEADING "Total Spent (USD)"
COLUMN avg_order_value FORMAT 999999999.99 HEADING "Avg Order Value (USD)"
COLUMN first_order_date FORMAT A16 HEADING "First Order Date"
COLUMN last_order_date FORMAT A15 HEADING "Last Order Date"

-- Title
TTITLE LEFT 'Generated On: ' _DATE -
       RIGHT 'Page: ' FORMAT 999 SQL.PNO SKIP 2 -
       CENTER 'Customer Churn and Retention Analysis Report' SKIP 1 -
       CENTER 'Year: &input_year' SKIP 1 -
       CENTER '======================================================================' SKIP 2

-- Generate Report
SELECT
  c.customer_name,
  c.country,
  CASE
    WHEN p.customer_key IS NULL THEN 'Churned'
    ELSE 'Retained'
  END AS churn_status,
  c.total_orders,
  c.total_spent,
  ROUND(c.total_spent / c.total_orders, 2) AS avg_order_value,
  TO_CHAR(c.first_order_date, 'DD/MM/YYYY') AS first_order_date,
  TO_CHAR(c.last_order_date, 'DD/MM/YYYY') AS last_order_date
FROM (
  SELECT 
    sf.CustomerKey AS customer_key,
    dc.CompanyName AS customer_name,
    dc.Country AS country,
    COUNT(sf.OrderID) AS total_orders,
    SUM(sf.OrderTotalPrice) AS total_spent,
    MIN(dd.CalendarDate) AS first_order_date,
    MAX(dd.CalendarDate) AS last_order_date
  FROM Sales_Fact sf
  JOIN Dim_Customer dc ON sf.CustomerKey = dc.CustomerKey
  JOIN Dim_Date dd ON sf.DateKey = dd.DateKey
  WHERE EXTRACT(YEAR FROM dd.CalendarDate) = &input_year
  GROUP BY sf.CustomerKey, dc.CompanyName, dc.Country
) c
LEFT JOIN (
  SELECT DISTINCT 
    sf.CustomerKey AS customer_key
  FROM Sales_Fact sf
  JOIN Dim_Date dd ON sf.DateKey = dd.DateKey
  WHERE EXTRACT(YEAR FROM dd.CalendarDate) = &input_year - 1
) p ON c.customer_key = p.customer_key
ORDER BY churn_status, c.total_spent DESC;

-- Clear formatting
CLEAR COLUMNS
CLEAR BREAKS
CLEAR COMPUTES
TTITLE OFF
