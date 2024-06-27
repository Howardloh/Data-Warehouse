-- Formatting
CLEAR SCREEN;
SET SERVEROUTPUT ON
SET LINESIZE 150
SET PAGESIZE 150
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

-- Prompt user to input
ACCEPT input_year DATE FORMAT 'YYYY' PROMPT ' Enter the year (YYYY) : '

-- Column Formatting
COLUMN product_name FORMAT A35 HEADING "Product Name"
COLUMN supplier_name FORMAT A40 HEADING "Supplier"
COLUMN prev_inventory_turnover FORMAT 999999999.99 HEADING "Prev. Year Inv Turnover"
COLUMN inventory_turnover FORMAT 999999999.99 HEADING "Inventory Turnover"
COLUMN stock_status FORMAT A15 HEADING "Stock Status"

-- Title
TTITLE LEFT 'Generated On: ' _DATE -
       RIGHT 'Page: ' FORMAT 999 SQL.PNO SKIP 2 -
       CENTER 'Product Inventory Turnover and Stock Status Report' SKIP 1 -
       CENTER 'Year: &input_year' SKIP 1 -
       CENTER '=============================================================' SKIP 2 -

-- Report View
CREATE OR REPLACE VIEW prac_inventory_turnover AS
WITH current_inventory AS (
  SELECT 
    dp.ProductName AS product_name,
    ds.CompanyName AS supplier_name,
    CASE 
      WHEN MAX(dp.UnitsInStock) != 0 
      THEN SUM(sf.Quantity) / MAX(dp.UnitsInStock) 
      ELSE NULL 
    END AS inventory_turnover
  FROM Sales_Fact sf
  JOIN Dim_Product dp ON sf.ProductKey = dp.ProductKey
  JOIN Dim_Suppliers ds ON sf.SupplierKey = ds.SupplierKey
  JOIN Dim_Date dd ON sf.DateKey = dd.DateKey
  WHERE EXTRACT(YEAR FROM dd.CalendarDate) = &input_year
  GROUP BY dp.ProductName, ds.CompanyName, dp.UnitsInStock
), 
previous_inventory AS (
  SELECT 
    dp.ProductName AS product_name,
    ds.CompanyName AS supplier_name,
    CASE 
      WHEN MAX(dp.UnitsInStock) != 0 
      THEN SUM(sf.Quantity) / MAX(dp.UnitsInStock) 
      ELSE NULL 
    END AS prev_inventory_turnover
  FROM Sales_Fact sf
  JOIN Dim_Product dp ON sf.ProductKey = dp.ProductKey
  JOIN Dim_Suppliers ds ON sf.SupplierKey = ds.SupplierKey
  JOIN Dim_Date dd ON sf.DateKey = dd.DateKey
  WHERE EXTRACT(YEAR FROM dd.CalendarDate) = &input_year - 1
  GROUP BY dp.ProductName, ds.CompanyName, dp.UnitsInStock
)

-- Generate Report
SELECT
  current_inventory.product_name,
  current_inventory.supplier_name,
  NVL(previous_inventory.prev_inventory_turnover, 0) AS prev_inventory_turnover,
  NVL(current_inventory.inventory_turnover, 0) AS inventory_turnover,
  CASE
    WHEN NVL(current_inventory.inventory_turnover, 0) > NVL(previous_inventory.prev_inventory_turnover, 0) THEN 'Improved'
    WHEN NVL(current_inventory.inventory_turnover, 0) = NVL(previous_inventory.prev_inventory_turnover, 0) THEN 'Constant'
    ELSE 'Declined'
  END AS stock_status
FROM current_inventory
LEFT JOIN previous_inventory
  ON current_inventory.product_name = previous_inventory.product_name
ORDER BY current_inventory.product_name;

-- Display computed results
SELECT * FROM prac_inventory_turnover;

-- Clear formatting
CLEAR COLUMNS
CLEAR BREAKS
CLEAR COMPUTES
TTITLE OFF