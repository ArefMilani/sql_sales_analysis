CREATE TABLE customers (
	customer_id VARCHAR(150) PRIMARY KEY,
	customer_unique_id VARCHAR(150),
	customer_zip_code_prefix integer,
	customer_city VARCHAR(150),
	customer_state VARCHAR(150)
);

SELECT *
FROM customers
LIMIT 20;

COPY customers(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
FROM '/Applications/PostgreSQL 15/olist_customers_dataset.csv' CSV DELIMITER ',' HEADER


CREATE TABLE orderitems (
	order_id VARCHAR(150),
	order_item_id INTEGER,
	product_id VARCHAR(150),
	seller_id VARCHAR(150),
	shipping_limit_date TIMESTAMP,
	price FLOAT,
	freight_value FLOAT
);

ALTER TABLE orderitems
ADD CONSTRAINT pk_order_item_id
PRIMARY KEY (order_item_id);

ALTER TABLE orderitems
ADD CONSTRAINT fk_order_id
FOREIGN KEY (order_id) REFERENCES orders(order_id);

ALTER TABLE orderitems
ADD CONSTRAINT fk_seller_id
FOREIGN KEY(seller_id) REFERENCES sellers(seller_id);


COPY orderitems(order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value)
FROM '/Applications/PostgreSQL 15/olist_order_items_dataset.csv' CSV DELIMITER ',' HEADER;

SELECT *
FROM orderitems
LIMIT 20;

CREATE TABLE orderpayments (
	order_id VARCHAR(150),
	payment_sequential INTEGER,
	payment_type VARCHAR(150),
	payment_installments INTEGER,
	payment_value FLOAT
);


COPY orderpayments(order_id, payment_sequential, payment_type, payment_installments, payment_value)
FROM '/Applications/PostgreSQL 15/olist_order_payments_dataset.csv' CSV DELIMITER ',' HEADER;

ALTER TABLE orderpayments
ADD CONSTRAINT fk_order_id
FOREIGN KEY (order_id) REFERENCES orders(order_id);

SELECT COUNT(DISTINCT order_id)
FROM orderpayments

SELECT order_id,
	COUNT(*)
FROM orderpayments
GROUP BY 1
ORDER BY 2 DESC

SELECT *
FROM orderpayments
WHERE order_id = 'fa65dad1b0e818e3ccc5cb0e39231352'

CREATE TABLE orderreviews (
	review_id VARCHAR(150),
	order_id VARCHAR(150),
	review_score INTEGER,
	review_comment_title VARCHAR(150),
	review_comment_message VARCHAR(500),
	review_creation_date TIMESTAMP,
	review_answer_stamp TIMESTAMP
);



COPY orderreviews(review_id, order_id, review_score, review_comment_title, review_comment_message, review_creation_date, review_answer_stamp)
FROM '/Applications/PostgreSQL 15/olist_order_reviews_dataset.csv' CSV DELIMITER ',' HEADER;

SELECT *
FROM orderreviews
LIMIT 10;

ALTER TABLE reviews
ADD CONSTRAINT pk_review_id
PRIMARY KEY(review_id)


SELECT review_id
FROM orderreviews
GROUP BY 1
HAVING COUNT(*) > 1

SELECT order_id
FROM orderreviews
GROUP BY 1
HAVING COUNT(*) > 1


ALTER TABLE orderreviews
ADD CONSTRAINT fk_order_id
FOREIGN KEY (order_id) REFERENCES orders(order_id);

CREATE TABLE orders (
	order_id VARCHAR(150),
	customer_id VARCHAR(150),
	order_status VARCHAR(150),
	order_purchase_timestamp TIMESTAMP,
	order_approved_at TIMESTAMP,
	order_delivered_carrier_date TIMESTAMP,
	order_delivered_customer_date TIMESTAMP,
	order_estimated_delivery_date TIMESTAMP
);



COPY orders(order_id, customer_id, order_status, order_purchase_timestamp, order_approved_at, order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date)
FROM '/Applications/PostgreSQL 15/olist_orders_dataset.csv' CSV DELIMITER ',' HEADER;

SELECT *
FROM orders
LIMIT 20;

ALTER TABLE orders
ADD CONSTRAINT fk_customer_id
FOREIGN KEY (customer_id) REFERENCES customers(customer_id);

CREATE TABLE products (
	product_id VARCHAR(150) PRIMARY KEY,
	product_category_name VARCHAR(150),
	product_name_length INTEGER,
	product_description_length INTEGER,
	products_photos_qty INTEGER,
	product_weight_g INTEGER,
	product_length_cm INTEGER,
	product_heigth_cm INTEGER,
	product_width_cm INTEGER
)

COPY products(product_id, product_category_name, product_name_length, product_description_length, products_photos_qty, product_weight_g,
			 product_length_cm, product_heigth_cm, product_width_cm)
FROM '/Applications/PostgreSQL 15/olist_products_dataset.csv' CSV DELIMITER ',' HEADER;



SELECT *
FROM products
LIMIT 20;

SELECT *
FROM products
WHERE product_category_name IS NULL

CREATE TABLE sellers (
	seller_id VARCHAR(150) PRIMARY KEY,
	seller_zip_code_prefix INTEGER,
	seller_city VARCHAR(150),
	seller_state VARCHAR(150)
);

COPY sellers(seller_id, seller_zip_code_prefix, seller_city, seller_state)
FROM '/Applications/PostgreSQL 15/olist_sellers_dataset.csv' CSV DELIMITER ',' HEADER;

SELECT *
FROM sellers
LIMIT 20;



CREATE TABLE categories (
	product_category_name VARCHAR(150),
	product_category_name_english VARCHAR(150)
);

COPY categories(product_category_name, product_category_name_english)
FROM '/Applications/PostgreSQL 15/product_category_name_translation.csv' CSV DELIMITER ',' HEADER;

SELECT *
FROM categories
LIMIT 20;

ALTER TABLE categories
ADD CONSTRAINT pk_product_category_name
PRIMARY KEY(product_category_name)

ALTER TABLE products
ADD CONSTRAINT fk_product_category_name
FOREIGN KEY (product_category_name) REFERENCES categories(product_category_name);

SELECT *
FROM products
WHERE product_category_name IS NULL

SELECT *
FROM categories
WHERE product_category_name IS NULL


--- Sipariş Analizi
-- Aylık olarak order dağılımını inceleyiniz. Tarih verisi için order_approved_at kullanılmalıdır.

SELECT DATE_TRUNC('month', order_approved_at)::date,
	COUNT(order_id)
FROM orders
WHERE order_approved_at::date IS NOT NULL
GROUP BY 1
ORDER BY 1;



-- Aylık olarak order status kırılımında order sayılarını inceleyiniz.
-- Sorgu sonucunda çıkan outputu excel ile görselleştiriniz.
-- Dramatik bir düşüşün ya da yükselişin olduğu aylar var mı?
-- Veriyi inceleyerek yorumlayınız.

SELECT DATE_TRUNC('month', order_approved_at)::date, order_status,
	COUNT(*)
FROM orders
WHERE order_status IS NOT NULL AND 
	order_approved_at IS NOT NULL
GROUP BY 1, 2
ORDER BY 1, 2;

-- Ürün kategorisi kırılımında sipariş sayılarını inceleyiniz.
-- Özel günlerde öne çıkan kategoriler nelerdir? 
-- Örneğin yılbaşı, sevgililer günü…

SELECT DISTINCT product_category_name
FROM products
WHERE product_category_name IS NULL; -- there is null value in product_category_name

SELECT product_category_name,
	COUNT(DISTINCT orders.order_id)
FROM orders
LEFT JOIN orderitems
ON orders.order_id = orderitems.order_id
LEFT JOIN products
ON orderitems.product_id = products.product_id
WHERE product_category_name IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC
LIMIT 20;     -- there is a null cateogy with 2378 orders

-- valentine analysis
SELECT product_category_name,
	COUNT(DISTINCT orders.order_id)
FROM orders
LEFT JOIN orderitems
ON orders.order_id = orderitems.order_id
LEFT JOIN products
ON orderitems.product_id = products.product_id
WHERE product_category_name IS NOT NULL AND
	EXTRACT(DAY FROM order_approved_at::date) = 14 AND
	EXTRACT(MONTH FROM order_approved_at::date) = 2
GROUP BY 1
ORDER BY 2 DESC;

-- new year analysis
SELECT product_category_name,
	COUNT(DISTINCT orders.order_id)
FROM orders
LEFT JOIN orderitems
ON orders.order_id = orderitems.order_id
LEFT JOIN products
ON orderitems.product_id = products.product_id
WHERE EXTRACT(DAY FROM order_approved_at::date) = 1 AND
	EXTRACT(MONTH FROM order_approved_at::date) = 1
GROUP BY 1
ORDER BY 2 DESC
LIMIT 20;


-- Haftanın günleri(pazartesi, perşembe, ….) ve ay günleri (ayın 1’i,2’si gibi) bazında order sayılarını inceleyiniz.
-- Yazdığınız sorgunun outputu ile excel’de bir görsel oluşturup yorumlayınız.


SELECT TO_CHAR(order_approved_at::date, 'DD'),
	COUNT(order_id)
FROM orders
WHERE order_approved_at IS NOT NULL
GROUP BY 1;

SELECT  TO_CHAR(order_approved_at::date, 'Day'),
	COUNT(order_id)
FROM orders
WHERE order_approved_at IS NOT NULL
GROUP BY 1;

--- Müşteri Analizi
-- Hangi şehirlerdeki müşteriler daha çok alışveriş yapıyor?

SELECT customer_city,
	COUNT(DISTINCT order_id)
FROM orders
LEFT JOIN customers
ON customers.customer_id = orders.customer_id
WHERE order_status = 'delivered' AND
	customer_city IS NOT NULL
GROUP BY customer_city
ORDER BY COUNT(order_id) DESC;

-- Müşterinin şehrini en çok sipariş verdiği şehir olarak belirleyip analizi ona göre yapınız.
-- Sibel Çanakkale’den 3, Muğla’dan 8 ve İstanbul’dan 10 sipariş olmak üzere 3 farklı şehirden sipariş veriyor. 
-- Sibel’in şehrini en çok sipariş verdiği şehir olan İstanbul olarak seçmelisiniz ve Sibel’in yaptığı siparişleri İstanbul’dan 21 sipariş vermiş şekilde görünmelidir.

WITH cte_2 AS (
	WITH cte AS (
	SELECT  customers.customer_id,
	customer_city,
	COUNT(DISTINCT orders.order_id)
FROM customers
LEFT JOIN orders
ON customers.customer_id = orders.customer_id
WHERE order_status = 'delivered'
GROUP BY 1, 2
ORDER BY 3 DESC)

SELECT customer_id,
	customer_city,
	ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY count DESC) AS count_by_city_rank
FROM cte
	)

