-- ============================================
-- CASE STUDY 2: PIZZA RUNNER
-- Danny Ma's 8 Week SQL Challenge
-- ============================================

-- ============================================
-- DATA CLEANING
-- ============================================

-- Create clean customer orders table
CREATE TABLE pizza_runner.clean_customer_orders AS
SELECT 
    order_id, customer_id, pizza_id,
    CASE WHEN exclusions IN ('null', '') THEN NULL ELSE exclusions END AS exclusions,
    CASE WHEN extras IN ('null', '') THEN NULL ELSE extras END AS extras,
    order_time
FROM pizza_runner.customer_orders;

-- Create clean runner orders table
CREATE TABLE pizza_runner.clean_runner_orders AS
WITH no_null AS (
    SELECT 
        order_id, runner_id,
        CASE WHEN pickup_time = 'null' THEN NULL ELSE pickup_time END AS pickup_time,
        CASE WHEN distance = 'null' THEN NULL ELSE distance END AS distance,
        CASE WHEN duration = 'null' THEN NULL ELSE duration END AS duration,
        CASE WHEN cancellation IN ('null', '') THEN NULL ELSE cancellation END AS cancellation
    FROM pizza_runner.runner_orders
)
SELECT 
    order_id, runner_id,
    pickup_time::timestamp AS pickup_time,
    REGEXP_REPLACE(distance, '[a-zA-Z\s]', '', 'g')::numeric AS distance,
    REGEXP_REPLACE(duration, '[a-zA-Z\s]', '', 'g')::numeric AS duration,
    cancellation
FROM no_null;

-- ============================================
-- SECTION A: PIZZA METRICS
-- ============================================

-- Q1: How many pizzas were ordered?
SELECT COUNT(pizza_id) AS total_pizzas_ordered
FROM pizza_runner.clean_customer_orders;

-- Q2: How many unique customer orders were made?
SELECT COUNT(DISTINCT customer_id) AS unique_customers
FROM pizza_runner.clean_customer_orders;

-- Q3: How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(order_id) AS successful_deliveries
FROM pizza_runner.clean_runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id;

-- Q4: How many of each type of pizza was delivered?
SELECT customer_id, pizza_id, COUNT(pizza_id) AS number_sold
FROM pizza_runner.clean_customer_orders
GROUP BY customer_id, pizza_id
ORDER BY customer_id ASC, pizza_id ASC;

-- Q5: How many Vegetarian and Meatlovers were ordered by each customer?
SELECT customer_id, pizza_id, COUNT(pizza_id) AS number_sold
FROM pizza_runner.clean_customer_orders
GROUP BY customer_id, pizza_id
ORDER BY customer_id ASC, pizza_id ASC;

-- Q6: What was the maximum number of pizzas delivered in a single order?
SELECT order_id, COUNT(pizza_id) AS pizzas_in_order
FROM pizza_runner.clean_customer_orders
GROUP BY order_id
ORDER BY pizzas_in_order DESC
LIMIT 1;

-- Q7: For each customer, how many delivered pizzas had at least 1 change vs no changes?
SELECT 
    cco.customer_id,
    COUNT(CASE WHEN exclusions IS NOT NULL OR extras IS NOT NULL THEN 1 END) AS with_changes,
    COUNT(CASE WHEN exclusions IS NULL AND extras IS NULL THEN 1 END) AS no_changes
FROM pizza_runner.clean_customer_orders cco
JOIN pizza_runner.clean_runner_orders cro ON cco.order_id = cro.order_id
WHERE cro.cancellation IS NULL
GROUP BY cco.customer_id;

-- Q8: How many pizzas were delivered with both exclusions AND extras?
SELECT COUNT(CASE WHEN exclusions IS NOT NULL AND extras IS NOT NULL THEN 1 END) AS both_changes
FROM pizza_runner.clean_customer_orders cco
JOIN pizza_runner.clean_runner_orders cro ON cco.order_id = cro.order_id
WHERE cro.cancellation IS NULL;

-- Q9: What was the total volume of pizzas ordered for each hour of the day?
SELECT EXTRACT(HOUR FROM order_time) AS order_hour, COUNT(order_id) AS total_pizzas
FROM pizza_runner.clean_customer_orders
GROUP BY order_hour
ORDER BY order_hour ASC;

-- Q10: What was the volume of orders for each day of the week?
SELECT EXTRACT(DOW FROM order_time) AS order_weekday, COUNT(order_id) AS total_volume
FROM pizza_runner.clean_customer_orders
GROUP BY order_weekday
ORDER BY order_weekday ASC;

