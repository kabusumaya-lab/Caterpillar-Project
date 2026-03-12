SELECT 
	TABLE_NAME, 
	TABLE_SCHEMA,
	TABLE_TYPE
FROM
	INFORMATION_SCHEMA.TABLES
WHERE
	TABLE_TYPE = 'BASE TABLE'

SELECT TOP 100* FROM Sales$;
SELECT TOP 100* FROM Stores$;
SELECT TOP 100* FROM Products$;
SELECT TOP 100* FROM ProductCategory$;
SELECT TOP 100* FROM ProductSubcategory$;
SELECT TOP 100* FROM Customers$;
SELECT TOP 100* FROM Calendar$;
SELECT TOP 100* FROM Channel$;

SELECT
	Invoice,
	ProductKey,
	COUNT(*) AS Unique_Count
FROM
	Sales$
GROUP BY
	Invoice,
	ProductKey
HAVING
	COUNT(*) > 1;


SELECT 
	c.YearMonth AS Months,
	ROUND(SUM(s.Revenue),2) AS TotalRevenue
FROM
	Sales$ s JOIN Calendar$ c
ON
	s.TransactionDate = c.Date
GROUP BY
	c.YearMonth
HAVING
	SUM(s.Revenue) > 50000000
ORDER BY
	TotalRevenue DESC;

SELECT TOP 10
	c.CustomerKey AS Customer_Key,
	c.CustomerName AS Customer_Name,
	c.Country,
	ROUND(SUM(s.Revenue),2) as MoneySpent
FROM
	Sales$ s JOIN Customers$ c
ON
	s.CustomerKey = c.CustomerKey
GROUP BY
	c.CustomerKey,
	c.CustomerName,
	c.Country
ORDER BY
	MoneySpent DESC;


SELECT TOP 10
	st.StoreID AS Stores,
	ROUND(SUM(s.Revenue),2) AS StoreSales
FROM
	Sales$ s JOIN Stores$ st
ON
	s.StoreID = st.StoreID
WHERE
	YEAR(s.TransactionDate) = 2006
GROUP BY
	st.StoreID
ORDER BY
	StoreSales DESC;

SELECT TOP 10
	st.StoreID AS Stores,
	ROUND(SUM(s.Revenue),2) AS StoreSales
FROM
	Sales$ s JOIN Stores$ st
ON
	s.StoreID = st.StoreID
WHERE
	YEAR(s.TransactionDate) = 2007
GROUP BY
	st.StoreID
ORDER BY
	StoreSales DESC;

SELECT
	Stores
FROM (
SELECT TOP 10
	st.StoreID AS Stores,
	ROUND(SUM(s.Revenue),2) AS StoreSales
FROM
	Sales$ s JOIN Stores$ st
ON
	s.StoreID = st.StoreID
WHERE
	YEAR(s.TransactionDate) = 2006
GROUP BY
	st.StoreID
ORDER BY
	StoreSales DESC
	) 
AS TopStores2006

INTERSECT

SELECT
	Stores 
FROM (
SELECT TOP 10
	st.StoreID AS Stores,
	ROUND(SUM(s.Revenue),2) AS StoreSales
FROM
	Sales$ s JOIN Stores$ st
ON
	s.StoreID = st.StoreID
WHERE
	YEAR(s.TransactionDate) = 2007
GROUP BY
	st.StoreID
ORDER BY
	StoreSales DESC
	) 
AS TopStores2007;


WITH TOP2006 AS(
SELECT TOP 10
	st.StoreID AS Stores,
	ROUND(SUM(s.Revenue),2) AS StoreSales_2006
FROM
	Sales$ s JOIN Stores$ st
ON
	s.StoreID = st.StoreID
WHERE
	YEAR(s.TransactionDate) = 2006
GROUP BY
	st.StoreID
ORDER BY
	StoreSales_2006 DESC
),
TOP2007 AS (
SELECT TOP 10
	st.StoreID AS Stores,
	ROUND(SUM(s.Revenue),2) AS StoreSales_2007
FROM
	Sales$ s JOIN Stores$ st
ON
	s.StoreID = st.StoreID
WHERE
	YEAR(s.TransactionDate) = 2007
GROUP BY
	st.StoreID
ORDER BY
	StoreSales_2007 DESC)

SELECT
	a.Stores,
	a.StoreSales_2006,
	b.StoreSales_2007
FROM
	TOP2006 a JOIN TOP2007 b
ON
	a.Stores= b.Stores;


SELECT TOP 1
	p.ProductKey,
	p.ProductDescription AS Product_Name,
	c.Country,
	ROUND(COUNT(s.Revenue),2) AS Product_Sales
FROM
	Sales$ s JOIN Products$ p
ON
	s.ProductKey = p.ProductKey
JOIN
	Customers$ c
ON
	s.CustomerKey = c.CustomerKey
WHERE
	c.Country = 'US'
GROUP BY
	p.ProductKey,
	p.ProductDescription,
	c.Country
ORDER BY
	Product_Sales DESC;