SELECT customer_id,
	customer_city
FROM cte_2
WHERE count_by_city_rank = 1;


--- Satıcı Analizi
-- Siparişleri en hızlı şekilde müşterilere ulaştıran satıcılar kimlerdir? Top 5 getirin.

SELECT DISTINCT orderitems.order_id,
	seller_id,
	order_approved_at::date,
	order_delivered_carrier_date::date,
	AGE(order_delivered_carrier_date::date, order_approved_at::date)
FROM orders
LEFT JOIN orderitems
ON orderitems.order_id = orders.order_id
WHERE AGE(order_delivered_carrier_date::date, order_approved_at::date) >= interval '0 days'
ORDER BY age;


---
--- fastest for seller date

SELECT seller_id,
	AVG(AGE(order_delivered_carrier_date::date, order_approved_at::date)) AS avg_delivery_time
FROM orderitems
LEFT JOIN orders
ON orderitems.order_id = orders.order_id
WHERE order_status = 'delivered' AND
	AGE(order_delivered_carrier_date::date, order_approved_at::date) >= interval '0 days'
GROUP BY seller_id
HAVING COUNT(DISTINCT orders.order_id) > (
	WITH cte AS (
	SELECT DISTINCT seller_id,
	COUNT(DISTINCT orders.order_id) AS seller_order_count
	FROM orders
	LEFT JOIN orderitems
	ON orderitems.order_id = orders.order_id
	WHERE order_status = 'delivered'
	GROUP BY 1
	)

	SELECT ROUND(AVG(seller_order_count), 2) avg_order_count
	FROM cte
)
ORDER BY avg_delivery_time
LIMIT 5;