-- ============================================
-- SECTION B: RUNNER AND CUSTOMER EXPERIENCE
-- ============================================

-- Q1: How many runners signed up for each 1 week period?
SELECT 
    FLOOR((registration_date - '2021-01-01') / 7) + 1 AS week,
    COUNT(runner_id) AS signups
FROM pizza_runner.runners
GROUP BY week
ORDER BY week;

-- Q2: What was the average time for each runner to arrive at HQ to pickup the order?
SELECT 
    cro.runner_id,
    ROUND(AVG(EXTRACT(EPOCH FROM (cro.pickup_time - cco.order_time)) / 60), 2) AS avg_pickup_minutes
FROM pizza_runner.clean_customer_orders cco
JOIN pizza_runner.clean_runner_orders cro ON cco.order_id = cro.order_id
WHERE cro.cancellation IS NULL
GROUP BY cro.runner_id;

-- Q3: Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH pizza_timecount AS (
    SELECT 
        cco.order_id,
        COUNT(cco.pizza_id) AS pizza_count,
        ROUND((EXTRACT(EPOCH FROM (cro.pickup_time - cco.order_time)) / 60), 2) AS prep_time
    FROM pizza_runner.clean_customer_orders cco
    JOIN pizza_runner.clean_runner_orders cro ON cco.order_id = cro.order_id
    WHERE cancellation IS NULL
    GROUP BY cco.order_id, cro.pickup_time, cco.order_time
)
SELECT pizza_count, ROUND(AVG(prep_time), 1) AS avg_prep_time
FROM pizza_timecount
GROUP BY pizza_count
ORDER BY pizza_count;

-- Q4: What was the average distance travelled for each customer?
SELECT 
    cco.customer_id,
    ROUND(AVG(cro.distance), 1) AS avg_distance_km
FROM pizza_runner.clean_customer_orders cco
JOIN pizza_runner.clean_runner_orders cro ON cco.order_id = cro.order_id
WHERE cancellation IS NULL
GROUP BY cco.customer_id;

-- Q5: What was the difference between the longest and shortest delivery times?
SELECT MAX(duration) - MIN(duration) AS delivery_time_diff
FROM pizza_runner.clean_runner_orders;

-- Q6: What was the average speed for each runner for each delivery?
SELECT 
    runner_id,
    order_id,
    distance,
    duration,
    ROUND((distance / duration) * 60.0, 2) AS speed_kmh
FROM pizza_runner.clean_runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id, order_id, distance, duration
ORDER BY runner_id;

-- Q7: What is the successful delivery percentage for each runner?
SELECT 
    runner_id,
    (COUNT(CASE WHEN cancellation IS NULL THEN order_id END) / COUNT(*)::numeric) * 100.0 AS success_pct
FROM pizza_runner.clean_runner_orders
GROUP BY runner_id
ORDER BY runner_id ASC;

-- ============================================
-- SECTION C: INGREDIENT OPTIMISATION
-- ============================================

-- Q1: What are the standard ingredients for each pizza?
WITH broken_down_recipes AS (
    SELECT 
        pizza_id,
        UNNEST(STRING_TO_ARRAY(toppings, ', '))::INTEGER AS topping_id
    FROM pizza_runner.pizza_recipes
)
SELECT 
    pn.pizza_name,
    STRING_AGG(pt.topping_name, ', ') AS standard_ingredients
FROM broken_down_recipes bdr
JOIN pizza_runner.pizza_names pn ON bdr.pizza_id = pn.pizza_id
JOIN pizza_runner.pizza_toppings pt ON bdr.topping_id = pt.topping_id
GROUP BY pn.pizza_name;

-- Q2: What was the most commonly added extra?
WITH extras AS (
    SELECT UNNEST(STRING_TO_ARRAY(extras, ', '))::numeric AS extras
    FROM pizza_runner.clean_customer_orders
    WHERE extras IS NOT NULL
)
SELECT pt.topping_name, COUNT(extras) AS times_added
FROM extras e
JOIN pizza_runner.pizza_toppings pt ON e.extras = pt.topping_id
GROUP BY pt.topping_name
ORDER BY times_added DESC
LIMIT 1;

-- Q3: What was the most common exclusion?
WITH exclusions AS (
    SELECT UNNEST(STRING_TO_ARRAY(exclusions, ', '))::numeric AS exclusion
    FROM pizza_runner.clean_customer_orders
    WHERE exclusions IS NOT NULL
)
SELECT pt.topping_name, COUNT(exclusion) AS times_excluded
FROM exclusions e
JOIN pizza_runner.pizza_toppings pt ON e.exclusion = pt.topping_id
GROUP BY pt.topping_name
ORDER BY times_excluded DESC
LIMIT 1;

