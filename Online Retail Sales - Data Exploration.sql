/*
Online Retail Sales Dataset Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views,
Using Parameter 

*/

-- Out of 406.829 rows, there are only 4372 Unique Customers -- 

SELECT COUNT(DISTINCT CustomerID) AS UniqueCustomerCount
FROM sales

-- Filtering out CustomerID and InvoiceNo with NULL values -- 

SELECT *
FROM sales
WHERE CustomerID IS NOT NULL 
AND InvoiceNo IS NOT NULL;

-- Filtering most common purchase country --

SELECT Country, Count(*) AS CountryCount 
FROM sales
WHERE Country <> 'Unspecified'
GROUP BY Country
ORDER BY 2 DESC 

-- Number of Unique Items -- 

SELECT COUNT(DISTINCT StockCode) AS TotalDistinctProducts
FROM sales;

-- Number of Total Sales in 2011 -- 

SELECT SUM(Totalsale) AS TotalSale 
FROM sales
WHERE YEAR(InvoiceDate) = 2011 
AND Totalsale > 0 
AND CustomerID IS NOT NULL 
AND InvoiceNo IS NOT NULL;


-- Calculating the total profit margin for all sales in 2011, avoiding division by zero

SELECT
    SUM(CASE
        WHEN TotalSale = 0 THEN 0  -- Handle the case when TotalSale is zero
        ELSE (TotalSale - (Quantity * UnitPrice)) / TotalSale
    END) AS TotalProfitMargin
FROM sales
WHERE YEAR(InvoiceDate) = 2011
AND Totalsale > 0
AND CustomerID IS NOT NULL 
AND InvoiceNo IS NOT NULL;

SELECT
    *,
    CASE
        WHEN TotalSale = 0 THEN 0  -- Handle the case when TotalSale is zero
        ELSE (TotalSale - (Quantity * UnitPrice)) / TotalSale
    END AS ProfitMargin
FROM sales 
WHERE YEAR(InvoiceDate) = 2011
AND CustomerID IS NOT NULL AND InvoiceNo IS NOT NULL;	

-- Most Commonly Ordered Items -- 

SELECT TOP 10 
Description, COUNT(*) Item_Count
FROM sales
WHERE CustomerID IS NOT NULL 
AND InvoiceNo IS NOT NULL
GROUP BY Description 
ORDER BY 2 DESC 

-- Using CTE and Window Function to combine the top 10 most sold & least sold items -- 

WITH RankedItems AS (
    SELECT
        'Most Sold' AS Ranking,
        Description,
        SUM(Quantity) AS TotalQuantity,
        ROW_NUMBER() OVER (ORDER BY SUM(Quantity) DESC) AS RowNum
    FROM sales
    WHERE CustomerID IS NOT NULL AND InvoiceNo IS NOT NULL
    GROUP BY Description
),
RankedLeastSold AS (
    SELECT
        'Least Sold' AS Ranking,
        Description,
        SUM(Quantity) AS TotalQuantity,
        ROW_NUMBER() OVER (ORDER BY SUM(Quantity)) AS RowNum
    FROM sales
    WHERE CustomerID IS NOT NULL AND InvoiceNo IS NOT NULL
    GROUP BY Description
)
SELECT Ranking, Description, TotalQuantity
FROM RankedItems
WHERE RowNum <= 10
UNION ALL
SELECT Ranking, Description, TotalQuantity
FROM RankedLeastSold
WHERE RowNum <= 10;

-- Creating View: Adding column Date, Year, Season to later filter information -- 

CREATE VIEW SalesSeasonView AS 
SELECT 
InvoiceDate, 
YEAR(InvoiceDate) AS InvoiceYear, 
MONTH(InvoiceDate) AS InvoiceMonth, 
CASE 
WHEN MONTH(InvoiceDate) > 2 AND MONTH(InvoiceDate) <6 THEN 'spring'
WHEN MONTH(InvoiceDate) >= 6 AND MONTH(InvoiceDate) <= 8 THEN 'summer'
WHEN MONTH(InvoiceDate) >= 9 AND MONTH(InvoiceDate) <= 11 THEN 'fall'
ELSE 'winter'
END AS Season 
FROM sales
WHERE CustomerID IS NOT NULL 
AND InvoiceNo IS NOT NULL;

SELECT * FROM SalesSeasonView;

-- Joining SalesSeasonView with sales table to gain insights into sales patterns throughout the year -- 

SELECT
    ss.InvoiceYear,
    ss.Season,
    SUM(s.Quantity) AS TotalSales
FROM SalesSeasonView ss
JOIN sales s 
ON s.InvoiceDate = ss.InvoiceDate
WHERE s.CustomerID IS NOT NULL AND s.InvoiceNo IS NOT NULL
GROUP BY ss.InvoiceYear, ss.Season 
HAVING InvoiceYear = 2011
ORDER BY 3 DESC;

-- Analyzing customer behavior and popular products during different seasons -- 

