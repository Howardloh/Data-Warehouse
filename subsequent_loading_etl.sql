-- DATE DIMENSION ----------------------------------------------------------------------------------------------
-- 1. Update subsequent/new dates into the Date Dimension Table
CREATE OR REPLACE PROCEDURE prc_populate_dim_date (start_date IN DATE, end_date IN DATE) IS

   -- Variable Declarations
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
   -- Initialize the start date, end date, and holiday to 'N'
   EveryDate     := start_date;
   EndDate       := end_date;
   HolidayInd    := 'N';

   -- Loop while the date is within EveryDate and EndDate
   WHILE (EveryDate <= EndDate) LOOP
      DayOfWeek    := TO_NUMBER(TO_CHAR(EveryDate,'D'));
      DayOfMonth   := TO_NUMBER(TO_CHAR(EveryDate,'DD'));
      DayOfYear    := TO_NUMBER(TO_CHAR(EveryDate,'DDD'));

      IF EveryDate = Last_Day(EveryDate) THEN
        LastDayMonthInd := 'Y';
      ELSE
        LastDayMonthInd := 'N';
      END IF;

      WeekEndDate  := EveryDate + (7 - TO_NUMBER(TO_CHAR(EveryDate,'D')));
  
      WeekInYear   := TO_NUMBER(TO_CHAR(EveryDate,'IW'));
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

      Year          := EXTRACT (YEAR FROM EveryDate);
      YearQuarter   := TO_CHAR(Year) || Quarter;

      IF (DayOfWeek BETWEEN 2 AND 6) THEN
         WeekdayInd := 'Y';
      ELSE
         WeekdayInd := 'N';
      END IF;
      
      -- Insert Data into Dim_Date
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

-- Alter session to a specific Date Format
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

-- Execute the procedure with desired start and end dates
EXEC prc_populate_dim_date(TO_DATE('01/05/2024', 'DD/MM/YYYY'), TO_DATE('01/06/2024', 'DD/MM/YYYY'));

-- Check the Dim_Date table
SELECT *
FROM Dim_Date
WHERE CalendarDate BETWEEN TO_DATE('2024-05-01', 'YYYY-MM-DD') AND TO_DATE('2024-06-01', 'YYYY-MM-DD');


-- 2. Type 1 Slowly Changing Dimension technique: Update Holidays Procedure
CREATE OR REPLACE PROCEDURE update_holidays_prc (
    prc_date IN DATE
) IS
    is_update_allowed BOOLEAN;

BEGIN
    -- Update the record to mark the date as a holiday
    UPDATE Dim_Date
    SET HolidayInd = 'Y'
    WHERE CalendarDate = prc_date;

    -- Provide feedback to the user
    IF SQL%FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Input Date: ' || TO_CHAR(prc_date, 'DD/MM/YYYY') || ' has been updated as a Holiday in the Dim_Date table.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('ERROR! No such date in the database.');
    END IF;
END;
/

-- Optional: Alter the session to a specific Date Format
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

-- Example Execution of the Procedure
EXEC update_holidays_prc(TO_DATE('01/01/2024', 'DD/MM/YYYY'));

-- Check the Dim_Date table
SELECT *
FROM Dim_Date
WHERE CalendarDate = TO_DATE('01/01/2024', 'DD/MM/YYYY');


-- 3. Type 1 Slowly Changing Dimension technique: Update Weekdays Procedure
CREATE OR REPLACE PROCEDURE update_weekday_prc (
    prc_date IN DATE
) IS
    day_number NUMBER;