-- ============================================
-- SECTION D: PRICING AND RATINGS
-- ============================================

-- Q1: Total revenue with no extras charge
SELECT 
    SUM(CASE 
        WHEN pn.pizza_name = 'Meatlovers' THEN 12
        WHEN pn.pizza_name = 'Vegetarian' THEN 10 
    END) AS total_revenue
FROM pizza_runner.clean_customer_orders cco
JOIN pizza_runner.clean_runner_orders cro ON cco.order_id = cro.order_id
JOIN pizza_runner.pizza_names pn ON cco.pizza_id = pn.pizza_id
WHERE cro.cancellation IS NULL;

-- Q2: Total revenue with $1 charge per extra
WITH base_pizza_revenue AS (
    SELECT 
        SUM(CASE 
            WHEN pn.pizza_name = 'Meatlovers' THEN 12
            WHEN pn.pizza_name = 'Vegetarian' THEN 10
            ELSE 0 
        END) AS base_total
    FROM pizza_runner.clean_customer_orders cco
    JOIN pizza_runner.clean_runner_orders cro ON cco.order_id = cro.order_id
    JOIN pizza_runner.pizza_names pn ON cco.pizza_id = pn.pizza_id
    WHERE cro.cancellation IS NULL
),
extras_revenue AS (
    SELECT COUNT(UNNEST(STRING_TO_ARRAY(cco.extras, ', '))) * 1 AS extras_total
    FROM pizza_runner.clean_customer_orders cco
    JOIN pizza_runner.clean_runner_orders cro ON cco.order_id = cro.order_id
    WHERE cro.cancellation IS NULL
    AND cco.extras IS NOT NULL
    AND cco.extras NOT IN ('', 'null')
)
SELECT 
    b.base_total,
    e.extras_total,
    (b.base_total + e.extras_total) AS grand_total
FROM base_pizza_revenue b, extras_revenue e;

-- Q3: Create runner ratings table
CREATE TABLE pizza_runner.runner_ratings (
    order_id INT,
    runner_id INT,
    rating INT CHECK (rating BETWEEN 1 AND 5)
);

INSERT INTO pizza_runner.runner_ratings ("order_id", "rating") VALUES
    (1, 2), (2, 1), (3, 4), (4, 5),
    (5, 2), (7, 2), (8, 2), (10, 1);

-- Q4: Join all delivery information together
SELECT 
    cco.customer_id,
    cco.order_id,
    cro.runner_id,
    rr.rating,
    cco.order_time,
    cro.pickup_time,
    (cro.pickup_time - cco.order_time) AS prep_time,
    cro.duration,
    ROUND((distance / duration) * 60.0, 2)::numeric AS speed_kmh,
    COUNT(cco.pizza_id) AS total_pizzas
FROM pizza_runner.clean_customer_orders cco
JOIN pizza_runner.clean_runner_orders cro ON cco.order_id = cro.order_id
JOIN pizza_runner.runner_ratings rr ON cco.order_id = rr.order_id
GROUP BY 
    cco.customer_id, cco.order_id, cro.runner_id, rr.rating,
    cco.order_time, cro.pickup_time, cro.duration, cro.distance
ORDER BY cco.order_id;

-- Q5: Revenue left after paying runners $0.30 per km
WITH runner_amount AS (
    SELECT 
        runner_id,
        SUM(distance) AS total_distance,
        SUM(distance) * 0.3 AS total_payment
    FROM pizza_runner.clean_runner_orders
    WHERE cancellation IS NULL
    GROUP BY runner_id
),
runner_payment AS (
    SELECT SUM(total_payment) AS runner_total FROM runner_amount
),
total_revenue AS (
    SELECT 
        SUM(CASE 
            WHEN pizza_name = 'Meatlovers' THEN 12
            WHEN pizza_name = 'Vegetarian' THEN 10 
        END) AS total_revenue
    FROM pizza_runner.clean_customer_orders cco
    JOIN pizza_runner.clean_runner_orders cro ON cco.order_id = cro.order_id
    JOIN pizza_runner.pizza_names pn ON cco.pizza_id = pn.pizza_id
    WHERE cro.cancellation IS NULL
)
SELECT total_revenue - runner_total AS actual_revenue
FROM total_revenue
CROSS JOIN runner_payment;
