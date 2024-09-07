--- RFM Analizi
-- Aşağıdaki e_commerce_data_.csv doyasındaki veri setini kullanarak RFM analizi yapınız. 
-- Recency hesaplarken bugünün tarihi değil en son sipariş tarihini baz alınız. 

CREATE TABLE orders (
	InvoiceNO VARCHAR(150),
	StockCode VARCHAR(150),
	Description VARCHAR(150),
	Quantity INTEGER,
	InvoiceDate TIMESTAMP,
	UnitPrice FLOAT,
	CustomerID INTEGER,
	Country VARCHAR(150)
);


COPY orders(InvoiceNO, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country)
FROM '/Applications/PostgreSQL 15/data.csv' CSV DELIMITER ',' HEADER ENCODING 'windows-1251';


SELECT *
FROM orders

-- Are there any NULL values in customerid?

SELECT COUNT(*)
FROM orders
WHERE customerid IS NULL --- There are 135080 values in customerid
----

-- Are there any strange quantities?

SELECT COUNT(*)
FROM orders
WHERE quantity <= 0 --- 10624 out of 541909 orders are negative !

-- Are there any strange values in unitprice?

SELECT COUNT(*)
FROM orders
WHERE unitprice = 0 -- 2525 unit values are 0

----- recency analysis

SELECT MAX(invoicedate::date)
FROM orders
WHERE customerid IS NOT NULL AND
		quantity > 0 AND
		unitprice > 0


WITH recency AS (

--- find each customer's most recent order date
	WITH cte_2 AS (

--- create a column for the reference date 
	WITH cte AS (
	SELECT customerid,
	invoicedate::date,
	MAX(invoicedate::date) OVER () AS new_date
FROM orders
WHERE customerid IS NOT NULL AND
		quantity > 0 AND
		unitprice > 0
	)
	
SELECT customerid,
	new_date - invoicedate AS last_order,
	DENSE_RANK() OVER (PARTITION BY customerid ORDER BY new_date - invoicedate) AS customer_recency_rank
FROM cte
GROUP BY 1, 2
ORDER BY customerid
	)
	
SELECT customerid,
	last_order,
	DENSE_RANK() OVER (ORDER BY last_order) AS recency_rank
FROM cte_2
WHERE customer_recency_rank = 1
	)

----- monetary analysis

WITH monetary AS (
	
--- we use total_spendings to rank the customers

	WITH cte_2 AS (

--- we calculate total_spendigs based on quantity and unitprice
	WITH cte AS (
	SELECT customerid,
	invoiceno,
	quantity,
	unitprice,
	quantity * unitprice AS total_spending
FROM orders
WHERE customerid IS NOT NULL AND
	quantity > 0 AND
	unitprice > 0
ORDER BY 5
	)

SELECT customerid,
	ROUND(SUM(total_spending)::integer, 2) AS total_spendings
FROM cte
GROUP BY customerid
ORDER BY 2
	)
	
SELECT customerid,
	total_spendings,
	DENSE_RANK() OVER (ORDER BY total_spendings DESC) AS monetary_rank
FROM cte_2
	)
	
---- frequency analysis
WITH cte AS (
	SELECT customerid,
	COUNT(DISTINCT invoiceno) AS order_count
FROM orders
WHERE customerid IS NOT NULL AND
		quantity > 0 AND
		unitprice > 0
GROUP BY customerid
ORDER BY order_count DESC

	)
	
SELECT customerid,
	order_count,
	DENSE_RANK() OVER (ORDER BY order_count DESC) AS frequency_rank
FROM cte
ORDER BY order_count DESC

-------------



