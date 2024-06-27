-- Formatting
CLEAR SCREEN;
SET SERVEROUTPUT ON
SET LINESIZE 150
SET PAGESIZE 150
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

-- Prompt user to input
ACCEPT input_year DATE FORMAT 'YYYY' PROMPT 'Enter the year (YYYY): '

-- Column Formatting
COLUMN region FORMAT A17 HEADING "Region"
COLUMN supplier_name FORMAT A38 HEADING "Supplier Name"
COLUMN contact_name FORMAT A28 HEADING "Contact Name"
COLUMN total_order_value FORMAT 999999999.99 HEADING "Total Order Value (USD)"
COLUMN order_count FORMAT 99999 HEADING "Order Count"
COLUMN avg_order_value FORMAT 999999999.99 HEADING "Avg Order Value (USD)"

-- Title
TTITLE LEFT 'Generated On: ' _DATE -
       RIGHT 'Page: ' FORMAT 999 SQL.PNO SKIP 2 -
       CENTER 'Top 5 Best Suppliers by Region Report' SKIP 1 -
       CENTER 'Year: &input_year' SKIP 1 -
       CENTER '=============================================================' SKIP 2 -

BREAK ON REPORT

-- Report View
CREATE OR REPLACE VIEW top_suppliers_by_region AS
WITH supplier_totals AS (
  SELECT 
    ds.Region AS region,
    ds.CompanyName AS supplier_name,
    ds.ContactName AS contact_name,
    COUNT(sf.OrderID) AS order_count,
    SUM(sf.UnitPrice * sf.Quantity) AS total_order_value,
    AVG(sf.UnitPrice * sf.Quantity) AS avg_order_value
  FROM Sales_Fact sf
  JOIN Dim_Suppliers ds ON sf.SupplierKey = ds.SupplierKey
  JOIN Dim_Date dd ON sf.DateKey = dd.DateKey
  WHERE EXTRACT(YEAR FROM dd.CalendarDate) = &input_year
  GROUP BY ds.Region, ds.CompanyName, ds.ContactName
)
-- Generate Report
SELECT
  region,
  supplier_name,
  contact_name,
  order_count,
  total_order_value,
  avg_order_value
FROM(
  SELECT 
    region,
    supplier_name,
    contact_name,
    order_count,
    total_order_value,
    avg_order_value,
    ROW_NUMBER() OVER (PARTITION BY region ORDER BY total_order_value DESC) AS rnk
  FROM supplier_totals
)
WHERE rnk <= 5
ORDER BY region;

-- Compute totals and averages
COMPUTE SUM LABEL 'TOTAL VALUE (USD): ' OF total_order_value ON REPORT

-- Execute the view to display the report
SELECT * FROM top_suppliers_by_region;

-- Clear formatting
CLEAR COLUMNS
CLEAR BREAKS
CLEAR COMPUTES
TTITLE OFF
