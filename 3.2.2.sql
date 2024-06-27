-- Formatting
CLEAR SCREEN;
SET SERVEROUTPUT ON
SET LINESIZE 145
SET PAGESIZE 50
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

-- Prompt user to input
ACCEPT input_year DATE FORMAT 'YYYY' PROMPT 'Enter the year (YYYY): '


-- Column Formatting
COLUMN region FORMAT A15 HEADING "Region"
COLUMN quarter FORMAT A9 HEADING "Quarter"
COLUMN total_sales FORMAT 999999999.99 HEADING "Total Sales (USD)"
COLUMN average_sales FORMAT 999999999.99 HEADING "Average Sales (USD)"
COLUMN num_orders FORMAT 99999 HEADING "Number of Orders"
COLUMN total_quantity FORMAT 999999999.99 HEADING "Total Quantity"
COLUMN total_discounts FORMAT 999999999.99 HEADING "Total Discounts (USD)"
COLUMN total_freight FORMAT 999999999.99 HEADING "Total Freight (USD)"

-- Title
TTITLE LEFT 'Generated On: ' _DATE -
       RIGHT 'Page: ' FORMAT 999 SQL.PNO SKIP 2 -
       CENTER 'Quarterly Sales Performance by Region Report' SKIP 1 -
       CENTER 'Year: &input_year' SKIP 1 -
       CENTER '========================================================' SKIP 2

-- Summary Section
COMPUTE SUM LABEL 'TOTAL: ' OF total_sales average_sales num_orders total_quantity total_discounts total_freight ON region 
BREAK ON region SKIP 1

-- Report View
CREATE OR REPLACE VIEW quarterly_sales_region_view AS
SELECT 
  dc.Region AS region,
  dd.CalQuarter AS quarter,
  SUM(sf.UnitPrice * sf.Quantity) AS total_sales,
  AVG(sf.UnitPrice * sf.Quantity) AS average_sales,
  COUNT(sf.OrderID) AS num_orders,
  SUM(sf.Quantity) AS total_quantity,
  SUM(sf.Discount) AS total_discounts,
  SUM(sf.Freight) AS total_freight
FROM Sales_Fact sf
JOIN Dim_Customer dc ON sf.CustomerKey = dc.CustomerKey
JOIN Dim_Date dd ON sf.DateKey = dd.DateKey
WHERE EXTRACT(YEAR FROM dd.CalendarDate) = &input_year
GROUP BY dc.Region, dd.CalQuarter;

-- Generate Report
SELECT 
  region,
  quarter,
  total_sales,
  average_sales,
  num_orders,
  total_quantity,
  total_discounts,
  total_freight
FROM quarterly_sales_region_view
ORDER BY region, average_sales DESC, quarter;

-- Clear formatting
CLEAR COLUMNS
CLEAR BREAKS
CLEAR COMPUTES
TTITLE OFF
