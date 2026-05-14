-- ------------------------------------------------------------------------------------
-- Question 1: What is the total amount each customer spent at the restaurant?
-- ------------------------------------------------------------------------------------
SELECT 
    s.customer_id, 
    SUM(m.price) AS total_sales
FROM dannys_diner.sales s 
JOIN dannys_diner.menu m USING (product_id)
GROUP BY s.customer_id
ORDER BY total_sales DESC;

-- -------------------------------------------------------------------------------
-- Question 2: How many days has each customer visited the restaurant?
-- -------------------------------------------------------------------------------
SELECT 
    customer_id, 
    COUNT(DISTINCT order_date) AS days_visited
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY customer_id;

-- -------------------------------------------------------------------------------
-- Question 3: What was the first item from the menu purchased by each customer?
-- -------------------------------------------------------------------------------
WITH rank AS (
    SELECT 
        s.customer_id, 
        m.product_name, 
        RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date ASC) as ranks
    FROM dannys_diner.sales s
    JOIN dannys_diner.menu m 
    USING (product_id)
)
SELECT DISTINCT 
    customer_id, 
    product_name
FROM rank
WHERE ranks = 1;

-- -------------------------------------------------------------------------------
-- Question 4: What is the most purchased item on the menu and how many times was it purchased by all customers?
-- -------------------------------------------------------------------------------
SELECT 
    m.product_name, 
    COUNT(s.product_id) AS total_purchases
FROM dannys_diner.menu m 
JOIN dannys_diner.sales s USING (product_id)
GROUP BY m.product_name
ORDER BY total_purchases DESC
LIMIT 1;

-- -------------------------------------------------------------------------------
-- Question 5: Which item was the most popular for each customer?
-- -------------------------------------------------------------------------------
WITH popular AS (
    SELECT 
        s.customer_id, 
        m.product_name, 
        COUNT(s.product_id) AS order_count,
        RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS ranks
    FROM dannys_diner.sales s 
    JOIN dannys_diner.menu m USING (product_id)
    GROUP BY s.customer_id, m.product_name
)
SELECT 
    customer_id, 
    product_name, 
    order_count
FROM popular 
WHERE ranks = 1;

-- -------------------------------------------------------------------------------
-- Question 6: Which item was purchased first by the customer after they became a member?
-- -------------------------------------------------------------------------------
WITH ranking AS (
    SELECT 
        s.customer_id, 
        s.order_date, 
        m2.product_name,
        RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date ASC) as ranks
    FROM dannys_diner.sales s 
    JOIN dannys_diner.members m USING (customer_id)
    JOIN dannys_diner.menu m2 USING (product_id)
    WHERE s.order_date >= m.join_date
)
SELECT 
    customer_id, 
    product_name
FROM ranking
WHERE ranks = 1
ORDER BY customer_id;

-- -------------------------------------------------------------------------------
-- Question 7: Which item was purchased just before the customer became a member?
-- -------------------------------------------------------------------------------
WITH Old_ranking AS (
    SELECT 
        s.customer_id, 
        s.order_date, 
        m2.product_name,
        RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) as ranks
    FROM dannys_diner.sales s 
    JOIN dannys_diner.members m USING (customer_id)
    JOIN dannys_diner.menu m2 USING (product_id)
    WHERE s.order_date < m.join_date
)
SELECT 
    customer_id, 
    product_name
FROM Old_ranking
WHERE ranks = 1
ORDER BY customer_id;

-- -------------------------------------------------------------------------------
-- Question 8: What is the total items and amount spent for each member before they became a member?
-- -------------------------------------------------------------------------------
SELECT 
    s.customer_id, 
    COUNT(s.product_id) AS total_items, 
    SUM(m2.price) AS total_amount_spent
FROM dannys_diner.sales s 
JOIN dannys_diner.members m USING (customer_id)
JOIN dannys_diner.menu m2 USING (product_id)
WHERE s.order_date < m.join_date
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- -------------------------------------------------------------------------------
-- Question 9: If each $1 spent equates to 10 points and sushi has a 2x points multiplier. 
                how many points would each customer have?
-- -------------------------------------------------------------------------------
WITH points AS (
    SELECT 
        product_id,
        CASE 
            WHEN product_name = 'sushi' THEN price * 20
            ELSE price * 10 
        END AS points
    FROM dannys_diner.menu
)
SELECT 
    s.customer_id, 
    SUM(p.points) AS total_points
FROM dannys_diner.sales s 
JOIN points p USING (product_id)
GROUP BY s.customer_id 
ORDER BY s.customer_id;

-- -------------------------------------------------------------------------------
-- Question 10: In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi.
                how many points do customer A and B have at the end of January?
-- -------------------------------------------------------------------------------

with promo as (
select m.product_id , price*20 as ppoints
from menu m
),
points as (
select product_id,
		(case when product_name = 'sushi' then price*10*2
      else price*10
      end) as Points
from menu m
),
promotion as(
		select s.customer_id as customer_id,SUM(p.ppoints) as promos
		from sales s 
		join members m 
		using (customer_id)
		join promo as p
		using (product_id)
		where order_date between join_date and m.join_date+interval '6 days' 
		and extract (month from order_date)=1
		group by s.customer_id
),
pre_promo as (
		select s.customer_id,SUM(p.Points) as promos
		from sales s 
		join points as p
		using (product_id)
		join members m 
		using (customer_id)
		where order_date < join_date
		and extract (month from order_date)=1
		group by s.customer_id
),
post_promo as (
		select s.customer_id, coalesce(sum(p.Points), 0) as promos
		from sales s 
		join members m
		using (customer_id)
		join points as p
		using (product_id)
		where order_date > (m.join_date+interval '6 days') 
		and extract (month from order_date)=1
		group by s.customer_id
),
non_members AS (
    SELECT s.customer_id, SUM(p.Points) AS promos
    FROM sales s
    LEFT JOIN members m USING (customer_id)
    JOIN points AS p USING (product_id)
    WHERE m.join_date IS NULL 
      AND EXTRACT(month FROM order_date) = 1
    GROUP BY s.customer_id
)
SELECT 
    distinct_customers.customer_id,
    (COALESCE(p2.promos, 0) + 
     COALESCE(p1.promos, 0) + 
     COALESCE(p3.promos, 0) + 
     COALESCE(nm.promos, 0)) AS total_points
FROM (SELECT DISTINCT customer_id FROM sales) AS distinct_customers
LEFT JOIN pre_promo p2   ON distinct_customers.customer_id = p2.customer_id
LEFT JOIN promotion p1   ON distinct_customers.customer_id = p1.customer_id
LEFT JOIN post_promo p3  ON distinct_customers.customer_id = p3.customer_id
LEFT JOIN non_members nm ON distinct_customers.customer_id = nm.customer_id
ORDER BY distinct_customers.customer_id