BEGIN
    -- Determine the day of the week as a number (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
    day_number := TO_NUMBER(TO_CHAR(prc_date, 'D'));

    -- Update the WeekdayInd column based on the numeric day of the week
    UPDATE Dim_Date
    SET WeekdayInd = CASE
        WHEN day_number BETWEEN 2 AND 6 THEN 'Y'
        ELSE 'N'
    END
    WHERE CalendarDate = prc_date;

    -- Provide feedback to the user
    IF SQL%FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Input Date: ' || TO_CHAR(prc_date, 'DD/MM/YYYY') || ' has been updated with WeekdayInd in the Dim_Date table.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('ERROR! No such date in the database.');
    END IF;
END;
/

-- Optional: Alter the session to a specific Date Format
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

-- Example Execution of the Procedure
EXEC update_weekday_prc(TO_DATE('01/02/2024', 'DD/MM/YYYY'));

-- Check the Dim_Date table
SELECT *
FROM Dim_Date
WHERE CalendarDate = TO_DATE('01/02/2024', 'DD/MM/YYYY');



-- 4. Adding Fiscal Calendar Information into the Date Dimension Table
ALTER TABLE Dim_Date
ADD (
    FiscalYear NUMBER(4),
    FiscalQuarter CHAR(2),
    FiscalMonth NUMBER(2)
);

CREATE OR REPLACE PROCEDURE prc_fiscal_dim_date (
    start_date IN DATE,
    end_date IN DATE
) IS
    -- Variable Declarations
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
    FiscalYear        NUMBER(4);
    FiscalQuarter     CHAR(2);
    FiscalMonth       NUMBER(2);

BEGIN
    -- Initialize the start date and end date
    EveryDate     := start_date;
    EndDate       := end_date;
    HolidayInd    := 'N';

    -- Loop while the date is within EveryDate and EndDate
    WHILE (EveryDate <= EndDate) LOOP
        DayOfWeek    := TO_NUMBER(TO_CHAR(EveryDate,'D'));
        DayOfMonth   := TO_NUMBER(TO_CHAR(EveryDate,'DD'));
        DayOfYear    := TO_NUMBER(TO_CHAR(EveryDate,'DDD'));

        IF EveryDate = Last_Day(EveryDate) THEN
            LastDayMonthInd := 'Y';
        ELSE
            LastDayMonthInd := 'N';
        END IF;

        WeekEndDate  := EveryDate + (7 - TO_NUMBER(TO_CHAR(EveryDate,'D')));
    
        WeekInYear   := TO_NUMBER(TO_CHAR(EveryDate,'IW'));
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

        Year          := EXTRACT (YEAR FROM EveryDate);
        YearQuarter   := TO_CHAR(Year) || Quarter;

        IF (DayOfWeek BETWEEN 2 AND 6) THEN
            WeekdayInd := 'Y';
        ELSE
            WeekdayInd := 'N';
        END IF;

        -- Determine Fiscal Year, Fiscal Quarter, and Fiscal Month
        IF (MonthNo >= 4) THEN
            FiscalYear := Year + 1; -- Fiscal year starts in April
            FiscalMonth := MonthNo - 3;
        ELSE
            FiscalYear := Year;
            FiscalMonth := MonthNo + 9;
        END IF;

        CASE
            WHEN FiscalMonth BETWEEN 1 AND 3 THEN FiscalQuarter := 'Q1';
            WHEN FiscalMonth BETWEEN 4 AND 6 THEN FiscalQuarter := 'Q2';
            WHEN FiscalMonth BETWEEN 7 AND 9 THEN FiscalQuarter := 'Q3';
            ELSE FiscalQuarter := 'Q4';
        END CASE;

        -- Insert Data into Dim_Date
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
            WeekdayInd,
            FiscalYear,
            FiscalQuarter,
            FiscalMonth
        );
        
        EveryDate := EveryDate + 1;
    END LOOP;
END;
/

-- Alter the session to a specific Date Format
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

-- Example Execution of the Procedure
EXEC prc_fiscal_dim_date(TO_DATE('01/05/2024', 'DD/MM/YYYY'), TO_DATE('01/06/2024', 'DD/MM/YYYY'));

