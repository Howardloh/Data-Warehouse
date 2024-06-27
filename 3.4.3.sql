-- Formatting
CLEAR SCREEN;
SET SERVEROUTPUT ON
SET LINESIZE 170
SET PAGESIZE 50
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

-- Prompt user to input
ACCEPT input_year NUMBER PROMPT 'Enter the year (YYYY): '

-- Column Formatting
COLUMN supplier_name FORMAT A40 HEADING "Supplier Name"
COLUMN product_name FORMAT A35 HEADING "Product Name"
COLUMN total_orders FORMAT 99999 HEADING "Total Orders"
COLUMN total_revenue FORMAT 999999999.99 HEADING "Total Revenue (USD)"
COLUMN total_discount FORMAT 999999999.99 HEADING "Total Discount (USD)"
COLUMN avg_order_value FORMAT 999999999.99 HEADING "Avg Order Value (USD)"
COLUMN quality_score FORMAT 99999.99 HEADING "Quality Score (%)"

-- Title
TTITLE LEFT 'Generated On: ' _DATE -
       RIGHT 'Page: ' FORMAT 999 SQL.PNO SKIP 2 -
       CENTER 'Supplier Performance and Quality Analysis Report' SKIP 1 -
       CENTER 'Year: &input_year' SKIP 1 -
       CENTER '========================================================' SKIP 2

-- Generate Report
SELECT
  ds.CompanyName AS supplier_name,
  dp.ProductName AS product_name,
  COUNT(sf.OrderID) AS total_orders,
  SUM(sf.OrderTotalPrice) AS total_revenue,
  SUM(sf.Discount) AS total_discount,
  ROUND(AVG(sf.OrderTotalPrice), 2) AS avg_order_value,
  ROUND(SUM(sf.Quantity) / NULLIF(SUM(sf.Quantity * dp.UnitsInStock), 0) * 100, 2) AS quality_score
FROM Sales_Fact sf
JOIN Dim_Suppliers ds ON sf.SupplierKey = ds.SupplierKey
JOIN Dim_Product dp ON sf.ProductKey = dp.ProductKey
JOIN Dim_Date dd ON sf.DateKey = dd.DateKey
WHERE EXTRACT(YEAR FROM dd.CalendarDate) = &input_year
GROUP BY ds.CompanyName, dp.ProductName
ORDER BY supplier_name, product_name;

-- Clear formatting
CLEAR COLUMNS
CLEAR BREAKS
CLEAR COMPUTES
TTITLE OFF
