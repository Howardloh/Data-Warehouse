-- Formatting
CLEAR SCREEN;
SET SERVEROUTPUT ON
SET LINESIZE 155
SET PAGESIZE 50
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

-- Prompt user to input
ACCEPT input_year DATE FORMAT 'YYYY' PROMPT 'Enter the year (YYYY): '

-- Column Formatting
COLUMN shipper_name FORMAT A16 HEADING "Shipper Name"
COLUMN region FORMAT A14 HEADING "Region"
COLUMN quarter FORMAT A7 HEADING "Quarter"
COLUMN total_shipped_orders FORMAT 99999 HEADING "Total Shipped Orders"
COLUMN avg_delivery_time FORMAT 999.99 HEADING "Avg Delivery Time (Days)"
COLUMN on_time_delivery FORMAT 999.99 HEADING "On-Time Delivery (%)"
COLUMN freight_cost FORMAT 999999999.99 HEADING "Total Freight Cost (USD)"
COLUMN order_total_price FORMAT 999999999.99 HEADING "Total Order Price (USD)"

-- Title
TTITLE LEFT 'Generated On: ' _DATE -
       RIGHT 'Page: ' FORMAT 999 SQL.PNO SKIP 2 -
       CENTER 'Shipped Orders and Delivery Performance Report' SKIP 1 -
       CENTER 'Year: &input_year' SKIP 1 -
       CENTER '========================================================' SKIP 2

BREAK ON shipper_name SKIP 1

-- COMPUTE statements to calculate the total for each shipper
COMPUTE SUM LABEL 'TOTAL:' OF total_shipped_orders freight_cost order_total_price ON shipper_name

-- Report View
CREATE OR REPLACE VIEW ship_orders_del_perf AS
SELECT 
  ds.CompanyName AS shipper_name,
  dc.Region AS region,
  dd.CalQuarter AS quarter,
  COUNT(sf.OrderID) AS total_shipped_orders,
  AVG(sd.CalendarDate - dd.CalendarDate) AS avg_delivery_time,
  ROUND(SUM(CASE WHEN sf.OrderStatus = 'Shipped' THEN 1 ELSE 0 END) / COUNT(sf.OrderID) * 100, 2) AS on_time_delivery,
  SUM(sf.Freight) AS freight_cost,
  SUM(sf.OrderTotalPrice) AS order_total_price
FROM Sales_Fact sf
JOIN Dim_Shipper ds ON sf.ShipperKey = ds.ShipperKey
JOIN Dim_Customer dc ON sf.CustomerKey = dc.CustomerKey
JOIN Dim_Date dd ON sf.DateKey = dd.DateKey
JOIN Dim_Date sd ON sf.ShippedDateID = sd.DateKey
WHERE EXTRACT(YEAR FROM dd.CalendarDate) = &input_year
AND sf.OrderStatus = 'Shipped'
AND dc.Region IS NOT NULL -- Exclude rows with NULL Region
GROUP BY ds.CompanyName, dc.Region, dd.CalQuarter;

-- Generate Report
SELECT 
  shipper_name,
  region,
  quarter,
  total_shipped_orders,
  avg_delivery_time,
  on_time_delivery,
  freight_cost,
  order_total_price
FROM ship_orders_del_perf
ORDER BY shipper_name, region, quarter;

-- Clear formatting
CLEAR COLUMNS
CLEAR BREAKS
CLEAR COMPUTES
TTITLE OFF