-- Check the Dim_Date table
SELECT *
FROM Dim_Date
WHERE CalendarDate BETWEEN TO_DATE('2024-05-01', 'YYYY-MM-DD') AND TO_DATE('2024-06-01', 'YYYY-MM-DD');


-- CUSTOMER DIMENSION ------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE insert_new_customers IS
BEGIN
    INSERT INTO Dim_Customer (
        CustomerKey, 
        CustomerID, 
        CompanyName, 
        ContactName, 
        ContactTitle, 
        City, 
        Region,
        PostalCode,
        Country
    )
    SELECT 
        Cust_Seq.NEXTVAL, 
        UPPER(c.CustomerID),
        UPPER(c.CompanyName), 
        UPPER(c.ContactName),
        UPPER(c.ContactTitle), 
        UPPER(c.City),
        UPPER(c.Region), 
        UPPER(c.PostalCode),
        UPPER(c.Country)
    FROM Customers c
    WHERE c.CustomerID NOT IN (SELECT CustomerID FROM Dim_Customer);
    
    DBMS_OUTPUT.PUT_LINE('New customers have been inserted successfully.');
END;
/

CREATE OR REPLACE PROCEDURE update_customer_scd2 (
    customer_id IN VARCHAR2,
    start_date IN DATE
) IS
    CURSOR cust_cur IS
        SELECT * FROM Dim_Customer
        WHERE CustomerID = customer_id AND EndDate = TO_DATE('31-12-9999', 'DD-MM-YYYY');

    cust_rec cust_cur%ROWTYPE;
BEGIN
    OPEN cust_cur;
    FETCH cust_cur INTO cust_rec;
    IF cust_cur%NOTFOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Customer ID ' || customer_id || ' does not exist or is inactive.');
    ELSE
        -- Mark the existing record as inactive
        UPDATE Dim_Customer
        SET EndDate = start_date - 1,
            CurrentFlag = 'N'
        WHERE CustomerKey = cust_rec.CustomerKey;

        -- Insert new version
        INSERT INTO Dim_Customer (
            CustomerKey, CustomerID, CompanyName, ContactName, ContactTitle, City, Region, PostalCode, Country,
            StartDate, EndDate
        ) VALUES (
            Cust_Seq.NEXTVAL, cust_rec.CustomerID, cust_rec.CompanyName, cust_rec.ContactName, cust_rec.ContactTitle, 
            cust_rec.City, cust_rec.Region, cust_rec.PostalCode, cust_rec.Country,
            start_date, TO_DATE('31-12-9999', 'DD-MM-YYYY')
        );

        DBMS_OUTPUT.PUT_LINE('Customer with ID ' || customer_id || ' has been updated successfully.');
    END IF;
    CLOSE cust_cur;
END;
/

ALTER TABLE Dim_Customer ADD StartDate DATE DEFAULT TRUNC(SYSDATE) NOT NULL;
ALTER TABLE Dim_Customer ADD EndDate DATE DEFAULT TO_DATE('31-12-9999', 'DD-MM-YYYY') NOT NULL;
ALTER TABLE Dim_Customer ADD CurrentFlag CHAR(1) DEFAULT 'Y' NOT NULL;

-- Insert new customers
EXEC insert_new_customers;

-- Update existing customer with ID 'ALFKI' to a new start date
EXEC update_customer_scd2('ALFKI', TO_DATE('01-07-2024', 'DD-MM-YYYY'));

-- Examine the Customer Dimension table
SELECT * FROM Dim_Customer WHERE CustomerID = 'ALFKI';


-- PRODUCT DIMENSION --------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE insert_new_products IS
BEGIN
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
        Discontinued
    )
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
        ON p.CategoryID = c.CategoryID
    WHERE p.ProductID NOT IN (SELECT ProductID FROM Dim_Product);

    DBMS_OUTPUT.PUT_LINE('New products have been inserted successfully.');
END;
/

