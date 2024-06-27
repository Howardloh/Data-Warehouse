-- Formatting
CLEAR SCREEN;
SET SERVEROUTPUT ON
SET LINESIZE 150
SET PAGESIZE 150
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

-- Prompt user to input
ACCEPT input_year DATE FORMAT 'YYYY' PROMPT ' Enter the year (YYYY) : '
ACCEPT input_emp_id NUMBER PROMPT ' Enter the Employee ID : '

-- Column Formatting
COLUMN employee_name FORMAT A20 HEADING "Employee Name"
COLUMN product_name FORMAT A32 HEADING "Product Name"
COLUMN annual_sales FORMAT 999999999.99 HEADING "Annual Sales (USD)"
COLUMN pre_sales FORMAT 999999999.99 HEADING "Previous Year Sales (USD)"
COLUMN growth FORMAT 99999.99 HEADING "Growth Rate (%)"
COLUMN sales_performance FORMAT A20 HEADING "Performance"

-- Title
TTITLE LEFT 'Generated On: ' _DATE -
       RIGHT 'Page: ' FORMAT 999 SQL.PNO SKIP 2 -
       CENTER 'Annual Sales by Product and Employee Report' SKIP 1 -
       CENTER 'Year: &input_year | Employee ID: &input_emp_id' SKIP 1 -
       CENTER '=============================================================' SKIP 2 -

BREAK ON employee_name

-- Report View
CREATE OR REPLACE VIEW prac_annual_sales AS
WITH annual_sales AS (
  SELECT 
    de.FirstName || ' ' || de.LastName AS employee_name,
    dp.ProductName AS product_name,
    SUM(sf.UnitPrice * sf.Quantity) AS annual_sales
  FROM Sales_Fact sf
  JOIN Dim_Employees de ON sf.EmployeeKey = de.EmployeeKey
  JOIN Dim_Product dp ON sf.ProductKey = dp.ProductKey
  JOIN Dim_Date dd ON sf.DateKey = dd.DateKey
  WHERE EXTRACT(YEAR FROM dd.CalendarDate) = &input_year
  AND de.EmployeeID = &input_emp_id
  GROUP BY de.FirstName, de.LastName, dp.ProductName
), 
previous_year_sales AS (
  SELECT 
    de.FirstName || ' ' || de.LastName AS employee_name,
    dp.ProductName AS product_name,
    SUM(sf.UnitPrice * sf.Quantity) AS pre_sales
  FROM Sales_Fact sf
  JOIN Dim_Employees de ON sf.EmployeeKey = de.EmployeeKey
  JOIN Dim_Product dp ON sf.ProductKey = dp.ProductKey
  JOIN Dim_Date dd ON sf.DateKey = dd.DateKey
  WHERE EXTRACT(YEAR FROM dd.CalendarDate) = &input_year - 1
  AND de.EmployeeID = &input_emp_id
  GROUP BY de.FirstName, de.LastName, dp.ProductName
)
-- Generate Report
SELECT
  annual_sales.employee_name,
  annual_sales.product_name,
  NVL(annual_sales.annual_sales, 0) AS annual_sales,
  NVL(previous_year_sales.pre_sales, 0) AS pre_sales,
  ROUND(COALESCE((annual_sales.annual_sales - previous_year_sales.pre_sales) / previous_year_sales.pre_sales * 100, 0), 2) AS growth,
  CASE
    WHEN COALESCE((annual_sales.annual_sales - previous_year_sales.pre_sales) / previous_year_sales.pre_sales * 100, 0) > 0 THEN 'Improved Performance'
    WHEN COALESCE((annual_sales.annual_sales - previous_year_sales.pre_sales) / previous_year_sales.pre_sales * 100, 0) = 0 THEN 'Constant Performance'
    WHEN COALESCE((annual_sales.annual_sales - previous_year_sales.pre_sales) / previous_year_sales.pre_sales * 100, 0) < 0 THEN 'Reduced Performance'
  END AS sales_performance
FROM annual_sales
LEFT JOIN previous_year_sales
  ON annual_sales.employee_name = previous_year_sales.employee_name 
  AND annual_sales.product_name = previous_year_sales.product_name
ORDER BY annual_sales.employee_name, annual_sales.product_name;

-- Compute totals and averages
COMPUTE SUM LABEL 'TOTAL SALES (USD): ' OF annual_sales ON employee_name

-- Display computed results
SELECT * FROM prac_annual_sales;

-- Clear formatting
CLEAR COLUMNS
CLEAR BREAKS
CLEAR COMPUTES
TTITLE OFF