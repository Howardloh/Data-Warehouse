-- Formatting
CLEAR SCREEN;
SET SERVEROUTPUT ON
SET LINESIZE 155
SET PAGESIZE 50
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

-- Prompt user to input
ACCEPT input_year DATE FORMAT 'YYYY' PROMPT 'Enter the year (YYYY): '

-- Column Formatting
COLUMN employee_name FORMAT A22 HEADING "Employee Name"
COLUMN region FORMAT A12 HEADING "Region"
COLUMN total_sales FORMAT 999999999.99 HEADING "Total Sales (USD)"
COLUMN previous_year_sales FORMAT 999999999.99 HEADING "Previous Year Sales (USD)"
COLUMN sales_growth FORMAT 99999.99 HEADING "Sales Growth (%)"
COLUMN order_count FORMAT 99999 HEADING "Order Count"
COLUMN avg_order_value FORMAT 999999.99 HEADING "Avg Order Value (USD)"
COLUMN total_discount FORMAT 999999999.99 HEADING "Total Discount (USD)"

-- Title
TTITLE LEFT 'Generated On: ' _DATE -
       RIGHT 'Page: ' FORMAT 999 SQL.PNO SKIP 2 -
       CENTER 'Regional Sales Performance by Employee Achievement Report' SKIP 1 -
       CENTER 'Year: &input_year' SKIP 1 -
       CENTER '==============================================================' SKIP 2

BREAK ON region SKIP 1

COMPUTE SUM LABEL 'TOTAL:' OF total_sales previous_year_sales order_count ON region

-- Generate Report
WITH current_year_sales AS (
  SELECT
    de.FirstName || ' ' || de.LastName AS employee_name,
    dc.Region AS region,
    SUM(sf.OrderTotalPrice) AS total_sales,
    COUNT(sf.OrderID) AS order_count,
    SUM(sf.Discount) AS total_discount,
    AVG(sf.OrderTotalPrice) AS avg_order_value
  FROM Sales_Fact sf
  JOIN Dim_Employees de ON sf.EmployeeKey = de.EmployeeKey
  JOIN Dim_Customer dc ON sf.CustomerKey = dc.CustomerKey
  JOIN Dim_Date dd ON sf.DateKey = dd.DateKey
  WHERE EXTRACT(YEAR FROM dd.CalendarDate) = &input_year
  GROUP BY de.FirstName, de.LastName, dc.Region
),
previous_year_sales AS (
  SELECT
    de.FirstName || ' ' || de.LastName AS employee_name,
    dc.Region AS region,
    SUM(sf.OrderTotalPrice) AS previous_year_sales
  FROM Sales_Fact sf
  JOIN Dim_Employees de ON sf.EmployeeKey = de.EmployeeKey
  JOIN Dim_Customer dc ON sf.CustomerKey = dc.CustomerKey
  JOIN Dim_Date dd ON sf.DateKey = dd.DateKey
  WHERE EXTRACT(YEAR FROM dd.CalendarDate) = &input_year - 1
  GROUP BY de.FirstName, de.LastName, dc.Region
)
SELECT
  cys.employee_name,
  cys.region,
  cys.total_sales,
  pys.previous_year_sales,
  ROUND(COALESCE((cys.total_sales - pys.previous_year_sales) / pys.previous_year_sales * 100, 0), 2) AS sales_growth,
  cys.order_count,
  cys.avg_order_value,
  cys.total_discount
FROM current_year_sales cys
LEFT JOIN previous_year_sales pys
  ON cys.employee_name = pys.employee_name AND cys.region = pys.region
ORDER BY region, total_sales DESC;

-- Clear formatting
CLEAR COLUMNS
CLEAR BREAKS
CLEAR COMPUTES
TTITLE OFF
