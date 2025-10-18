-- Task 1. Write a query to find top 5 most frequently ordered dish by Priya Sharma over last 1 year

WITH top5_dish AS (
    SELECT 
        c.customer_name,
        o.order_item,
        COUNT(*) AS order_count,
        DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS freq_rank
    FROM customers c
    INNER JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE c.customer_name = 'Priya Sharma'
    AND o.order_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
    GROUP BY c.customer_name, o.order_item
)
SELECT 
    order_item
FROM top5_dish
WHERE freq_rank <= 5;

-- Task 2. Identify the time slots during which the most orders are placed based on 2hour intervals

SELECT
    FLOOR(EXTRACT(HOUR FROM order_time)/2)*2 AS start_time,
    FLOOR(EXTRACT(HOUR FROM order_time)/2)*2 + 2 AS end_time,
    COUNT(*) AS order_count
FROM orders
GROUP BY 1, 2
ORDER BY order_count DESC;

-- Task 3. Find the average order value per customer who has placed more than 18 orders and then return customer_name and avg order value

SELECT 
    o.customer_id,
    c.customer_name,
    ROUND(AVG(total_amount), 2) AS average_order_value
FROM orders o
INNER JOIN customers c
    USING(customer_id)
GROUP BY o.customer_id, c.customer_name
HAVING COUNT(*) > 18
ORDER BY average_order_value DESC;

-- Task 4. List the customers who have spent more than 30K in total on food orders and then return customer_name and id

SELECT
    customer_id,
    c.customer_name,
    ROUND(SUM(o.total_amount), 2) AS amount_spent
FROM orders o
INNER JOIN customers c
    USING(customer_id)
GROUP BY o.customer_id
HAVING SUM(o.total_amount) > 35000
ORDER BY amount_spent DESC;

-- Task 5. Write a query to find orders that were placed but not delivered and then return each restuarant name,city and number of not delivered orders

SELECT 
    r.restaurant_name,
    r.city,
    COUNT(*) AS order_not_delivered
FROM orders o
INNER JOIN restaurants r
    USING(restaurant_id)
WHERE order_status <> 'Delivered'
GROUP BY r.restaurant_name, r.city
ORDER BY order_not_delivered DESC;

-- Task 6. Write a query to rank restaurants by their total revenue from the last year,including their name,total revenue and rank within their city

SELECT 
    r.restaurant_id,
    r.restaurant_name,
    r.city,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    DENSE_RANK() OVER(PARTITION BY city ORDER BY ROUND(SUM(total_amount), 2) DESC) AS rank_city
FROM orders o
INNER JOIN restaurants r
    USING(restaurant_id)
WHERE order_time > DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
GROUP BY r.restaurant_id, r.restaurant_name, r.city
ORDER BY city, total_revenue DESC;

-- Task 7. Write a query to identify the most popular dish in each city based on the number of orders

WITH n_orders AS (
    SELECT
        r.city,
        o.order_item,
        DENSE_RANK() OVER(PARTITION BY city ORDER BY COUNT(*) DESC) AS rank_city
    FROM orders o
    INNER JOIN restaurants r
        USING(restaurant_id)
    GROUP BY r.city, o.order_item
)
SELECT 
    city,
    order_item
FROM n_orders
WHERE rank_city = 1;

-- Task 8. Write a query to find customers who haven't placed an order in 2025 but did in 2024

SELECT
    DISTINCT customer_id
FROM orders
WHERE EXTRACT(YEAR FROM order_date) = 2024 
AND customer_id NOT IN (
    SELECT 
        customer_id
    FROM orders
    WHERE EXTRACT(YEAR FROM order_date) = 2025
);

-- Task 9. Write a query to calculate and compare the order cancellation rate for each restaurant between the current year and the previous year

