-- Formatting
CLEAR SCREEN;
SET SERVEROUTPUT ON
SET LINESIZE 140
SET PAGESIZE 50
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

-- Prompt user to input
ACCEPT input_year NUMBER PROMPT 'Enter the year (YYYY): '

-- Column Formatting
COLUMN sales_month FORMAT A15 Heading "Sales Month"
COLUMN product_category FORMAT A25 Heading "Product Category"
COLUMN total_orders FORMAT 99999 HEADING "Total Orders"
COLUMN sales_amount FORMAT 999999999.99 HEADING "Monthly Sales (USD)"
COLUMN pre_sales_amount FORMAT 999999999.99 HEADING "Previous Monthly Sales (USD)"
COLUMN growth FORMAT 99999.99 HEADING "Growth Rate (%)"
COLUMN sales_performance FORMAT A20 HEADING "Performance"

-- Title
TTITLE LEFT 'Generated On: ' _DATE -
       RIGHT 'Page: ' FORMAT 999 SQL.PNO SKIP 2 -
       CENTER 'Monthly Sales Growth Performance by Product Category' SKIP 1 -
       CENTER 'Year: &input_year' SKIP 1 -
       CENTER '========================================================' SKIP 2

-- Report View
WITH monthly_sales AS (
  SELECT 
    TO_CHAR(TO_DATE(EXTRACT(MONTH FROM dd.CalendarDate), 'MM'), 'MONTH') AS sales_month,
    dp.CategoryName AS product_category,
    SUM(sf.OrderTotalPrice) AS sales_amount,
    COUNT(sf.OrderID) AS total_orders
  FROM Sales_Fact sf
  JOIN Dim_Product dp ON sf.ProductKey = dp.ProductKey
  JOIN Dim_Date dd ON sf.DateKey = dd.DateKey
  WHERE EXTRACT(YEAR FROM dd.CalendarDate) = &input_year
  GROUP BY EXTRACT(MONTH FROM dd.CalendarDate), dp.CategoryName
),
previous_month_sales AS (
  SELECT 
    TO_CHAR(TO_DATE(EXTRACT(MONTH FROM dd.CalendarDate), 'MM'), 'MONTH') AS sales_month,
    dp.CategoryName AS product_category,
    SUM(sf.OrderTotalPrice) AS pre_sales_amount
  FROM Sales_Fact sf
  JOIN Dim_Product dp ON sf.ProductKey = dp.ProductKey
  JOIN Dim_Date dd ON sf.DateKey = dd.DateKey
  WHERE EXTRACT(YEAR FROM dd.CalendarDate) = &input_year - 1
  GROUP BY EXTRACT(MONTH FROM dd.CalendarDate), dp.CategoryName
)
-- Generate Report
SELECT 
  ms.sales_month,
  ms.product_category,
  ms.total_orders,
  NVL(ms.sales_amount, 0) AS sales_amount,
  NVL(pms.pre_sales_amount, 0) AS pre_sales_amount,
  ROUND(COALESCE((ms.sales_amount - pms.pre_sales_amount) / pms.pre_sales_amount * 100, 0), 2) AS growth,
  CASE
    WHEN COALESCE((ms.sales_amount - pms.pre_sales_amount) / pms.pre_sales_amount * 100, 0) > 0 THEN 'Improved Performance'
    WHEN COALESCE((ms.sales_amount - pms.pre_sales_amount) / pms.pre_sales_amount * 100, 0) = 0 THEN 'Constant Performance'
    WHEN COALESCE((ms.sales_amount - pms.pre_sales_amount) / pms.pre_sales_amount * 100, 0) < 0 THEN 'Reduced Performance'
  END AS sales_performance
FROM monthly_sales ms
LEFT JOIN previous_month_sales pms ON ms.sales_month = pms.sales_month AND ms.product_category = pms.product_category
ORDER BY TO_DATE(ms.sales_month, 'MONTH');

-- Clear formatting
CLEAR COLUMNS
CLEAR BREAKS
CLEAR COMPUTES
TTITLE OFF
