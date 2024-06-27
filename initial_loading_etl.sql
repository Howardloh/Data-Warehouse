SET LINESIZE 200
SET PAGESIZE 100

-- DATE DIMENSION ----------------------------------------------------------------------------------------------
-- Drop and Create Sequence of Date Dimension
DROP SEQUENCE Date_Seq;

CREATE SEQUENCE Date_Seq 
START WITH 1000001
INCREMENT BY 1;

-- Drop and Create Date Dimension
DROP TABLE Dim_Date;

CREATE TABLE Dim_Date ( 
    DateKey NUMBER NOT NULL,
    CalendarDate DATE NOT NULL,
    DayOfWeek NUMBER(1) NOT NULL,
    DayOfMonth NUMBER(2) NOT NULL,
    DayOfYear NUMBER(3) NOT NULL,
    LastDayInMonthInd CHAR(1),
    CalWeekEndDate DATE NOT NULL,
    CalWeekNoInYear NUMBER(2) NOT NULL,
    CalMonthName VARCHAR(9) NOT NULL,
    CalMonthNoInYear NUMBER(2) NOT NULL,
    CalYearMonth CHAR(7) NOT NULL,
    CalQuarter CHAR(2) NOT NULL,
    CalYearQuarter CHAR(6) NOT NULL,
    CalYear NUMBER(4) NOT NULL,
    HolidayInd CHAR(1),
    WeekdayInd CHAR(1),
    PRIMARY KEY (DateKey) 
);

-- Insert Data into Date Dimension
DECLARE
   EveryDate         DATE;
   EndDate           DATE;
   DayOfWeek         NUMBER(1);
   DayOfMonth        NUMBER(2);
   DayOfYear         NUMBER(3);
   LastDayMonthInd   CHAR(1);
   WeekEndDate       DATE;
   WeekInYear        NUMBER(2);
   MonthName         VARCHAR(9);
   MonthNo           NUMBER(2);
   YearMonth         CHAR(7);
   Quarter           CHAR(2);
   YearQuarter       CHAR(6); 
   Year              NUMBER(4);
   HolidayInd        CHAR(1);
   WeekdayInd        CHAR(1);

BEGIN
   EveryDate     := TO_DATE('01/01/1937','dd/mm/yyyy');
   EndDate       := TO_DATE('01/05/2024','dd/mm/yyyy');
   HolidayInd    := 'N';

   WHILE (EveryDate <= EndDate) LOOP
      DayOfWeek    := TO_CHAR(EveryDate,'D');
      DayOfMonth   := TO_CHAR(EveryDate,'DD');
      DayOfYear    := TO_CHAR(EveryDate,'DDD');

      IF EveryDate = Last_Day(EveryDate) THEN
        LastDayMonthInd := 'Y';
      END IF;

      WeekEndDate  := EveryDate + (7 - TO_CHAR(EveryDate,'d'));
  
      WeekInYear   := TO_CHAR(EveryDate,'IW');
      MonthName    := TO_CHAR(EveryDate,'MONTH');
      MonthNo      := EXTRACT (MONTH FROM EveryDate);
      YearMonth    := TO_CHAR(EveryDate,'YYYY-MM');

      IF (MonthNo <= 3) THEN
         Quarter := 'Q1';
      ELSIF (MonthNo <= 6) THEN
         Quarter := 'Q2';
      ELSIF (MonthNo <= 9) THEN
         Quarter := 'Q3';
      ELSE
         Quarter := 'Q4';
      END IF;

      Year          := EXTRACT (year FROM EveryDate);
      YearQuarter   := Year || Quarter;

      IF (DayOfWeek BETWEEN 2 AND 6) THEN
         WeekdayInd := 'Y';
      ELSE
         WeekdayInd := 'N';
      END IF;
      
      INSERT INTO Dim_Date VALUES (
          Date_Seq.NEXTVAL,
          EveryDate,
          DayOfWeek,
          DayOfMonth,
          DayOfYear,
          LastDayMonthInd,
          WeekEndDate,
          WeekInYear,
          MonthName,
          MonthNo,
          YearMonth,
          Quarter,
          YearQuarter, 
          Year,
          HolidayInd,
          WeekdayInd
      );
      
      EveryDate := EveryDate + 1;
   END LOOP;