CREATE OR REPLACE PROCEDURE update_product_scd2 (
    product_id IN NUMBER,
    start_date IN DATE
) IS
    CURSOR prod_cur IS
        SELECT * FROM Dim_Product
        WHERE ProductID = product_id AND EndDate = TO_DATE('31-12-9999', 'DD-MM-YYYY');

    prod_rec prod_cur%ROWTYPE;
BEGIN
    OPEN prod_cur;
    FETCH prod_cur INTO prod_rec;
    IF prod_cur%NOTFOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Product ID ' || product_id || ' does not exist or is inactive.');
    ELSE
        -- Mark the existing record as inactive
        UPDATE Dim_Product
        SET EndDate = start_date - 1,
            CurrentFlag = 'N'
        WHERE ProductKey = prod_rec.ProductKey;

        -- Insert new version
        INSERT INTO Dim_Product (
            ProductKey, ProductID, ProductName, CategoryName, Description, QuantityPerUnit, UnitPrice,
            UnitsInStock, UnitsOnOrder, ReorderLevel, Discontinued, StartDate, EndDate, CurrentFlag
        ) VALUES (
            Prod_Seq.NEXTVAL, prod_rec.ProductID, prod_rec.ProductName, prod_rec.CategoryName, prod_rec.Description, 
            prod_rec.QuantityPerUnit, prod_rec.UnitPrice, prod_rec.UnitsInStock, prod_rec.UnitsOnOrder,
            prod_rec.ReorderLevel, prod_rec.Discontinued, start_date, TO_DATE('31-12-9999', 'DD-MM-YYYY'), 'Y'
        );

        DBMS_OUTPUT.PUT_LINE('Product with ID ' || product_id || ' has been updated successfully.');
    END IF;
    CLOSE prod_cur;
END;
/

ALTER TABLE Dim_Product ADD StartDate DATE DEFAULT TRUNC(SYSDATE) NOT NULL;
ALTER TABLE Dim_Product ADD EndDate DATE DEFAULT TO_DATE('31-12-9999', 'DD-MM-YYYY') NOT NULL;
ALTER TABLE Dim_Product ADD CurrentFlag CHAR(1) DEFAULT 'Y' NOT NULL;

-- Insert new products
EXEC insert_new_products;

-- Update an existing product with ID '1' to a new start date
EXEC update_product_scd2(1, TO_DATE('01-07-2024', 'DD-MM-YYYY'));

-- Examine the Product Dimension table
SELECT * FROM Dim_Product WHERE ProductID = 1;


-- SHIPPER DIMENSION ------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE insert_new_shippers IS
BEGIN
    INSERT INTO Dim_Shipper (
        ShipperKey, 
        ShipperID, 
        CompanyName, 
        Phone
    )
    SELECT 
        Ship_Seq.NEXTVAL, 
        s.ShipperID,
        UPPER(s.CompanyName), 
        UPPER(s.Phone)
    FROM Shippers s
    WHERE s.ShipperID NOT IN (SELECT ShipperID FROM Dim_Shipper);

    DBMS_OUTPUT.PUT_LINE('New shippers have been inserted successfully.');
END;
/

CREATE OR REPLACE PROCEDURE update_shipper_scd2 (
    shipper_id IN NUMBER,
    start_date IN DATE
) IS
    CURSOR ship_cur IS
        SELECT * FROM Dim_Shipper
        WHERE ShipperID = shipper_id AND EndDate = TO_DATE('31-12-9999', 'DD-MM-YYYY');

    ship_rec ship_cur%ROWTYPE;