WITH rate_2025 AS (
    SELECT 
        restaurant_id,
        restaurant_name,
        r.city,
        ROUND(SUM(CASE WHEN o.order_status = 'Cancelled' THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) AS cancellation_rate_25
    FROM orders o
    INNER JOIN restaurants r
        USING(restaurant_id)
    WHERE EXTRACT(YEAR FROM o.order_date) = 2025
    GROUP BY r.restaurant_name, r.restaurant_id, r.city
),
rate_2024 AS (
    SELECT
        restaurant_id,
        restaurant_name,
        r.city,
        ROUND(SUM(CASE WHEN o.order_status = 'Cancelled' THEN 1 ELSE 0 END) * 100 / COUNT(*), 2) AS cancellation_rate_24
    FROM orders o
    INNER JOIN restaurants r
        USING(restaurant_id)
    WHERE EXTRACT(YEAR FROM o.order_date) = 2024
    GROUP BY r.restaurant_name, r.restaurant_id, r.city
)
SELECT
    r1.restaurant_name,
    r1.city,
    r1.cancellation_rate_25,
    r2.cancellation_rate_24,
    ROUND(r1.cancellation_rate_25 - r2.cancellation_rate_24, 2) AS rate_difference
FROM rate_2025 r1
LEFT JOIN rate_2024 r2
    USING(restaurant_id)
ORDER BY rate_difference;

-- Task 10. Write a query to determine each rider's average delivery time

WITH rider_delivery_time AS (
    SELECT 
        r.rider_id,
        r.rider_name,
        GREATEST(TIMESTAMPDIFF(SECOND, o.order_time, d.delivery_time), 0) AS seconds_taken
    FROM orders o
    INNER JOIN deliveries d USING (order_id)
    INNER JOIN riders r USING (rider_id)
    WHERE d.delivery_status = 'Delivered'
)
SELECT 
    r.rider_id,
    r.rider_name,
    DATE_FORMAT(SEC_TO_TIME(ROUND(AVG(seconds_taken))), '%H:%i') AS average_delivery_time
FROM rider_delivery_time r
GROUP BY r.rider_id, r.rider_name
ORDER BY average_delivery_time;

-- Task 11. Write a query to find the monthly restaurant growth ratio by calculate the each restaurant's growth ratio based on the total number of delivered orders since its joining

WITH order_count AS (
    SELECT
        restaurant_id,
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        COUNT(*) AS total_orders
    FROM orders
    INNER JOIN deliveries USING(order_id)
    WHERE delivery_status = 'Delivered'
    GROUP BY restaurant_id, month
),
lagged AS (
    SELECT
        *,
        LAG(total_orders) OVER (PARTITION BY restaurant_id ORDER BY month) AS prev_month_orders
    FROM order_count
)
SELECT
    *,
    ROUND(
        (total_orders - prev_month_orders) * 100 / NULLIF(prev_month_orders, 0),
        2
    ) AS ratio
FROM lagged
ORDER BY restaurant_id, month;

-- Task 12. Customer Segmentation by Total Spending
-- Objective: Segment customers into 'Gold' or 'Silver' groups based on their total spending compared to the average total spending of all customers.

WITH customer_amount AS (
    SELECT 
        customer_id,
        SUM(total_amount) AS amount_spend,
        COUNT(*) AS total_orders
    FROM orders
    GROUP BY customer_id
),
avg_customer_spend AS (
    SELECT AVG(amount_spend) AS avg_spend
    FROM customer_amount
),
customer_segment AS (
    SELECT 
        customer_id,
        amount_spend,
        total_orders,
        CASE
            WHEN amount_spend > (SELECT avg_spend FROM avg_customer_spend) THEN 'Gold'
            ELSE 'Silver'
        END AS customer_category
    FROM customer_amount
)
SELECT
    customer_category,
    SUM(total_orders) AS total_orders,
    ROUND(SUM(amount_spend), 2) AS total_spend
FROM customer_segment
GROUP BY customer_category;

-- Task 13. Write a query to calculate each rider's total monthly earning,assuming they earn 8% of the order amount

SELECT 
    rider_id,
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    ROUND(SUM(total_amount) * 0.08, 2) AS monthly_earn
FROM orders o
INNER JOIN deliveries d
    USING(order_id)
GROUP BY 1, 2
ORDER BY 1, 2;

-- Task 14. Rider Rating Analysis by Delivery Time
-- Objective: Write a SQL query to determine, for each rider, how many 5-star, 4-star, and 3-star ratings they have earned.

WITH time_taken_riders AS (
    SELECT 
        rider_id,
        TIMESTAMPDIFF(MINUTE, order_time, delivery_time) AS minutes
    FROM orders
    INNER JOIN deliveries
        USING(order_id)
    WHERE delivery_status = 'Delivered'
),
rating AS (
    SELECT 
        rider_id,
        CASE
            WHEN minutes < 15 THEN '5 Star'
            WHEN minutes BETWEEN 15 AND 20 THEN '4 Star'
            ELSE '3 Star'
        END AS rating 
    FROM time_taken_riders
)
SELECT
    rider_id,
    SUM(CASE WHEN rating = '3 Star' THEN 1 ELSE 0 END) AS 3stars,
    SUM(CASE WHEN rating = '4 Star' THEN 1 ELSE 0 END) AS 4stars,
    SUM(CASE WHEN rating = '5 Star' THEN 1 ELSE 0 END) AS 5stars
FROM rating
GROUP BY rider_id
ORDER BY 4 DESC, 3 DESC, 2 DESC;

-- Task 15. Write a query to find the analyze order frequency per day of the week and identify the peak day for each restaurant

WITH weekday_count AS (
    SELECT 
        restaurant_id,
        restaurant_name,
        city,
        DATE_FORMAT(order_date, '%W') AS weekday,
        COUNT(*) AS order_count
    FROM orders
    INNER JOIN restaurants
        USING(restaurant_id)
    GROUP BY 1, 2, 3, 4
),
top_rank_res AS (
    SELECT
        *,
        RANK() OVER(PARTITION BY restaurant_id ORDER BY order_count DESC) AS top_rank
    FROM weekday_count
)
SELECT
    restaurant_id,
    restaurant_name,
    city,
    weekday,
    order_count
FROM top_rank_res
WHERE top_rank = 1;

-- Task 16. Write a query to calcualte the total revenue generated by each customer over all their orders

SELECT
    customer_id,
    customer_name,
    ROUND(SUM(total_amount), 2) AS total_revenue
FROM customers
INNER JOIN orders
    USING(customer_id)
GROUP BY customer_id, customer_name
ORDER BY 3 DESC;

-- Task 17. Write a query to identify sales trend by comparing each month's total sales to the  previous month

WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        ROUND(SUM(total_amount), 2) AS total_sales
    FROM orders
    GROUP BY month
)
SELECT 
    *,
    LAG(total_sales) OVER(ORDER BY month) AS prev_month_sales,
    ROUND(total_sales - COALESCE(LAG(total_sales) OVER(ORDER BY month), 0), 2) AS amount_diff