-- Bu satıcıların order sayıları ile ürünlerindeki yorumlar ve puanlamaları inceleyiniz ve yorumlayınız.

--- review points
WITH cte_2 AS (
	WITH cte AS (
	SELECT seller_id,
	AVG(AGE(order_delivered_carrier_date::date, order_approved_at::date)) AS avg_delivery_time
FROM orderitems
LEFT JOIN orders
ON orderitems.order_id = orders.order_id
WHERE order_status = 'delivered' AND
	AGE(order_delivered_carrier_date::date, order_approved_at::date) >= interval '0 days'
GROUP BY seller_id
HAVING COUNT(DISTINCT orders.order_id) > (
	WITH cte_0 AS (
	SELECT DISTINCT seller_id,
	COUNT(DISTINCT orders.order_id) AS seller_order_count
	FROM orders
	LEFT JOIN orderitems
	ON orderitems.order_id = orders.order_id
	WHERE order_status = 'delivered'
	GROUP BY 1
	)

	SELECT ROUND(AVG(seller_order_count), 2) avg_order_count
	FROM cte_0
)
		
ORDER BY avg_delivery_time
LIMIT 5
		
	)

SELECT seller_id, 
	 orderitems.order_id
FROM orderitems
LEFT JOIN orders
ON orderitems.order_id = orders.order_id
WHERE order_status = 'delivered' AND
	AGE(order_delivered_carrier_date::date, order_approved_at::date) >= interval '0 days' AND
	seller_id IN (
		SELECT seller_id
		FROM cte
	)
	)

