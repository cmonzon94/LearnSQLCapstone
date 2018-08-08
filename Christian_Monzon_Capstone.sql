--Question 1: A look at dataset
 SELECT *
 FROM SUBSCRIPTIONS
 LIMIT 100;

--Question 2: Identifying range of subscription data
SELECT min(subscription_start) AS Min,
	max(subscription_start) AS Max
FROM subscriptions;

--Identifying distinct user segments
SELECT DISTINCT segment AS Distinct_User_Segments
FROM subscriptions;

--Calculating churn rate by month

--Question 3: Temporary "months" table
WITH months AS (
  SELECT 
 	'2017-01-01' AS first_day,
 	'2017-01-31' AS last_day
  UNION
  SELECT
  	'2017-02-01' AS first_day,
  	'2017-02-28' AS last_day
  UNION
  SELECT
  	'2017-03-01' AS first_day,
  	'2017-03-31' AS last_day
),

--Temp cross join table 
---of months and subscriptions tables
cross_join AS
(SELECT *
FROM subscriptions
CROSS JOIN months),

--Temp table active and cancelled subscribers
status AS (
  SELECT 
    id, first_day AS month, 
    CASE
      WHEN (subscription_start < first_day) 
        AND (
          subscription_end > first_day 
          OR subscription_end IS NULL
        ) THEN 1
      ELSE 0
    END AS is_active,
    CASE
      WHEN subscription_end BETWEEN first_day AND last_day THEN 1
      ELSE 0
    END AS is_canceled
  FROM cross_join
),

--SUM active and canceled subscribers
status_aggregate AS (
  SELECT 
    month, 
    SUM(is_active) AS active, 
    SUM(is_canceled) AS canceled 
  FROM status 
  GROUP BY month
) 
SELECT
  month, 
  100 * (1.0 * canceled / active) AS churn_rate 
FROM status_aggregate;

--Calculating churn rate by segment grouped by month
WITH months AS (
  SELECT 
 	'2017-01-01' AS first_day,
 	'2017-01-31' AS last_day
  UNION
  SELECT
  	'2017-02-01' AS first_day,
  	'2017-02-28' AS last_day
  UNION
  SELECT
  	'2017-03-01' AS first_day,
  	'2017-03-31' AS last_day
),
cross_join AS (
	SELECT *
	FROM subscriptions
	CROSS JOIN months
),
status AS (
  SELECT 
    id, first_day AS month, 
    CASE
      WHEN (segment = 87) AND (subscription_start < first_day) 
        AND (
          subscription_end > first_day 
          OR subscription_end IS NULL
        ) THEN 1
      ELSE 0
    END AS is_active_87,
   CASE
      WHEN (segment = 30) AND (subscription_start < first_day) 
        AND (
          subscription_end > first_day 
          OR subscription_end IS NULL
        ) THEN 1
      ELSE 0
    END AS is_active_30, 
    CASE
      WHEN (segment = 87) AND subscription_end BETWEEN first_day AND last_day THEN 1
      ELSE 0
    END AS is_canceled_87,
    CASE
      WHEN (segment = 30) AND subscription_end BETWEEN first_day AND last_day THEN 1
      ELSE 0
    END AS is_canceled_30
  FROM cross_join
), 
status_aggregate AS (
  SELECT 
    month, 
    SUM(is_active_87) AS sum_active_87, 
    SUM(is_canceled_87) AS sum_canceled_87,
    SUM(is_active_30) AS sum_active_30, 
    SUM(is_canceled_30) AS sum_canceled_30
  FROM status 
  GROUP BY month)
SELECT
  month,
  sum_active_87 AS Active87, 
  sum_active_30 AS Active30,
  sum_canceled_87 AS Canceled87,
  sum_canceled_30 AS Canceled30, 
  100 * (1.0 * sum_canceled_87 / sum_active_87) AS churn_rate_87,
  100 * (1.0 * sum_canceled_30 / sum_active_30) AS churn_rate_30
FROM status_aggregate;