WITH ProductDetails AS (
SELECT TOP 1
	p.ProductKey,
	c.Country,
	ROUND(COUNT(s.Revenue),2) AS Product_Sales
FROM
	Sales$ s JOIN Products$ p
ON
	s.ProductKey = p.ProductKey
JOIN
	Customers$ c
ON
	s.CustomerKey = c.CustomerKey
WHERE
	c.Country = 'US'
GROUP BY
	p.ProductKey,
	c.Country
ORDER BY
	Product_Sales DESC
	)

SELECT
	p.*,
	pd.Product_Sales
FROM
	ProductDetails pd JOIN Products$ p
ON
	pd.ProductKey = p.ProductKey;


SELECT TOP 1 
	ch.ChannelKey,
	ch.Channel,
	ROUND(SUM(s.Revenue),2) AS ChannelSales
FROM
	Channel$ ch JOIN Sales$ s
ON
	ch.ChannelKey = s.ChannelKey
GROUP BY
	ch.ChannelKey,
	ch.Channel
ORDER BY
	ChannelSales DESC;


WITH 
	MaxYearCTE AS (
SELECT
	MAX(YEAR(TransactionDate)) AS MaxYear
FROM
	Sales$
)

SELECT TOP 1 
	YEAR(s.TransactionDate) AS Year,
	ch.ChannelKey,
	ch.Channel,
	ROUND(SUM(s.Revenue),2) AS ChannelSales
FROM
	Channel$ ch JOIN Sales$ s
ON
	ch.ChannelKey = s.ChannelKey
CROSS JOIN 
	MaxYearCTE my
WHERE
	YEAR(s.TransactionDate) BETWEEN
	my.MaxYear - 4 AND my.MaxYear
GROUP BY
	ch.ChannelKey,
	ch.Channel,
	YEAR(s.TransactionDate)
ORDER BY
	ChannelSales DESC;


WITH
	MaxYearProfit AS (
SELECT
	YEAR(TransactionDate) AS Profit_Year,
	ROUND(SUM((Revenue - Cost) * Qty),2) AS Year_Profit
FROM 
	Sales$
GROUP BY
	YEAR(TransactionDate)
),
MaxProductProfit AS (
SELECT TOP 1
	p.ProductKey,
	p.ProductDescription AS Product_Name,
	ROUND(SUM((s.Revenue - s.Cost) * s.Qty),2) AS Product_Profit
FROM
	Sales$ s JOIN Products$ p
ON
	s.ProductKey = p.ProductKey
CROSS JOIN 
	MaxYearProfit myp
WHERE 
	YEAR(s.TransactionDate) = myp.Profit_Year
GROUP BY
	p.ProductKey,
	p.ProductDescription 
ORDER BY
	Product_Profit DESC
	)

SELECT TOP 1
	a.Profit_Year,
	b.ProductKey,
	b.Product_Name,
	a.Year_Profit,
	b.Product_Profit
FROM
	MaxYearProfit a CROSS JOIN MaxProductProfit b;


WITH YearlySpendingCountry AS (
SELECT 
	YEAR(s.TransactionDate) AS YearlySpending,
	c.Country,
	SUM(s.Revenue) AS CountrySpending
FROM
	Sales$ s JOIN Customers$ c
ON
	s.CustomerKey = c.CustomerKey
GROUP BY
	YEAR(s.TransactionDate),
	c.Country
),
Ranked AS (
SELECT
	Country,
	YearlySpending,
	CountrySpending,
	ROW_NUMBER() OVER (
	PARTITION BY Country
	ORDER BY CountrySpending DESC
	) AS RankedCountry
FROM
	YearlySpendingCountry
)

SELECT
	Country,
	YearlySpending,
	CountrySpending
FROM
	Ranked
WHERE
	RankedCountry = 1
ORDER BY
	CountrySpending DESC;


SELECT TOP 10
	EmpKey,
	COUNT(DISTINCT(Invoice)) AS Count_Orders
FROM
	Sales$
WHERE
	YEAR(TransactionDate) = 2011
GROUP BY
	EmpKey
ORDER BY
	Count_Orders DESC;

SELECT
	EmpKey,
	ROUND(SUM(Revenue),2) as Total_Revenue_Generated
FROM
	Sales$ 
GROUP BY
	EmpKey
ORDER BY
	Total_Revenue_Generated DESC;


SELECT
	pc.CategoryKey AS Category_Key,
	pc.CategoryName AS Category_Name,
	ROUND(SUM((s.Revenue - S.Cost) * s.Qty),2) as TotalProfit
FROM
	Sales$ s JOIN Products$ p
ON
	s.ProductKey = p.ProductKey
JOIN
	ProductSubcategory$ psc
ON
	p.SubCategoryKey = psc.SubCategoryKey
JOIN 
	ProductCategory$ pc
ON
	psc.CategoryKey = pc.CategoryKey
GROUP BY
	pc.CategoryKey,
	pc.CategoryName
ORDER BY
	TotalProfit DESC;