SELECT seller_id,
	ROUND(AVG(review_score), 2) AS review_avg,
	MIN(review_score) AS review_min,
	MAX(review_score) AS review_max,
	COUNT(DISTINCT cte_2.order_id) AS order_count
FROM cte_2
LEFT JOIN orderreviews
ON cte_2.order_id = orderreviews.order_id
GROUP BY seller_id
ORDER BY review_avg DESC;

--- reviews
WITH cte_2 AS (
	WITH cte AS (
	SELECT seller_id,
	AVG(AGE(order_delivered_carrier_date::date, order_approved_at::date)) AS avg_delivery_time
FROM orderitems
LEFT JOIN orders
ON orderitems.order_id = orders.order_id
WHERE order_status = 'delivered' AND
	AGE(order_delivered_carrier_date::date, order_approved_at::date) >= interval '0 days'
GROUP BY seller_id
HAVING COUNT(DISTINCT orders.order_id) > (
	WITH cte_0 AS (
	SELECT DISTINCT seller_id,
	COUNT(DISTINCT orders.order_id) AS seller_order_count
	FROM orders
	LEFT JOIN orderitems
	ON orderitems.order_id = orders.order_id
	WHERE order_status = 'delivered'
	GROUP BY 1
	)

	SELECT ROUND(AVG(seller_order_count), 2) avg_order_count
	FROM cte_0
)
		
ORDER BY avg_delivery_time
LIMIT 5
		
	)

SELECT seller_id, 
	 orderitems.order_id
FROM orderitems
LEFT JOIN orders
ON orderitems.order_id = orders.order_id
WHERE order_status = 'delivered' AND
	AGE(order_delivered_carrier_date::date, order_approved_at::date) >= interval '0 days' AND
	seller_id IN (
		SELECT seller_id
		FROM cte
	)
	)

SELECT seller_id,
	review_comment_title,
	review_comment_message
FROM cte_2
LEFT JOIN orderreviews
ON cte_2.order_id = orderreviews.order_id
ORDER BY 1;


----- 

WITH cte_2 AS (
	WITH cte AS (
	SELECT seller_id, 
	COUNT(DISTINCT orderitems.order_id) AS order_count
FROM orderitems
LEFT JOIN orders
ON orderitems.order_id = orders.order_id
WHERE order_status = 'delivered' AND
	AGE(order_delivered_carrier_date::date, order_approved_at::date) >= interval '0 days'
GROUP BY seller_id
ORDER BY order_count DESC
	)

SELECT seller_id, 
	 orderitems.order_id
FROM orderitems
LEFT JOIN orders
ON orderitems.order_id = orders.order_id
WHERE order_status = 'delivered' AND
	AGE(order_delivered_carrier_date::date, order_approved_at::date) >= interval '0 days' AND
	seller_id IN (
		SELECT seller_id
		FROM cte
	)
	)
	

SELECT seller_id,
	ROUND(AVG(review_score), 2) AS review_avg,
	MAX(review_score) AS max_score,
	MIN(review_score) AS min_score,
	COUNT(DISTINCT cte_2.order_id) AS order_count
FROM cte_2
LEFT JOIN orderreviews
ON cte_2.order_id = orderreviews.order_id
WHERE review_score IS NOT NULL
GROUP BY seller_id
ORDER BY 5 DESC;


-- Hangi satıcılar daha fazla kategoriye ait ürün satışı yapmaktadır? 

WITH cte AS (
	SELECT product_id,
	products.product_category_name,
	product_category_name_english
FROM products
LEFT JOIN categories
ON products.product_category_name = categories.product_category_name
WHERE products.product_category_name IS NOT NULL
	)


SELECT seller_id,
	COUNT(DISTINCT product_category_name_english) AS category_count,
	COUNT(DISTINCT order_id) AS order_count
FROM orderitems
LEFT JOIN cte
ON orderitems.product_id = cte.product_id
GROUP BY seller_id
ORDER BY category_count DESC;


-- Fazla kategoriye sahip satıcıların order sayıları da fazla mı?

SELECT seller_id,
	COUNT(DISTINCT product_category_name) AS category_count,
	COUNT(DISTINCT order_id) AS order_count