END;
/

-- Examine the Date Dimension table
SELECT * FROM Dim_Date;

-- CUSTOMER DIMENSION ------------------------------------------------------------------------------------------
-- Drop and Create Sequence of Customer Dimension
DROP SEQUENCE Cust_Seq;

CREATE SEQUENCE Cust_Seq
START WITH 10000001
INCREMENT BY 1;

-- Drop and Create the Customer Dimension
DROP TABLE Dim_Customer;

CREATE TABLE Dim_Customer (
    CustomerKey        NUMBER PRIMARY KEY,
    CustomerID         VARCHAR(5) NOT NULL,
    CompanyName        VARCHAR(40) NOT NULL,
    ContactName        VARCHAR(30),
    ContactTitle       VARCHAR(30),
    City               VARCHAR(15),
    Region             VARCHAR(15),
    PostalCode         VARCHAR(10),
    Country            VARCHAR(15)
);

-- Insert Data into the Customer Dimension
INSERT INTO Dim_Customer (
    CustomerKey, 
    CustomerID, 
    CompanyName, 
    ContactName, 
    ContactTitle, 
    City, 
    Region,
    PostalCode,
    Country)
SELECT 
    Cust_Seq.NEXTVAL, 
    UPPER(cu.CustomerID),
    UPPER(cu.CompanyName), 
    UPPER(cu.ContactName),
    UPPER(cu.ContactTitle), 
    UPPER(cu.City),
    UPPER(cu.Region), 
    UPPER(cu.PostalCode),
    UPPER(cu.Country)
FROM Customers cu;

-- Examine the Customer Dimension table
SELECT * FROM Dim_Customer;

-- PRODUCT DIMENSION ------------------------------------------------------------------------------------------
-- Drop and Create Sequence of Product Dimension
DROP SEQUENCE Prod_Seq;

CREATE SEQUENCE Prod_Seq
START WITH 100001
INCREMENT BY 1;

-- Drop and Create the Product Dimension
DROP TABLE Dim_Product;

CREATE TABLE Dim_Product (
    ProductKey         NUMBER PRIMARY KEY,
    ProductID          NUMBER NOT NULL,
    ProductName        VARCHAR(40) NOT NULL,
    CategoryName       VARCHAR(15) NOT NULL,
    Description        VARCHAR(100),
    QuantityPerUnit    VARCHAR(20),
    UnitPrice          NUMBER(6,2) DEFAULT 0,
    UnitsInStock       NUMBER DEFAULT 0,
    UnitsOnOrder       NUMBER DEFAULT 0,
    ReorderLevel       NUMBER DEFAULT 0,
    Discontinued       NUMBER(1) DEFAULT 0
);

-- Insert Data into Product Dimension
INSERT INTO Dim_Product (
    ProductKey, 
    ProductID, 
    ProductName, 
    CategoryName, 
    Description, 
    QuantityPerUnit, 
    UnitPrice,
    UnitsInStock,
    UnitsOnOrder,
    ReorderLevel,
    Discontinued)
SELECT 
    Prod_Seq.NEXTVAL, 
    p.ProductID, 
    UPPER(p.ProductName), 
    UPPER(c.CategoryName),
    UPPER(c.Description), 
    UPPER(p.QuantityPerUnit),
    p.UnitPrice,
    p.UnitsInStock,
    p.UnitsOnOrder,
    p.ReorderLevel,
    p.Discontinued
FROM Products p 
INNER JOIN Categories c 
	ON p.CategoryID = c.CategoryID;

-- Examine the Product Dimension table
SELECT * FROM Dim_Product;

-- SHIPPER DIMENSION ------------------------------------------------------------------------------------------
-- Drop and Create Sequence of Shipper Dimension
DROP SEQUENCE Ship_Seq;

CREATE SEQUENCE Ship_Seq
START WITH 101
INCREMENT BY 1;

-- Drop and Create the Shipper Dimension
DROP TABLE Dim_Shipper;

