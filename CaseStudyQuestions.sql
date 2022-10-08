SELECT *
FROM Dannys_Diner.dbo.sales;

SELECT *
FROM Dannys_Diner.dbo.menu;

SELECT *
FROM Dannys_Diner.dbo.members;


----Case Study Questions

--1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id, SUM(price) 'Total Amount'
FROM  Dannys_Diner.dbo.sales s
JOIN Dannys_Diner.dbo.menu m
		ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- 2. How many days has each customer visited the restaurant?
--There are orders by the same customer within the same date ,so I use distinct to get unique values
SELECT s.customer_id, Count(DISTINCT order_date) 'Date Visited'
FROM  Dannys_Diner.dbo.sales s
GROUP BY s.customer_id;

-- 3. What was the first item from the menu purchased by each customer?

WITH
 first_purchase
AS
 (
  SELECT
   s.customer_id,
   s.order_date,
   m.product_name,
			DENSE_RANK() OVER(PARTITION BY s.customer_id 
          ORDER BY s.order_date) AS rank
  FROM Dannys_Diner.dbo.sales s
  LEFT JOIN Dannys_Diner.dbo.menu m
  ON s.product_id = m.product_id
  LEFT JOIN Dannys_Diner.dbo.members ms 
  ON s.customer_id = ms.customer_id
 )
SELECT 
 customer_id,
 product_name, 
 order_date
FROM first_purchase
WHERE rank = 1
GROUP BY customer_id, product_name, order_date;

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT TOP 1  product_name, COUNT(order_date) AS 'Number of Purchases'
FROM  Dannys_Diner.dbo.sales s
JOIN Dannys_Diner.dbo.menu m
		ON s.product_id = m.product_id
GROUP BY product_name
ORDER BY 2 DESC;

-- 5. Which item was the most popular for each customer?

WITH popular_item_cte AS
(
	SELECT 
    s.customer_id, 
    m.product_name, 
    COUNT(m.product_id) AS order_count,
		DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.customer_id) DESC) AS rank
 FROM Dannys_Diner.dbo.sales s
 LEFT JOIN Dannys_Diner.dbo.menu m
 ON s.product_id = m.product_id
 LEFT JOIN Dannys_Diner.dbo.members ms 
 ON s.customer_id = ms.customer_id
GROUP BY s.customer_id, m.product_name
)
SELECT 
  customer_id, 
  product_name, 
  order_count
FROM popular_item_cte
WHERE rank = 1;


--6. Which item was purchased first by the customer after they became a member?
WITH member_sales_cte AS 
(
  SELECT 
    s.customer_id, 
    ms.join_date, 
    s.order_date,
	s.product_id,
    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rank
  FROM Dannys_Diner.dbo.sales s
	JOIN Dannys_Diner.dbo.members ms
		ON s.customer_id = ms.customer_id
	WHERE s.order_date >= ms.join_date
)

SELECT 
  s.customer_id, 
  s.order_date, 
  ms.product_name 
FROM member_sales_cte s
JOIN Dannys_Diner.dbo.menu ms
	ON s.product_id = ms.product_id
WHERE rank = 1;

--7. Which item was purchased just before the customer became a member?

WITH purchase_b4_member_cte AS 
(
  SELECT 
    s.customer_id, 
    ms.join_date, 
    s.order_date,
	s.product_id,
    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rank
  FROM Dannys_Diner.dbo.sales s
	JOIN Dannys_Diner.dbo.members ms
		ON s.customer_id = ms.customer_id
	WHERE s.order_date < ms.join_date
)

SELECT 
  p.customer_id, 
  p.order_date, 
  ms.product_name 
FROM purchase_b4_member_cte p
JOIN Dannys_Diner.dbo.menu ms
	ON p.product_id = ms.product_id
WHERE rank = 1;
