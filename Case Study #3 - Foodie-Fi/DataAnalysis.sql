SELECT * 
FROM plans;

SELECT *
FROM subscriptions;

-------------------------------------------
-----------CASE STUDY SOLUTIONS------------
-------------------------------------------




-- Q1. How many customers has Foodie-Fi ever had?

SELECT COUNT(DISTINCT customer_id) as NumberOfCustomers
FROM subscriptions;

-- Q2. What is the monthly distribution of trial plan start_date values for our dataset?

SELECT DATEPART(MONTH,start_date) as MonthNumber,
		DATENAME(MONTH,start_date) as Month_Name,
		count(*) as TrialSubscriptions
FROM subscriptions
WHERE plan_id = 0
GROUP BY DATEPART(MONTH,start_date), DATENAME(MONTH,start_date)
ORDER BY MonthNumber;


--Q3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

SELECT P.plan_name, P.plan_id, count(*) as SubscriptionsIn2021
FROM plans P 
JOIN subscriptions S
	ON P.plan_id = S.plan_id
WHERE S.start_date >= '2021-01-01'
GROUP BY P.plan_id,P.plan_name
ORDER BY P.plan_id;

--Q4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

SELECT COUNT(*) as CustomerCount, 
	   ROUND( (100 * COUNT(*)/( SELECT COUNT(DISTINCT customer_id) 
								  FROM subscriptions S)),1) AS CHURNRATE
FROM plans P 
JOIN subscriptions S
	ON P.plan_id = S.plan_id
WHERE P.plan_id = 4;

--Q5. How many customers have churned straight after their initial free trial?

WITH RANKING AS (
     SELECT S.customer_id,
			P.plan_id,
			P.plan_name,
	ROW_NUMBER() OVER (
		PARTITION BY S.customer_id
		ORDER BY P.plan_id) AS RANKING
	FROM plans P 
	JOIN subscriptions S
		ON P.plan_id = S.plan_id
)
     
SELECT COUNT(*) as CustomerCount, 
	   ROUND( (100 * COUNT(*)/( SELECT COUNT(DISTINCT customer_id) 
								  FROM subscriptions S)),0) AS CHURNRATE
FROM RANKING
WHERE plan_id = 4
	AND RANKING = 2;

--Q6. What is the number and percentage of customer plans after their initial free trial?

WITH next_plan AS (
SELECT customer_id, plan_id,
	   LEAD(plan_id) OVER( PARTITION BY customer_id			
						   ORDER BY plan_id) as Next_Plan
from subscriptions
)

--SELECT * FROM next_plan;

SELECT Next_Plan, COUNT(*) AS Conversions,
	   ROUND(100 * COUNT(*)/ ( SELECT COUNT(DISTINCT customer_id) 
							   FROM subscriptions),2) AS ConversionPercentage
FROM next_plan
WHERE Next_Plan IS NOT NULL 
  AND plan_id = 0
GROUP BY Next_Plan
ORDER BY Next_Plan;
 

-- Q7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

WITH next_plan AS(
   SELECT customer_id, plan_id,start_date,
   LEAD(start_date) OVER(PARTITION BY customer_id 
							ORDER BY start_date) AS next_date
FROM subscriptions
WHERE start_date <= '2020-12-31'
),
--SELECT * FROM next_plan;
  customer_count AS (
	SELECT plan_id, COUNT(DISTINCT customer_id) AS customers
	FROM next_plan
	WHERE (next_date IS NOT NULL AND (start_date < '2020-12-31' AND next_date > '2020-12-31'))
		OR (next_date IS NULL AND start_date < '2020-12-31')
	GROUP BY plan_id
)

SELECT plan_id, customers, ROUND(100 * customers /( SELECT COUNT(DISTINCT customer_id) 
													FROM subscriptions),2) AS percentage
FROM customer_count
GROUP BY plan_id, customers
ORDER BY plan_id;

--Q8. How many customers have upgraded to an annual plan in 2020?
SELECT COUNT(DISTINCT customer_id) AS NumberOfCustomers
FROM subscriptions
WHERE plan_id = 3 
  AND start_date <= '2020-12-31';


-- Q9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

WITH trial_plan AS (
   SELECT customer_id, start_date AS trial_date
   FROM subscriptions
   WHERE plan_id = 0
),
    annual_plan AS (
   SELECT customer_id, start_date AS annual_date
   FROM subscriptions
   WHERE plan_id = 3
)

SELECT ROUND(AVG(DATEDIFF(day,trial_date,annual_date)),0) AS AverageDays
FROM trial_plan TP
JOIN annual_plan AP
	ON TP.customer_id = AP.customer_id;
	
	
	
-- Q10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

WITH trial_plan AS (
   SELECT customer_id, start_date AS trial_date
   FROM subscriptions
   WHERE plan_id = 0
),
    annual_plan AS (
   SELECT customer_id, start_date AS annual_date
   FROM subscriptions
   WHERE plan_id = 3
),

  bins AS (
	SELECT CASE
					 WHEN DATEDIFF(day,TP.trial_date,AP.annual_date) <30 THEN '[0,30)' 
					 WHEN DATEDIFF(day,TP.trial_date,AP.annual_date) <60 THEN '[30,60)' 
					 WHEN DATEDIFF(day,TP.trial_date,AP.annual_date) <90 THEN '[60,90)' 
					 WHEN DATEDIFF(day,TP.trial_date,AP.annual_date) <120 THEN '[90,120)' 
					 WHEN DATEDIFF(day,TP.trial_date,AP.annual_date) <150 THEN '[120,150)' 
					 WHEN DATEDIFF(day,TP.trial_date,AP.annual_date) <180 THEN '[150,180)' 
					 WHEN DATEDIFF(day,TP.trial_date,AP.annual_date) <210 THEN '[180,210)' 
					 WHEN DATEDIFF(day,TP.trial_date,AP.annual_date) <240 THEN '[210,240)' 
					 WHEN DATEDIFF(day,TP.trial_date,AP.annual_date) <270 THEN '[240,270)' 
					 WHEN DATEDIFF(day,TP.trial_date,AP.annual_date) <300 THEN '[270,300)' 
					 WHEN DATEDIFF(day,TP.trial_date,AP.annual_date) <330 THEN '[300,330)' 
					 WHEN DATEDIFF(day,TP.trial_date,AP.annual_date) <360 THEN '[330,360)' 
					 ELSE 'Unknown'
					 END AS DaysBucket
  FROM trial_plan TP
  JOIN annual_plan AP
	ON TP.customer_id = AP.customer_id
)
SELECT CONCAT(DaysBucket,' days') as Duration, Count(*) as NumberOfCustomers
FROM bins
GROUP BY DaysBucket
ORDER BY NumberOfCustomers desc;


--Q11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

WITH Next_Plan AS(
   SELECT customer_id, plan_id, start_date,
   LEAD(plan_id) OVER(PARTITION BY customer_id 
							ORDER BY plan_id) AS next_plan
FROM subscriptions
)
--SELECT * FROM Next_Plan;

SELECT COUNT(*) AS NumberOfCustomers
FROM Next_Plan
WHERE plan_id = 2
	AND next_plan = 1
	AND start_date <='2020-12-31';