FROM monthly_sales
ORDER BY 1;

-- Task 18. Write a query to evaluate rider efficiency by determining average delivery times and identifying those with the lowest and highest averages

WITH avg_delivery_time AS (
    SELECT 
        rider_id,
        ROUND(AVG(CASE
            WHEN delivery_time < order_time
            THEN TIMESTAMPDIFF(MINUTE, order_time, ADDTIME(delivery_time, '24:00:00'))
            ELSE TIMESTAMPDIFF(MINUTE, order_time, delivery_time)
        END), 2) AS average_delivery_time
    FROM orders
    INNER JOIN deliveries
        USING(order_id)
    WHERE delivery_status = 'Delivered'
    GROUP BY 1
),
rank_riders AS (
    SELECT
        *,
        RANK() OVER(ORDER BY average_delivery_time) AS riders_rank
    FROM avg_delivery_time
)
SELECT 
    rider_id,
    average_delivery_time,
    riders_rank
FROM rank_riders
WHERE riders_rank = (SELECT MIN(riders_rank) FROM rank_riders) 
OR riders_rank = (SELECT MAX(riders_rank) FROM rank_riders);

-- Task 19. Write a query to track the popularity of specific order items over time and identify seasonal demand spikes

WITH order_season AS (
    SELECT 
        *,
        CASE
            WHEN MONTH(order_date) BETWEEN 3 AND 5 THEN 'Spring'
            WHEN MONTH(order_date) BETWEEN 6 AND 8 THEN 'Summer'
            WHEN MONTH(order_date) BETWEEN 9 AND 11 THEN 'Autumn'
            ELSE 'Winter'
        END AS Season
    FROM orders
),
season_orders AS (
    SELECT
        Season,
        order_item,
        COUNT(*) AS order_count,
        RANK() OVER(PARTITION BY Season ORDER BY COUNT(*) DESC) AS season_rank
    FROM order_season
    GROUP BY 1, 2
)
SELECT 
    Season,
    GROUP_CONCAT(order_item SEPARATOR ',') AS top_items
FROM season_orders
WHERE season_rank = 1
GROUP BY Season;

-- Task 20. Write a query to rank each city based on the total revenue for last year 2024

SELECT 
    city,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    RANK() OVER(ORDER BY SUM(total_amount) DESC) AS city_rank
FROM orders
INNER JOIN restaurants
    USING(restaurant_id)
WHERE order_date BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY city;