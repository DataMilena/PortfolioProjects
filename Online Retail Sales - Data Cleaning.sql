/*

Cleaning Online Retail Sales Data in SQL Queries 

*/


SELECT * FROM OnlineRetails.dbo.sales

------------------------------------------

--  Standardizing Date Format --

SELECT InvoiceDate, CONVERT(Date, InvoiceDate) AS convertedDate FROM sales

UPDATE sales 
SET InvoiceDate = CONVERT(Date, InvoiceDate)

ALTER TABLE sales 
ALTER COLUMN InvoiceDate DATE

SELECT InvoiceTime, 
CONVERT(TIME, InvoiceTime) AS convertedTime 
FROM sales

UPDATE sales 
SET InvoiceTime = CONVERT(TIME, InvoiceTime)

ALTER TABLE sales 
ALTER COLUMN InvoiceTime TIME 

-- Standardizing format in UnitPrice and Totalsale Column -- 

UPDATE sales
SET UnitPrice = CAST(LTRIM(RTRIM(UnitPrice)) AS DECIMAL(10, 2));

ALTER TABLE sales
ALTER COLUMN UnitPrice DECIMAL(10, 2);

UPDATE sales
SET Totalsale = CAST(LTRIM(RTRIM(Totalsale)) AS DECIMAL(10, 2))

ALTER TABLE sales
ALTER COLUMN Totalsale DECIMAL(10, 2);


-- Removing Special characters from Description column

UPDATE sales 
SET Description = REPLACE(Description, '.', '')
WHERE Description LIKE '%.%'

UPDATE sales
SET Description = REPLACE(REPLACE(Description, '*', ''), '?', '')
WHERE Description LIKE '%*%' OR Description LIKE '%?%'

-- Standardizing descriptions with variations of "missing" and "lost"
UPDATE sales
SET Description = 'Missing'
WHERE Description LIKE '%missing%' OR Description LIKE '%lost%';

-- Replacing empty descriptions with a placeholder
UPDATE sales
SET Description = 'N/A'  
WHERE Description = '';

-- Converting strings to lower-case
UPDATE sales 
SET Description = LOWER(Description)

-- Changing Country Name -- 

SELECT Country from sales
WHERE Country = 'EIRE'

UPDATE sales 
SET Country = 'Ireland' 
WHERE Country = 'EIRE'

-- 
