CREATE TABLE Dim_Shipper (
    ShipperKey         NUMBER PRIMARY KEY,
    ShipperID          NUMBER NOT NULL,
    CompanyName        VARCHAR(40) NOT NULL,
    Phone              VARCHAR(24)
);

-- Insert Data into the Shipper Dimension
INSERT INTO Dim_Shipper (
    ShipperKey, 
    ShipperID, 
    CompanyName, 
    Phone)
SELECT 
    Ship_Seq.NEXTVAL, 
    s.ShipperID,
    UPPER(s.CompanyName), 
    UPPER(s.Phone)
FROM Shippers s;

-- Examine the Shipper Dimension table
SELECT * FROM Dim_Shipper;

-- SUPPLIERS DIMENSION ------------------------------------------------------------------------------------------
-- Drop and Create Sequence of Suppliers Dimension
DROP SEQUENCE Supp_Seq;

CREATE SEQUENCE Supp_Seq
START WITH 1001
INCREMENT BY 1;

-- Drop and Create the Suppliers Dimension
DROP TABLE Dim_Suppliers;

CREATE TABLE Dim_Suppliers (
    SupplierKey        NUMBER PRIMARY KEY,
    SupplierID         NUMBER NOT NULL,
    CompanyName        VARCHAR(40) NOT NULL,
    ContactName        VARCHAR(30),
    ContactTitle       VARCHAR(30),
    City               VARCHAR(15),
    Region             VARCHAR(15),
    PostalCode         VARCHAR(10),
    Country            VARCHAR(15)
);

-- Insert Data into the Suppliers Dimension
INSERT INTO Dim_Suppliers (
    SupplierKey, 
    SupplierID, 
    CompanyName, 
    ContactName,
    ContactTitle,
    City,
    Region,
    PostalCode,
    Country)
SELECT 
    Supp_Seq.NEXTVAL, 
    su.SupplierID,
    UPPER(su.CompanyName), 
    UPPER(su.ContactName),
    UPPER(su.ContactTitle), 
    UPPER(su.City),    
    UPPER(su.Region), 
    UPPER(su.PostalCode),
    UPPER(su.Country)
FROM Suppliers su;

-- Examine the Supplier Dimension table
SELECT * FROM Dim_Suppliers;

-- EMPLOYEES DIMENSION ------------------------------------------------------------------------------------------
-- Drop and Create Sequence of Employees Dimension
DROP SEQUENCE Emp_Seq;

CREATE SEQUENCE Emp_Seq
START WITH 10001
INCREMENT BY 1;

-- Drop and Create the Employees Dimension
DROP TABLE Dim_Employees;

CREATE TABLE Dim_Employees (
    EmployeeKey        NUMBER PRIMARY KEY,
    EmployeeID         NUMBER NOT NULL,
    FirstName          VARCHAR(10) NOT NULL,
    LastName           VARCHAR(20) NOT NULL,
    Title              VARCHAR(30),
    BirthDateKey       NUMBER,
    HireDateKey        NUMBER,
    City               VARCHAR(15),
    Region             VARCHAR(15),
    PostalCode         VARCHAR(10),
    Country            VARCHAR(15),
    ReportsTo          NUMBER,
    FOREIGN KEY (BirthDateKey) REFERENCES Dim_Date(DateKey),
    FOREIGN KEY (HireDateKey) REFERENCES Dim_Date(DateKey)
);

-- Insert Data into the Employees Dimension
INSERT INTO Dim_Employees (
    EmployeeKey, 
    EmployeeID, 
    FirstName, 
    LastName, 
    Title, 
    BirthDateKey,
    HireDateKey,
    City,
    Region,
    PostalCode,
    Country,
    ReportsTo
)
SELECT 
    Emp_Seq.NEXTVAL,
    e.EmployeeID,
    e.FirstName,
    e.LastName,
    e.Title,
    (SELECT DateKey FROM Dim_Date WHERE CalendarDate = e.BirthDate) AS BirthDateKey,
    (SELECT DateKey FROM Dim_Date WHERE CalendarDate = e.HireDate) AS HireDateKey,
    e.City,
    e.Region,
    e.PostalCode,
    e.Country,
    e.ReportsTo
FROM Employees e;

-- Examine the Employees Dimension table
SELECT * FROM Dim_Employees;