--- rfm_table
CREATE TABLE rfm_table AS (
	WITH monetary AS (
	WITH cte_2 AS (
	WITH cte AS (
	SELECT customerid,
	invoiceno,
	quantity,
	unitprice,
	quantity * unitprice AS total_spending
FROM orders
WHERE customerid IS NOT NULL AND
	quantity > 0 AND
	unitprice > 0
	)

SELECT customerid,
	ROUND(SUM(total_spending)::integer, 2) AS total_spendings
FROM cte
GROUP BY customerid
ORDER BY 2 DESC
	)
	
SELECT customerid,
	total_spendings,
	DENSE_RANK() OVER (ORDER BY total_spendings DESC) AS monetary_rank
FROM cte_2
	),

--- recency

recency AS (
	WITH cte_2 AS (
	WITH cte AS (
	SELECT customerid,
	invoicedate::date,
	MAX(invoicedate::date) OVER () as new_date
FROM orders
WHERE customerid IS NOT NULL AND
	quantity > 0 AND
	unitprice > 0
	)
	
SELECT customerid,
	new_date - invoicedate AS last_order,
	DENSE_RANK() OVER (PARTITION BY customerid ORDER BY new_date - invoicedate) AS customer_recency_rank
FROM cte
GROUP BY 1, 2
ORDER BY customerid
	)
	
SELECT customerid,
	last_order,
	DENSE_RANK() OVER (ORDER BY last_order) AS recency_rank
FROM cte_2
WHERE customer_recency_rank = 1
	),

--- frequency
frequency AS (
	WITH cte AS (
	SELECT customerid,
	COUNT(DISTINCT invoiceno) AS order_count
FROM orders
WHERE customerid IS NOT NULL AND
	quantity > 0 AND
	unitprice > 0
GROUP BY customerid
	)
	
SELECT customerid,
	order_count,
	DENSE_RANK() OVER (ORDER BY order_count DESC) AS frequency_rank
FROM cte
ORDER BY order_count DESC)

SELECT frequency.customerid, order_count, frequency_rank, last_order, recency_rank, total_spendings, monetary_rank
FROM frequency
LEFT JOIN recency
ON frequency.customerid = recency.customerid
LEFT JOIN monetary
ON frequency.customerid = monetary.customerid
	)
	
--- investigate rfm_table

SELECT *
FROM rfm_table
	
--- frequency_monetary rank

WITH freq_mon AS (
	WITH cte AS (
	SELECT customerid, frequency_rank, monetary_rank,
	DENSE_RANK() OVER (ORDER BY frequency_rank, monetary_rank) AS frequency_monetary_score
FROM rfm_table
ORDER BY frequency_rank, monetary_rank
	)
	
SELECT customerid, frequency_rank, monetary_rank,
	NTILE(3) OVER (ORDER BY frequency_monetary_score) AS frequency_monetary_ntile
FROM cte),

--- recency ranking

rec AS (
	SELECT customerid,
	last_order,
	recency_rank,
	NTILE(3) OVER (ORDER BY recency_rank) AS recency_ntile 
FROM rfm_table
ORDER BY last_order
	)
	
SELECT freq_mon.customerid, 
	frequency_monetary_ntile, 
	recency_ntile,
	CASE
	WHEN frequency_monetary_ntile = 1 AND recency_ntile = 1 THEN 'champions'
	WHEN frequency_monetary_ntile = 1 AND recency_ntile = 2 THEN 'loyal customers'
	WHEN frequency_monetary_ntile = 1 AND recency_ntile = 3 THEN 'Cant lose them'
	WHEN frequency_monetary_ntile = 2 AND recency_ntile = 1 THEN 'potential loyalist'
	WHEN frequency_monetary_ntile = 2 AND recency_ntile = 2 THEN 'needs attention'
	WHEN frequency_monetary_ntile = 2 AND recency_ntile = 3 THEN 'hibernating'
	WHEN frequency_monetary_ntile = 3 AND recency_ntile = 1 THEN 'price sensitive/promising'
	WHEN frequency_monetary_ntile = 3 AND recency_ntile = 2 THEN 'about to sleep'
	WHEN frequency_monetary_ntile = 3 AND recency_ntile = 3 THEN 'lost'
	END AS predictive_segment	
FROM freq_mon
LEFT JOIN rec
ON freq_mon.customerid = rec.customerid;