BEGIN
    OPEN ship_cur;
    FETCH ship_cur INTO ship_rec;
    IF ship_cur%NOTFOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Shipper ID ' || shipper_id || ' does not exist or is inactive.');
    ELSE
        -- Mark the existing record as inactive
        UPDATE Dim_Shipper
        SET EndDate = start_date - 1,
            CurrentFlag = 'N'
        WHERE ShipperKey = ship_rec.ShipperKey;

        -- Insert new version
        INSERT INTO Dim_Shipper (
            ShipperKey, ShipperID, CompanyName, Phone, StartDate, EndDate, CurrentFlag
        ) VALUES (
            Ship_Seq.NEXTVAL, ship_rec.ShipperID, ship_rec.CompanyName, ship_rec.Phone,
            start_date, TO_DATE('31-12-9999', 'DD-MM-YYYY'), 'Y'
        );

        DBMS_OUTPUT.PUT_LINE('Shipper with ID ' || shipper_id || ' has been updated successfully.');
    END IF;
    CLOSE ship_cur;
END;
/

ALTER TABLE Dim_Shipper ADD StartDate DATE DEFAULT TRUNC(SYSDATE) NOT NULL;
ALTER TABLE Dim_Shipper ADD EndDate DATE DEFAULT TO_DATE('31-12-9999', 'DD-MM-YYYY') NOT NULL;
ALTER TABLE Dim_Shipper ADD CurrentFlag CHAR(1) DEFAULT 'Y' NOT NULL;

-- To test
--INSERT INTO Shippers VALUES (4, 'Alliance Shippers', '1-800-222-0451');

-- Insert new shippers
EXEC insert_new_shippers;

-- Update an existing shipper with ID '1' to a new start date
EXEC update_shipper_scd2(1, TO_DATE('01-07-2024', 'DD-MM-YYYY'));

-- Examine the Shipper Dimension table
SELECT * FROM Dim_Shipper WHERE ShipperID = 1;


-- SUPPLIERS DIMENSION ------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE insert_new_suppliers IS
BEGIN
    INSERT INTO Dim_Suppliers (
        SupplierKey, 
        SupplierID, 
        CompanyName, 
        ContactName,
        ContactTitle,
        City,
        Region,
        PostalCode,
        Country
    )
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
    FROM Suppliers su
    WHERE su.SupplierID NOT IN (SELECT SupplierID FROM Dim_Suppliers);

    DBMS_OUTPUT.PUT_LINE('New suppliers have been inserted successfully.');
END;
/

CREATE OR REPLACE PROCEDURE update_supplier_scd2 (
    supplier_id IN NUMBER,
    start_date IN DATE
) IS
    CURSOR supp_cur IS
        SELECT *
        FROM Dim_Suppliers
        WHERE SupplierID = supplier_id AND CurrentFlag = 'Y';

    supp_rec supp_cur%ROWTYPE;
BEGIN
    OPEN supp_cur;
    FETCH supp_cur INTO supp_rec;
    IF supp_cur%NOTFOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Supplier ID ' || supplier_id || ' does not exist or is inactive.');
    ELSE
        -- Mark the existing record as inactive
        UPDATE Dim_Suppliers
        SET EndDate = start_date - 1,
            CurrentFlag = 'N'
        WHERE SupplierKey = supp_rec.SupplierKey;

        -- Insert new version
        INSERT INTO Dim_Suppliers (
            SupplierKey, SupplierID, CompanyName, ContactName, ContactTitle, City, Region, PostalCode, Country,
            StartDate, EndDate, CurrentFlag
        ) VALUES (
            Supp_Seq.NEXTVAL, supp_rec.SupplierID, supp_rec.CompanyName, supp_rec.ContactName, supp_rec.ContactTitle, 
            supp_rec.City, supp_rec.Region, supp_rec.PostalCode, supp_rec.Country,
            start_date, TO_DATE('31-12-9999', 'DD-MM-YYYY'), 'Y'
        );

        DBMS_OUTPUT.PUT_LINE('Supplier with ID ' || supplier_id || ' has been updated successfully.');
    END IF;
    CLOSE supp_cur;
END;
/

ALTER TABLE Dim_Suppliers ADD StartDate DATE DEFAULT TRUNC(SYSDATE) NOT NULL;
ALTER TABLE Dim_Suppliers ADD EndDate DATE DEFAULT TO_DATE('31-12-9999', 'DD-MM-YYYY') NOT NULL;
ALTER TABLE Dim_Suppliers ADD CurrentFlag CHAR(1) DEFAULT 'Y' NOT NULL;

