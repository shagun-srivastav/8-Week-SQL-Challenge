--Creating temp tables for tables we need to change/alter types

--Exclusion and Extras column : Removing NULL values and replacing with ' '
SELECT 
  order_id, 
  customer_id, 
  pizza_id, 
  CASE
	  WHEN exclusions IS null OR exclusions LIKE 'null' THEN ' '
	  ELSE exclusions
	  END AS exclusions,
  CASE
	  WHEN extras IS NULL or extras LIKE 'null' THEN ' '
	  ELSE extras
	  END AS extras,
	order_time
INTO #customer_orders_temp
FROM dbo.customer_orders;

SELECT * from #customer_orders_temp;


 --Pickup_time column : Remove nulls and replace with blank space ' '.
 --Distance column : Remove "km" and nulls and replace with blank space ' '.
 --Duration column : Remove "minutes", "minute" and nulls and replace with blank space ' '.
 --Cancellation column : Remove NULL and null and and replace with blank space ' '.

SELECT 
  order_id, 
  runner_id, 
   CASE
	  WHEN pickup_time IS null OR pickup_time LIKE 'null' THEN ' '
	  ELSE pickup_time
	  END AS pickup_time, 
  CASE
	  WHEN distance IS null OR distance LIKE 'null' THEN ' '
	  WHEN distance LIKE '%km' THEN TRIM('km' from distance)
	  ELSE distance
	  END AS distance,
  CASE
	  WHEN duration LIKE 'null' THEN ' '
	  WHEN duration LIKE '%mins' THEN TRIM('mins' from duration)
	  
	  WHEN duration like '%minute' THEN TRIM('minute' from duration)
	  WHEN duration like '%minutes' THEN TRIM('minutes' from duration)
	  ELSE NULL
	  END AS duration,
  CASE
	  WHEN cancellation IS NULL or cancellation LIKE 'null' THEN ' '
	  ELSE cancellation
	  END AS cancellation
INTO #runner_orders_temp
FROM dbo.runner_orders;


SELECT * from dbo.#runner_orders_temp;

-- Duration, Distance, Pickup_time : Changing data types to correct types

ALTER TABLE dbo.#runner_orders_temp
ALTER COLUMN duration INT;

ALTER TABLE dbo.#runner_orders_temp
ALTER COLUMN distance FLOAT;

ALTER TABLE dbo.#runner_orders_temp
ALTER COLUMN pickup_time DATETIME;
