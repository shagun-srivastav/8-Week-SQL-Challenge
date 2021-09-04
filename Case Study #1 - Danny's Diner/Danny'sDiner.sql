SELECT *
FROM dbo.members;

SELECT *
FROM dbo.menu;

SELECT *
FROM dbo.sales;

---------------------------------------------
-----------CASE STUDY QUESTIONS--------------
---------------------------------------------

-- Q1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id AS CustomerName, SUM(price) AS TotalAmountSpent
FROM dbo.sales s
JOIN dbo.menu m 
	ON s.product_id = m.product_id
GROUP BY customer_id
ORDER BY s.customer_id;



--Q2. How many days has each customer visited the restaurant?

SELECT customer_id AS CustomerName, COUNT(distinct(order_date)) AS NoOfDays
FROM dbo.sales
GROUP BY customer_id;


--Q3. What was the first item from the menu purchased by each customer?
SELECT s.customer_id AS CustomerName, SUM(price) AS TotalAmountSpent
FROM dbo.sales s
JOIN dbo.menu m 
	ON s.product_id = m.product_id
GROUP BY customer_id
ORDER BY s.customer_id;
WITH cte_order AS (
	SELECT s.customer_id AS CustomerName, m.product_name AS NameOfProduct,
	ROW_NUMBER() OVER (
		PARTITION BY s.customer_id
		ORDER BY s.order_date,
				 s.product_id
	) AS FirstItemPurchASed
FROM dbo.sales s 
JOIN dbo.menu m
	ON s.product_id = m.product_id
)

SELECT * FROM cte_order WHERE FirstItemPurchASed = 1;


--Q4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT TOP 1 m.product_name AS MostPurchASedItem, COUNT(s.product_id) AS PurchaseCount
FROM dbo.sales s 
JOIN dbo.menu m
	ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY PurchaseCount desc;



--Q5. Which item was the most popular for each customer?

WITH CTE_popular AS
(			SELECT s.customer_id, m.product_name AS ProductName, COUNT(m.product_id) AS COUNT,
			ROW_NUMBER() OVER ( 
				PARTITION BY s.customer_id
				ORDER BY COUNT(m.product_id) desc
			) AS Popular
FROM dbo.sales s 
JOIN dbo.menu m
	ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name
)
SELECT * FROM CTE_popular WHERE popular =1; 


--Q6. Which item was purchased first by the customer after they became a member?

WITH cte_firstitem AS(
			SELECT s.customer_id,s.product_id, s.order_date, me.JOIN_date,
			ROW_NUMBER() OVER (
				PARTITION BY s.customer_id
				ORDER BY s.order_date
			) AS ordernumber
FROM dbo.sales s 
JOIN dbo.members me
	ON me.customer_id = s.customer_id
WHERE s.order_date>=me.JOIN_date
)

SELECT cte.customer_id,m.product_name,cte.order_date
FROM cte_firstitem cte 
JOIN dbo.menu m
	ON cte.product_id = m.product_id
WHERE ordernumber = 1;



--Q7. Which item was purchased just before the customer became a member?
WITH cte_firstitem AS (
		SELECT s.customer_id,s.product_id, s.order_date, me.JOIN_date,
		DENSE_RANK() OVER (
			PARTITION BY s.customer_id
			ORDER BY s.order_date desc
		) AS ordernumber
FROM dbo.sales s 
JOIN dbo.members me
	ON me.customer_id = s.customer_id
WHERE s.order_date<me.JOIN_date
)

SELECT cte.customer_id,m.product_name,cte.order_date
FROM cte_firstitem cte 
JOIN dbo.menu m
	ON cte.product_id = m.product_id
WHERE ordernumber = 1;


--Q8. What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id,COUNT(m.product_id) AS TotalItems,SUM(m.price) AS TotalAmountSpent
FROM dbo.sales s 
JOIN dbo.menu m
	ON s.product_id = m.product_id
JOIN dbo.members me
	ON s.customer_id = me.customer_id
WHERE s.order_date< me.JOIN_date
GROUP BY s.customer_id;


--Q9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH cte_points AS (
		SELECT s.customer_id,
		CASE m.product_name 
				WHEN 'sushi' THEN m.price*20
				ELSE m.price*10
		END AS points
FROM dbo.sales s 
JOIN dbo.menu m 
	ON s.product_id = m.product_id
)
SELECT customer_id, SUM(points) AS TotalPoints
FROM cte_points
GROUP BY customer_id;



--Q10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH cte_dates AS
(
    SELECT *,
    DATEADD(DAY, 6, JOIN_date) AS valid_date,
    EOMONTH('2021-01-31') AS last_date
    FROM dbo.members AS m
)
SELECT d.customer_id,d.valid_date,d.last_date,s.order_date,m.product_name,m.price,
SUM( CASE 
		WHEN s.order_date >=d.JOIN_date AND s.order_date <d.valid_date THEN 2 * 10 * m.price
		WHEN m.product_name = 'sushi' THEN 2 * 10 * m.price
		ELSE 10 *m.price
	 END) AS POINTS
FROM cte_dates d JOIN dbo.sales s 
	ON d.customer_id = s.customer_id
JOIN dbo.menu m
	ON s.product_id = m.product_id
WHERE s.order_date < d.last_date
GROUP BY d.customer_id, s.order_date, d.JOIN_date, d.valid_date, d.last_date, m.product_name, m.price;


-----BONUS QUESTIONS-----

--Bonus Question 1. Join All The Things
 
SELECT s.customer_id, s.order_date,m.product_name,m.price,
CASE 
	WHEN me.JOIN_date <= s.order_date THEN 'Y'
	ELSE 'N'
END AS Member
FROM dbo.sales s 
JOIN dbo.menu m
	ON s.product_id = m.product_id
LEFT JOIN dbo.members me 
	ON me.customer_id = s.customer_id;

--Bonus Question 2. Rank All The Things

WITH CTE_ranking AS (
	SELECT s.customer_id, s.order_date,m.product_name,m.price,
	CASE 
		WHEN me.JOIN_date <= s.order_date THEN 'Y'
		ELSE 'N'
	END AS Member
	FROM dbo.sales s 
	JOIN dbo.menu m
		ON s.product_id = m.product_id
	LEFT JOIN dbo.members me 
		ON me.customer_id = s.customer_id
)

SELECT *,
CASE 
	WHEN member = 'N' THEN NULL
	ELSE
	RANK() OVER (
		PARTITION BY customer_id, member
		ORDER BY order_date)
	END AS Ranking
FROM CTE_ranking;