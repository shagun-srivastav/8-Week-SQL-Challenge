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


-- Q1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

select runner_id, 
CASE WHEN registration_date BETWEEN '2021-01-01' AND '2021-01-07' THEN 'Week 1'
	 WHEN registration_date BETWEEN '2021-01-08' AND '2021-01-14' THEN 'Week 2'
	 ELSE 'Week 3'
END AS Signups
From runners
ORDER BY runner_id;


-- Q2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?


WITH timediff_cte AS
(
SELECT r.runner_id, c.order_id, c.order_time, r.pickup_time, DATEDIFF(MINUTE, c.order_time, r.pickup_time) AS timetaken
FROM #customer_orders_temp AS c
JOIN #runner_orders_temp AS r
	ON c.order_id = r.order_id
WHERE r.distance != 0
GROUP BY r.runner_id, c.order_id, c.order_time, r.pickup_time
)

SELECT runner_id, AVG(timetaken) AS AvgTimeTaken
FROM timediff_cte
--WHERE timetaken > 1
GROUP BY runner_id;
	
	
-- Q3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

WITH preptime_cte AS

(
SELECT c.order_id, COUNT(c.order_id) AS Pizzas, c.order_time, r.pickup_time, DATEDIFF(MINUTE, c.order_time, r.pickup_time) AS PrepTimeTaken
FROM #customer_orders_temp AS c
JOIN #runner_orders_temp AS r
	ON c.order_id = r.order_id
WHERE r.distance != 0
GROUP BY c.order_id, c.order_time, r.pickup_time
)
-- select * from preptime_cte;

SELECT Pizzas, AVG(PrepTimeTaken) AS AvgPrepTimeTaken
FROM preptime_cte
--WHERE timetaken > 1
GROUP BY Pizzas;


-- Q4. What was the average distance travelled for each customer?

SELECT C.customer_id, AVG(R.distance) as AvgDistance
FROM #customer_orders_temp AS c
JOIN #runner_orders_temp AS R
	ON C.order_id = R.order_id
WHERE R.duration != 0
GROUP BY C.customer_id;

-- Q5. What was the difference between the longest and shortest delivery times for all orders?

--For each order individually:
SELECT C.order_id, C.order_time, R.pickup_time,DATEDIFF(minute, C.order_time, R.pickup_time) as DeliveryTime 
FROM #customer_orders_temp AS c
JOIN #runner_orders_temp AS r
	ON c.order_id = r.order_id
WHERE r.distance != 0
GROUP BY C.order_id,C.order_time, R.pickup_time
-------------------
--For all orders :
WITH deliverytime_CTE as (
SELECT C.order_id, C.order_time, R.pickup_time,DATEDIFF(minute, C.order_time, R.pickup_time) as DeliveryTime 
FROM #customer_orders_temp AS c
JOIN #runner_orders_temp AS r
	ON c.order_id = r.order_id
WHERE r.distance != 0
GROUP BY C.order_id,C.order_time, R.pickup_time
)

SELECT 
  (MAX(DeliveryTime) - MIN(DeliveryTime)) AS DeliveryTimeDiff
FROM deliverytime_CTE
WHERE DeliveryTime > 1


-- Q6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

SELECT 
  R.runner_id, 
  C.customer_id, 
  C.order_id, 
  --COUNT(C.order_id) AS pizza_count, 
  R.distance, 
  CASE 
	   WHEN R.duration is NULL or R.duration = 0 THEN 0
       ELSE R.duration
	   END AS duration_mins , 
  CASE 
       WHEN R.duration is NULL or R.duration = 0 THEN 0
       ELSE ROUND((R.distance/R.duration * 60), 2)
	   END AS AvgSpeedInKM_HR
FROM #runner_orders_temp AS R
JOIN #customer_orders_temp AS C
  ON R.order_id = C.order_id
WHERE distance != 0
GROUP BY R.runner_id, C.customer_id, C.order_id, R.distance, R.duration
ORDER BY C.order_id;

--Q7. What is the successful delivery percentage for each runner?
SELECT runner_id, 
	   ROUND( 100 * SUM( CASE WHEN distance = 0 THEN 0
							  ELSE 1
						 END)/count(*),0) AS successpercentage
FROM #runner_orders_temp
GROUP BY runner_id;