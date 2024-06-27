-- Formatting
CLEAR SCREEN;
SET SERVEROUTPUT ON
SET LINESIZE 170
SET PAGESIZE 300
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

-- Prompt user to input
ACCEPT input_year NUMBER PROMPT 'Enter the year (YYYY): '
ACCEPT input_quarter CHAR PROMPT 'Enter the quarter (Q1, Q2, Q3, or Q4): '

-- Column Formatting
COLUMN product_id FORMAT 9999 HEADING "Product ID"
COLUMN product_name FORMAT A20 TRUNC HEADING "Product Name"
COLUMN product_category FORMAT A20 HEADING "Category"
COLUMN standard_cost FORMAT 999999999.99 HEADING "Standard Cost (USD)"
COLUMN unit_sold FORMAT 99999999 HEADING "Unit Sold"
COLUMN sales_revenue FORMAT 999999999.99 HEADING "Total Revenue (USD)"
COLUMN gross_profit FORMAT 999999999.99 HEADING "Gross Profit (USD)"
COLUMN gross_profit_margin FORMAT 999.99 HEADING "Gross Profit Margin (%)"
COLUMN avg_unit_price FORMAT 999999.99 HEADING "Avg Unit Price (USD)"

-- Title
TTITLE LEFT 'Generated On: ' _DATE -
       RIGHT 'Page: ' FORMAT 999 SQL.PNO SKIP 2 -
       CENTER 'Quarterly Profit Margin Trends Analysis Report' SKIP 1 -
       CENTER 'Year: &input_year | Quarter: &input_quarter' SKIP 1 -
       CENTER '=======================================================' SKIP 2
BREAK ON REPORT

COMPUTE SUM LABEL 'TOTAL: ' OF standard_cost ON REPORT
COMPUTE SUM OF unit_sold ON REPORT
COMPUTE SUM OF sales_revenue ON REPORT
COMPUTE SUM OF gross_profit ON REPORT

-- Report View
CREATE OR REPLACE VIEW quarterly_profit_margin_report AS
SELECT 
    dp.ProductID AS product_id,
    dp.ProductName AS product_name,
    dp.CategoryName AS product_category,
    dp.UnitPrice AS standard_cost,
    SUM(sf.Quantity) AS unit_sold,
    SUM(sf.OrderTotalPrice) AS sales_revenue,
    SUM(sf.OrderTotalPrice - (sf.Quantity * dp.UnitPrice)) AS gross_profit,
    ROUND(SUM(sf.OrderTotalPrice - (sf.Quantity * dp.UnitPrice)) / SUM(sf.OrderTotalPrice) * 100, 2) AS gross_profit_margin,
    ROUND(AVG(sf.UnitPrice), 2) AS avg_unit_price
FROM 
    Sales_Fact sf
JOIN 
    Dim_Product dp ON sf.ProductKey = dp.ProductKey
JOIN 
    Dim_Date dd ON sf.DateKey = dd.DateKey
WHERE 
    EXTRACT(YEAR FROM dd.CalendarDate) = &input_year
    AND dd.CalQuarter = '&input_quarter'
GROUP BY 
    dp.ProductID, dp.ProductName, dp.CategoryName, dp.UnitPrice
ORDER BY 
    gross_profit_margin;

-- Generate Report
SELECT * FROM quarterly_profit_margin_report;

-- Clear formatting
CLEAR COLUMNS
CLEAR BREAKS
CLEAR COMPUTES
TTITLE OFF
