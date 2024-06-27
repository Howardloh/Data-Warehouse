-- Formatting
CLEAR SCREEN;
SET SERVEROUTPUT ON
SET LINESIZE 140
SET PAGESIZE 50
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

-- Prompt user to input
ACCEPT input_year DATE FORMAT 'YYYY' PROMPT 'Enter the year (YYYY): '

-- Column Formatting
COLUMN rank FORMAT 999 HEADING "Customer's Ranking"
COLUMN customer_name FORMAT A35 HEADING "Customer Name"
COLUMN country FORMAT A20 HEADING "Country"
COLUMN total_revenue FORMAT 999999999.99 HEADING "Total Revenue (USD)"
COLUMN previous_year_revenue FORMAT 999999999.99 HEADING "Previous Year Revenue (USD)"
COLUMN growth FORMAT 99999.99 HEADING "Growth Rate (%)"

-- Title
TTITLE LEFT 'Generated On: ' _DATE -
       RIGHT 'Page: ' FORMAT 999 SQL.PNO SKIP 2 -
       CENTER 'Top 15 Revenue-Generating Customers Analysis Report' SKIP 1 -
       CENTER 'Year: &input_year' SKIP 1 -
       CENTER '==============================================================' SKIP 2 -

-- Report View
CREATE OR REPLACE VIEW top_customers_revenue AS
WITH current_year_sales AS (
  SELECT 
    dc.CompanyName AS customer_name,
    dc.Country AS country,
    SUM(sf.UnitPrice * sf.Quantity) AS total_revenue
  FROM Sales_Fact sf
  JOIN Dim_Customer dc ON sf.CustomerKey = dc.CustomerKey
  JOIN Dim_Date dd ON sf.DateKey = dd.DateKey
  WHERE EXTRACT(YEAR FROM dd.CalendarDate) = &input_year
  GROUP BY dc.CompanyName, dc.Country
),
previous_year_sales AS (
  SELECT 
    dc.CompanyName AS customer_name,
    SUM(sf.UnitPrice * sf.Quantity) AS previous_year_revenue
  FROM Sales_Fact sf
  JOIN Dim_Customer dc ON sf.CustomerKey = dc.CustomerKey
  JOIN Dim_Date dd ON sf.DateKey = dd.DateKey
  WHERE EXTRACT(YEAR FROM dd.CalendarDate) = &input_year - 1
  GROUP BY dc.CompanyName
)
SELECT
  cys.customer_name,
  cys.country,
  NVL(cys.total_revenue, 0) AS total_revenue,
  NVL(pys.previous_year_revenue, 0) AS previous_year_revenue,
  ROUND(COALESCE((cys.total_revenue - pys.previous_year_revenue) / pys.previous_year_revenue * 100, 0), 2) AS growth
FROM current_year_sales cys
LEFT JOIN previous_year_sales pys
  ON cys.customer_name = pys.customer_name;

-- Query to get the top 15 customers by revenue
SELECT
    ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS rank,
    customer_name,
    country,
    total_revenue,
    previous_year_revenue,
    growth
FROM (
  SELECT
    customer_name,
    country,
    total_revenue,
    previous_year_revenue,
    growth
  FROM top_customers_revenue
  ORDER BY total_revenue DESC
)
WHERE ROWNUM <= 15;

-- Clear formatting
CLEAR COLUMNS
CLEAR BREAKS
CLEAR COMPUTES
TTITLE OFF
