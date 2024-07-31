CREATE DATABASE dannys_diner;
USE dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  
  /* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

SELECT customer_id, SUM(menu.price) AS total_expense
FROM sales s , menu
WHERE s.product_id = menu.product_id
GROUP BY 1;

-- 2. How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT(order_date)) AS days_visited
FROM sales
GROUP BY 1; 

-- 3. What was the first item from the menu purchased by each customer?

SELECT DISTINCT 
	customer_id, 
    FIRST_VALUE(product_name) OVER(PARTITION BY customer_id ORDER BY order_date) AS first_order
FROM sales s, menu m
WHERE s.product_id = m.product_id;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT product_name, COUNT(s.product_id) AS popularity
FROM sales s, menu m
WHERE s.product_id = m.product_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH CTE AS
(
SELECT customer_id, product_name,COUNT(*) AS total, RANK()OVER(PARTITION BY customer_id ORDER BY COUNT(*) DESC  ) AS RN
FROM sales s, menu m
WHERE s.product_id = m.product_id
GROUP BY 1,2
)
SELECT customer_id, product_name, total
FROM CTE
WHERE RN = 1
GROUP BY 1,2
;


-- 6. Which item was purchased first by the customer after they became a member?

WITH CTE AS
(
SELECT s.customer_id, m.product_name,order_date,join_date,RANK()OVER(PARTITION BY s.customer_id ORDER BY order_date) AS RN
FROM sales s
JOIN menu m
	ON s.product_id = m.product_id
JOIN members mem
	ON s.customer_id = mem.customer_id
WHERE order_date >= join_date
ORDER BY s.customer_id,order_date 
 )
 SELECT customer_id, product_name,order_date,join_date
 FROM CTE
 WHERE RN = 1;
 
-- 7. Which item was purchased just before the customer became a member?
WITH CTE AS
(
SELECT s.customer_id, m.product_name,order_date,join_date,RANK()OVER(PARTITION BY s.customer_id ORDER BY order_date DESC) AS RN
FROM sales s
JOIN menu m
	ON s.product_id = m.product_id
JOIN members mem
	ON s.customer_id = mem.customer_id
WHERE order_date < join_date
ORDER BY s.customer_id,order_date 
 )
 SELECT customer_id, product_name,order_date,join_date
 FROM CTE
 WHERE RN = 1;

-- 8. What is the total items and amount spent for each member before they became a member?


SELECT s.customer_id, COUNT(m.product_id) AS total_items ,SUM(price) AS amount_spent
FROM sales s
JOIN menu m
	ON s.product_id = m.product_id
JOIN members mem
	ON s.customer_id = mem.customer_id
WHERE order_date < join_date
GROUP BY 1
ORDER BY s.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH CTE AS
(
SELECT customer_id, product_name, price,
		price*IF(product_name = 'sushi',2,1) AS points_multiplier
FROM sales s
JOIN menu m
	ON s.product_id = m.product_id
 )
 SELECT customer_id,  SUM(points_multiplier) AS total_points
 FROM CTE 
 GROUP BY customer_id
 
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH CTE AS 
(
SELECT s.customer_id, s.order_date, m.product_name, m.price,
		CASE
			WHEN order_date BETWEEN mem.join_date AND DATE_ADD(mem.join_date,INTERVAL 6 DAY) THEN m.price * 2
            WHEN order_date NOT BETWEEN mem.join_date AND DATE_ADD(mem.join_date,INTERVAL 6 DAY) AND product_name = 'sushi' THEN m.price * 2
            ELSE price*1
            END AS total_points
FROM sales s
JOIN menu m
	ON s.product_id = m.product_id
JOIN members mem
	ON mem.customer_id = s.customer_id
WHERE order_date < '2021-01-31'
ORDER BY order_date
 )
 SELECT customer_id,  SUM(total_points) AS total_points_till_Jan_31
 FROM CTE 
 GROUP BY customer_id
 ORDER BY customer_id;
