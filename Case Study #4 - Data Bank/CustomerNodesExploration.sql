SELECT *
FROM customer_transactions;

SELECT *
FROM customer_nodes;

SELECT *
FROM regions;



----------------------------------------------
-------------CASE STUDY SOLUTIONS-------------
----------------------------------------------



-- Q1. How many unique nodes are there on the Data Bank system?

SELECT COUNT(DISTINCT node_id) AS Distinct_Nodes
FROM customer_nodes;

-- Q2. What is the number of nodes per region?

SELECT R.region_id,R.region_name, COUNT(CN.node_id) as CountofNodes
FROM regions R
JOIN customer_nodes CN
	 ON R.region_id = CN.region_id
GROUP BY R.region_id,R.region_name
ORDER BY R.region_id;

-- Q3. How many customers are allocated to each region?

SELECT CN.region_id, R.region_name, COUNT(CN.customer_id) as NumberOfCustomers
FROM customer_nodes CN
JOIN regions R
	ON CN.region_id = R.region_id
GROUP BY CN.region_id, R.region_name
ORDER BY CN.region_id;

-- Q4. How many days on average are customers reallocated to a different node?

WITH CTE_diff AS (
SELECT customer_id,node_id,start_date,end_date, DATEDIFF(day,start_date,end_date) as DATEDIFFERENCE
FROM customer_nodes
WHERE end_date != '9999-12-31'
GROUP BY customer_id,node_id,start_date,end_date
),
	CTE_DIFF_SUM AS(
SELECT customer_id,node_id,SUM(DATEDIFFERENCE) as sumdiff
FROM CTE_diff
GROUP BY customer_id,node_id
)
SELECT 
  ROUND(AVG(sumdiff),2) AS AVERAGE_NUMBER_OF_RELOCATION_DAYS
FROM CTE_DIFF_SUM;

--Q5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

WITH CTE_diff AS (
SELECT customer_id,node_id,start_date,end_date, DATEDIFF(day,start_date,end_date) as DATEDIFFERENCE
FROM customer_nodes
WHERE end_date != '9999-12-31'
GROUP BY customer_id,node_id,start_date,end_date
),
	CTE_DIFF_SUM AS(
SELECT customer_id,node_id,SUM(DATEDIFFERENCE) as sumdiff
FROM CTE_diff
GROUP BY customer_id,node_id
)
--SELECT * FROM CTE_DIFF_SUM;
SELECT 
  PERCENTILE_CONT(0.50) WITHIN GROUP(ORDER BY sumdiff)
							  OVER ()
							  AS MEDIAN,
  PERCENTILE_CONT(0.80) WITHIN GROUP(ORDER BY sumdiff)
					    OVER ()
					    AS EIGHTYPERCENTILE,
  PERCENTILE_CONT(0.95) WITHIN GROUP(ORDER BY sumdiff)
					    OVER ()
					    AS NINETYFIVEPERCENTILE 
FROM CTE_DIFF_SUM;