FROM orderitems
LEFT JOIN products
ON orderitems.product_id = products.product_id
GROUP BY seller_id
ORDER BY order_count DESC;


--- Payment Analizi
-- Ödeme yaparken taksit sayısı fazla olan kullanıcılar en çok hangi bölgede yaşamaktadır? Bu çıktıyı yorumlayınız.

WITH cte_3 AS (
	WITH cte_2 AS (
	WITH cte_1 AS(
SELECT orderpayments.payment_installments,
customers.customer_state,
COUNT(DISTINCT customers.customer_id) AS count
FROM orders
LEFT JOIN customers
ON orders.customer_id = customers.customer_id
LEFT JOIN orderpayments
on orders.order_id = orderpayments.order_id
WHERE orderpayments.payment_installments IS NOT NULL AND
		payment_installments > 1
GROUP BY orderpayments.payment_installments, customers.customer_state
ORDER BY orderpayments.payment_installments desc, count DESC
	)

SELECT count, customer_state, payment_installments,
ROW_NUMBER() OVER (PARTITION BY payment_installments ORDER BY count DESC) AS rank
FROM cte_1
ORDER BY payment_installments DESC, rank ASC
	)

SELECT *
FROM cte_2
WHERE rank = 1
ORDER BY payment_installments DESC
	)
	
SELECT COUNT(*),
	customer_state
FROM cte_3
GROUP BY customer_state
ORDER BY 1 DESC;


-- Ödeme tipine göre başarılı order sayısı ve toplam başarılı ödeme tutarını hesaplayınız.
-- En çok kullanılan ödeme tipinden en az olana göre sıralayınız.


SELECT payment_type,
	COUNT(DISTINCT orderpayments.order_id) AS order_count,
	ROUND(SUM(payment_value)::integer, 2) AS order_sum
FROM orderpayments
LEFT JOIN orders
ON orderpayments.order_id = orders.order_id
WHERE order_status = 'delivered'
GROUP BY payment_type
ORDER BY 2 DESC;



-- Tek çekimde ve taksitle ödenen siparişlerin kategori bazlı analizini yapınız.
-- one-time payment
SELECT product_category_name_english,
	COUNT(DISTINCT orderitems.order_id) AS order_count,
	ROUND(SUM(payment_value)::integer, 2) AS payment_sum,
	MIN(payment_value) AS min_payment,
	MAX(payment_value) AS max_payment
FROM orderitems
LEFT JOIN (
	SELECT product_id,
	products.product_category_name,
	product_category_name_english
FROM products
LEFT JOIN categories
ON products.product_category_name = categories.product_category_name
) AS products_table
ON orderitems.product_id = products_table.product_id
LEFT JOIN orderpayments
ON orderpayments.order_id = orderitems.order_id
WHERE payment_installments = 1 AND
	payment_installments IS NOT NULL AND
	product_category_name_english IS NOT NULL
GROUP BY product_category_name_english
ORDER BY 2 DESC;


-- installment payment
SELECT product_category_name_english,
	COUNT(DISTINCT orderitems.order_id) AS order_count,
	ROUND(SUM(payment_value)::integer, 2) AS payment_sum,
	MIN(payment_value) AS min_payment,
	MAX(payment_value) AS max_payment
FROM orderitems
LEFT JOIN (
	SELECT product_id,
	products.product_category_name,
	product_category_name_english
FROM products
LEFT JOIN categories
ON products.product_category_name = categories.product_category_name
) AS products_table
ON orderitems.product_id = products_table.product_id
LEFT JOIN orderpayments
ON orderpayments.order_id = orderitems.order_id
WHERE payment_installments <> 1 AND 
	payment_installments IS NOT NULL AND
	product_category_name_english IS NOT NULL
GROUP BY product_category_name_english
ORDER BY 2 DESC;


-- En çok hangi kategorilerde taksitle ödeme kullanılmaktadır?
SELECT product_category_name_english,
	COUNT(DISTINCT orderitems.order_id) AS order_count
FROM orderitems
LEFT JOIN (
	SELECT product_id,
	products.product_category_name,
	product_category_name_english
FROM products
LEFT JOIN categories
ON products.product_category_name = categories.product_category_name
) AS products_table
ON orderitems.product_id = products_table.product_id
LEFT JOIN orderpayments
ON orderpayments.order_id = orderitems.order_id
WHERE payment_installments <> 1 AND
	payment_installments IS NOT NULL AND
	product_category_name_english IS NOT NULL
GROUP BY product_category_name_english
ORDER BY 2 DESC
LIMIT 20;