-- Insert new suppliers
EXEC insert_new_suppliers;

-- Update an existing supplier with ID '1' to a new start date
EXEC update_supplier_scd2(1, TO_DATE('01-07-2024', 'DD-MM-YYYY'));

-- Examine the Supplier Dimension table
SELECT * FROM Dim_Suppliers WHERE SupplierID = 1;


-- EMPLOYEES DIMENSION ------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE insert_new_employees IS
BEGIN
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
    FROM Employees e
    WHERE e.EmployeeID NOT IN (SELECT EmployeeID FROM Dim_Employees);

    DBMS_OUTPUT.PUT_LINE('New employees have been inserted successfully.');
END;
/

CREATE OR REPLACE PROCEDURE update_employee_scd2 (
    employee_id IN NUMBER,
    start_date IN DATE
) IS
    CURSOR emp_cur IS
        SELECT *
        FROM Dim_Employees
        WHERE EmployeeID = employee_id AND CurrentFlag = 'Y';

    emp_rec emp_cur%ROWTYPE;
BEGIN
    OPEN emp_cur;
    FETCH emp_cur INTO emp_rec;
    IF emp_cur%NOTFOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Employee ID ' || employee_id || ' does not exist or is inactive.');
    ELSE
        -- Mark the existing record as inactive
        UPDATE Dim_Employees
        SET EndDate = start_date - 1,
            CurrentFlag = 'N'
        WHERE EmployeeKey = emp_rec.EmployeeKey;

        -- Insert new version
        INSERT INTO Dim_Employees (
            EmployeeKey, EmployeeID, FirstName, LastName, Title, BirthDateKey, HireDateKey,
            City, Region, PostalCode, Country, ReportsTo, StartDate, EndDate, CurrentFlag
        ) VALUES (
            Emp_Seq.NEXTVAL, emp_rec.EmployeeID, emp_rec.FirstName, emp_rec.LastName, emp_rec.Title,
            emp_rec.BirthDateKey, emp_rec.HireDateKey, emp_rec.City, emp_rec.Region, emp_rec.PostalCode, 
            emp_rec.Country, emp_rec.ReportsTo, start_date, TO_DATE('31-12-9999', 'DD-MM-YYYY'), 'Y'
        );

        DBMS_OUTPUT.PUT_LINE('Employee with ID ' || employee_id || ' has been updated successfully.');
    END IF;
    CLOSE emp_cur;
END;
/

ALTER TABLE Dim_Employees ADD StartDate DATE DEFAULT TRUNC(SYSDATE) NOT NULL;
ALTER TABLE Dim_Employees ADD EndDate DATE DEFAULT TO_DATE('31-12-9999', 'DD-MM-YYYY') NOT NULL;
ALTER TABLE Dim_Employees ADD CurrentFlag CHAR(1) DEFAULT 'Y' NOT NULL;

-- Insert new employees
EXEC insert_new_employees;

-- Update an existing employee with ID '1' to a new start date
EXEC update_employee_scd2(1, TO_DATE('01-07-2024', 'DD-MM-YYYY'));

-- Examine the Employees Dimension table
SELECT * FROM Dim_Employees WHERE EmployeeID = 1;


-- SALES FACT ---------------------------------------------------------------------------------------------------
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
LEFT JOIN Dim_Employees de ON de.EmployeeID = o.EmployeeID
WHERE dd.CalendarDate > (SELECT MAX(d.CalendarDate)
                         FROM Sales_Fact sf
                         JOIN Dim_Date d ON sf.DateKey = d.DateKey);

-- Examine the Sales Fact table
SELECT * FROM Sales_Fact;

-- Check the number of records
SELECT COUNT(*) FROM Sales_Fact;
