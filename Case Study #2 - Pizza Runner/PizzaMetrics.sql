SELECT * 
FROM #customer_orders_temp;


SELECT * 
FROM pizza_names;


SELECT * 
FROM #runner_orders_temp;


SELECT * 
FROM pizza_recipes;


SELECT * 
FROM runners;


SELECT * 
FROM pizza_toppings;


-----------------------------------------
-----------CASE STUDY QUESTIONS----------
-----------------------------------------




-- Q1. How many pizzas were ordered?

SELECT COUNT(order_id) AS Number_Of_Pizzas
FROM #customer_orders_temp;

--Q2. How many unique customer orders were made?

SELECT COUNT(DISTINCT order_id) AS Unique_Orders
FROM #customer_orders_temp;

--Q3. How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(order_id) AS Successful_Orders
FROM dbo.#runner_orders_temp
WHERE duration != 0
GROUP BY runner_id;

--Q4. How many of each type of pizza was delivered?

SELECT P.pizza_name, COUNT(R.order_id) AS Successful_Orders
FROM dbo.#runner_orders_temp R 
JOIN #customer_orders_temp C 
	ON R.order_id = C.order_id
JOIN pizza_names P
	ON P.pizza_id = C.pizza_id
WHERE R.distance !=0
GROUP BY P.pizza_name;



--Q5. How many Vegetarian and Meatlovers were ordered by each customer?

SELECT C.customer_id, P.pizza_name, COUNT(P.pizza_name)
FROM #customer_orders_temp AS C 
JOIN pizza_names AS P
	ON C.pizza_id = P.pizza_id
GROUP BY C.customer_id, P.pizza_name
ORDER BY C.customer_id;


--Q6. What was the maximum number of pizzas delivered in a single order?

WITH number_of_pizzas_CTE AS (
SELECT 
	C.order_id, 
	COUNT(C.pizza_id) AS MaxNumber
FROM #customer_orders_temp C
JOIN #runner_orders_temp R
	ON C.order_id = R.order_id
WHERE R.distance !=0
GROUP BY C.order_id
)

SELECT TOP 1 order_id, MAX(MaxNumber)  AS TotalNumberOfPizzas
FROM number_of_pizzas_CTE
GROUP BY order_id
ORDER BY TotalNumberOfPizzas desc;


--without CTE:
SELECT TOP 1
	C.order_id, 
	COUNT(C.pizza_id) AS MaxNumber
FROM #customer_orders_temp C
JOIN #runner_orders_temp R
	ON C.order_id = R.order_id
WHERE R.distance !=0
GROUP BY C.order_id
ORDER BY MaxNumber desc;


--Q7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

SELECT 
	C.customer_id, 
	SUM( CASE WHEN C.exclusions <> ' ' OR C.extras <> ' ' THEN 1
		 ELSE 0
		 END) AS Changes,
	SUM( CASE WHEN C.exclusions = ' ' AND C.extras = ' ' THEN 1
		 ELSE 0
		 END) AS NoChanges
FROM #customer_orders_temp C
JOIN #runner_orders_temp R
	ON	C.order_id = R.order_id
WHERE R.distance != 0 
GROUP BY C.customer_id
ORDER BY C.customer_id;


--Q8. How many pizzas were delivered that had both exclusions and extras?

SELECT C.customer_id,
	SUM( CASE WHEN C.exclusions <> ' ' AND C.extras <> ' ' THEN 1
		 ELSE 0
		 END) AS ChangesWithExclusionsAndExtras
FROM #customer_orders_temp C
JOIN #runner_orders_temp R
	ON	C.order_id = R.order_id
WHERE R.distance != 0 
AND exclusions <> ' ' 
AND extras <> ' '
GROUP BY C.customer_id


--Q9. What was the total volume of pizzas ordered for each hour of the day?

SELECT DATEPART(HOUR, order_time) AS Hour_Of_Order, COUNT(order_id) AS PizzaOrdered
FROM #customer_orders_temp
GROUP BY DATEPART(HOUR, order_time) 


--Q10. What was the volume of orders for each day of the week?

SELECT DATENAME(WEEKDAY, order_time) AS DayOfTheWeek, COUNT(order_id) AS PizzaOrdered
FROM #customer_orders_temp
GROUP BY DATENAME(WEEKDAY, order_time) 