CREATE VIEW SalesSeasonView2 AS 
SELECT 
InvoiceDate, 
YEAR(InvoiceDate) AS InvoiceYear, 
Month(InvoiceDate) AS InvoiceMonth, 
CASE 
WHEN Month(InvoiceDate) > 2 AND Month(InvoiceDate) <6 THEN 'spring'
WHEN Month(InvoiceDate) >= 6 AND Month(InvoiceDate) <= 8 THEN 'summer'
WHEN Month(InvoiceDate) >= 9 AND Month(InvoiceDate) <= 11 THEN 'fall'
ELSE 'winter'
END AS Season,
Description, 
Quantity
FROM sales
WHERE CustomerID IS NOT NULL AND InvoiceNo IS NOT NULL;

SELECT
    Season,
    InvoiceMonth,
    Description,
    SUM(Quantity) AS TotalQuantity
FROM SalesSeasonView2
WHERE InvoiceYear = 2011
GROUP BY Season, InvoiceMonth, Description
ORDER BY Season, InvoiceMonth, TotalQuantity DESC;


-- Analyzing Customer Behavior: Shopping Hour Distribution

SELECT CONVERT(NVARCHAR(5), InvoiceTime, 108) AS InvoiceTime, 
COUNT(CONVERT(NVARCHAR(5), InvoiceTime, 108)) AS TimeCount
FROM sales 
WHERE CustomerID IS NOT NULL 
AND InvoiceNo IS NOT NULL 
GROUP BY InvoiceTime
ORDER BY 2 DESC

-- Using Temp Table to create customer segments based on purchase history, frequency, and monetary value (RFM segmentation) 

SELECT
    CustomerID,
    CASE
        WHEN DATEDIFF(MONTH, MAX(InvoiceDate), '2011-12-09') = 0
            THEN DATEDIFF(DAY, MAX(InvoiceDate), '2011-12-09') -- This represents how many days ago the customer made their last purchase within the same month
        ELSE DATEDIFF(MONTH, MAX(InvoiceDate), '2011-12-09') 
		* 30 + DATEDIFF(DAY, DATEADD(MONTH, DATEDIFF(MONTH, MAX(InvoiceDate), '2011-12-09'), MAX(InvoiceDate)), '2011-12-09') -- This calculates the remaining days in the month when the last purchase occurred. It adds the number of days from the last purchase to the end of the month in which the reference date falls.
    END AS Recency, -- Recency (how recently a customer made a purchase)
    COUNT(DISTINCT InvoiceNo) AS Frequency, -- Frequency (how often a customer makes a purchase)
    SUM(Totalsale) AS MonetaryValue  -- Monetary Value (how much money a customer has spent)
INTO #RFMValues
FROM sales
WHERE CustomerID IS NOT NULL
AND InvoiceNo IS NOT NULL
GROUP BY CustomerID

SELECT * FROM #RFMValues


SELECT
    CustomerID,
    Recency,
    Frequency,
    MonetaryValue,
    CASE
        WHEN Recency <= 30 AND Frequency >= 5 AND MonetaryValue >= 1000 THEN 'High-Value Customer'
		WHEN Recency >= 30 AND Frequency <= 2 AND MonetaryValue >= 1000 THEN 'High-Value Customer'
        WHEN Recency <= 80 AND Frequency >= 3 AND MonetaryValue >= 500 THEN 'Medium-Value Customer'
		WHEN Recency <= 100 AND Frequency <= 2 AND MonetaryValue >= 500 THEN 'Medium-Value Customer'
		WHEN Recency <= 100 AND Frequency <= 2 AND MonetaryValue <= 300 THEN 'Low-Value Customer'
    ELSE 'Low-Value Customer'
    END AS CustomerSegment
FROM #RFMValues
WHERE MonetaryValue > 0 -- Filtering out zero and negative values
ORDER BY 4 ASC

SELECT
    CustomerID,
    Recency,
    Frequency,
    MonetaryValue,
    CASE
        WHEN MonetaryValue >= 1000 THEN 'High-Spend Customers'
		WHEN MonetaryValue >= 1000 THEN 'High-Spend Customers'
		WHEN MonetaryValue >= 500 THEN 'Medium-Spend Customers'
		WHEN MonetaryValue <= 300 THEN 'Low-Spend Customers'
    ELSE 'Low-Spend Customers'
    END AS CustomerSegment
FROM #RFMValues
WHERE MonetaryValue > 0 -- Filtering out zero and negative values
ORDER BY 4 ASC

-- Using parameter/variable that represents the width or size of the bins to identify the typical recency of customers and whether there are any outliers or patterns in the data

DECLARE @BinWidth INT;
SET @BinWidth = 30;

SELECT
    (Recency / @BinWidth) * @BinWidth AS RecencyBin,
    COUNT(*) AS Count
FROM #RFMValues
GROUP BY (Recency / @BinWidth) * @BinWidth
ORDER BY RecencyBin;