-- SALES FACT ---------------------------------------------------------------------------------------------------
-- Drop Sales Fact Table
--DROP TABLE Sales_Fact;

-- Create Sales Fact Table
CREATE TABLE Sales_Fact (
    DateKey            NUMBER,
    ProductKey         NUMBER,
    CustomerKey        NUMBER,
    ShipperKey         NUMBER,
    SupplierKey        NUMBER,
    EmployeeKey        NUMBER,
    OrderID            NUMBER,
    RequiredDateID     NUMBER,
    ShippedDateID      NUMBER,
    ShipVia            NUMBER,
    Freight            NUMBER(6,2),
    Quantity           NUMBER,
    UnitPrice          NUMBER(6,2),
    OrderStatus        VARCHAR(25),
    OrderTotalPrice    NUMBER(9,2),
    Discount           NUMBER(3,2),
    CONSTRAINT sales_fk_date FOREIGN KEY (DateKey) REFERENCES Dim_Date(DateKey) ON DELETE CASCADE,
    CONSTRAINT sales_fk_prod FOREIGN KEY (ProductKey) REFERENCES Dim_Product(ProductKey) ON DELETE CASCADE,
    CONSTRAINT sales_fk_cust FOREIGN KEY (CustomerKey) REFERENCES Dim_Customer(CustomerKey) ON DELETE CASCADE,
    CONSTRAINT sales_fk_ship FOREIGN KEY (ShipperKey) REFERENCES Dim_Shipper(ShipperKey) ON DELETE CASCADE,
    CONSTRAINT sales_fk_suppl FOREIGN KEY (SupplierKey) REFERENCES Dim_Suppliers(SupplierKey) ON DELETE CASCADE,
    CONSTRAINT sales_fk_empl FOREIGN KEY (EmployeeKey) REFERENCES Dim_Employees(EmployeeKey) ON DELETE CASCADE,
    FOREIGN KEY (RequiredDateID) REFERENCES Dim_Date(DateKey),
    FOREIGN KEY (ShippedDateID) REFERENCES Dim_Date(DateKey)
);

-- Insert data into Sales Fact Table
INSERT INTO Sales_Fact (
    DateKey,
    ProductKey,
    CustomerKey,
    ShipperKey,
    SupplierKey,
    EmployeeKey,
    OrderID,
    RequiredDateID,
    ShippedDateID,
    ShipVia,
    Freight,
    Quantity,
    UnitPrice,
    OrderStatus,
    OrderTotalPrice,
    Discount
)
SELECT 
    dd.DateKey,
    dp.ProductKey,
    dc.CustomerKey,
    ds.ShipperKey,
    dsup.SupplierKey,
    de.EmployeeKey,
    o.OrderID,
    rd.DateKey AS RequiredDateID,
    sd.DateKey AS ShippedDateID,
    o.ShipVia,
    o.Freight,
    od.Quantity,
    od.UnitPrice,
    CASE 
        WHEN o.ShippedDate IS NOT NULL AND o.ShippedDate < SYSDATE THEN 'Shipped'
        ELSE 'Pending'
    END AS OrderStatus,
    od.Quantity * od.UnitPrice AS OrderTotalPrice,
    od.Discount
FROM Orders o
JOIN Order_Details od ON o.OrderID = od.OrderID
JOIN Dim_Date dd ON dd.CalendarDate = o.OrderDate
LEFT JOIN Dim_Date rd ON rd.CalendarDate = o.RequiredDate
LEFT JOIN Dim_Date sd ON sd.CalendarDate = o.ShippedDate
JOIN Dim_Product dp ON dp.ProductID = od.ProductID
JOIN Products p ON od.ProductID = p.ProductID
LEFT JOIN Dim_Suppliers dsup ON dsup.SupplierID = p.SupplierID
JOIN Dim_Customer dc ON dc.CustomerID = o.CustomerID
LEFT JOIN Dim_Shipper ds ON ds.ShipperID = o.ShipVia
LEFT JOIN Dim_Employees de ON de.EmployeeID = o.EmployeeID;

-- Examine the Sales Fact table
SELECT * FROM Sales_Fact;