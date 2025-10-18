# 🍕 Food Delivery System — SQL Data Analytics Project

## 🔹 Introduction

The **Food Delivery System** is an end-to-end **SQL-based data analytics project** that simulates a real-world online food delivery platform.  
It demonstrates a comprehensive approach to **database design**, **data generation**, and **complex SQL analysis** to uncover actionable business insights regarding customer behavior, restaurant performance, and delivery logistics.


---

## 🔹 Project Details

- **Title**: Food Delivery System  
- **Level**: Advanced  
- **Database**: `food_delivery_db` (MySQL)  
- **Focus Areas**: Data Modeling, Advanced Analytical SQL, Window Functions, CTEs, Performance Queries, Growth Metrics, and Trend Analysis  

---

## 🛠️ Technologies Used

| Category | Tool / Library |
|-----------|----------------|
| **Database** | MySQL |
| **DB Management** | MySQL Workbench |
| **Data Generation** | Python (`Faker`, `CSV` libraries) |
| **Version Control** | Git & GitHub |

---
<img width="850" height="570" alt="image" src="https://github.com/Gokul66-ub/sql_p3_food_delivery_system/blob/main/Gemini_Generated_Image_u70ketu70ketu70k.png" />

## 🧱 Database Schema (ER Diagram)

The system is built on a **normalized relational database model** designed to ensure data integrity and query efficiency.  
It comprises **five core tables** that interact to capture the entire order lifecycle.

<img src="./er diagram.png" alt="Entity-Relationship Diagram" width="800">

```sql
CREATE DATABASE zomato_db;

USE zomato_db;

--Create Tables

-- Table for storing customer information
CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    customer_name VARCHAR(25),
    reg_date DATE
);

-- Table for storing restaurant information
CREATE TABLE restaurants (
    restaurant_id INTEGER PRIMARY KEY,
    restaurant_name VARCHAR(55),
    city VARCHAR(15),
    opening_hours VARCHAR(55)
);

-- Table for storing rider information
CREATE TABLE riders (
    rider_id INTEGER PRIMARY KEY,
    rider_name VARCHAR(55),
    sign_up_date DATE
);

-- Central table for storing order details
CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    restaurant_id INTEGER REFERENCES restaurants(restaurant_id),
    order_item VARCHAR(55),
    order_date DATE,
    order_time TIME,
    order_status VARCHAR(55),
    total_amount DOUBLE PRECISION
);

-- Table for tracking delivery status and rider assignment
CREATE TABLE deliveries (
    delivery_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id),
    delivery_status VARCHAR(35),
    delivery_time TIME,
    rider_id INTEGER REFERENCES riders(rider_id)
);
```
### Data Analysis and Finding

**1.Write a query to find top 5 most frequently ordered dish by Priya Sharma over last 1 year**
```sql

WITH top5_dish as (
    SELECT 
    c.customer_name,
    o.order_item,
    COUNT(*) AS order_count,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS freq_rank
FROM customers c
INNER JOIN orders o
    ON c.customer_id = o.customer_id
WHERE c.customer_name = 'Gagan Gupta'
  AND o.order_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
GROUP BY c.customer_name, o.order_item
                      )
SELECT order_item
FROM top5_dish
WHERE freq_rank<=5
```
**2.Identify the time slots during which the most orders are placed based on 2hour intervals**
```sql

SELECT
    FLOOR(EXTRACT(HOUR FROM order_time)/2)*2 as start_time,
    FLOOR(EXTRACT(HOUR FROM order_time)/2)*2 +2 as end_time,
    COUNT(*) AS order_count
FROM orders
GROUP BY 1,2
ORDER BY order_count DESC
```
**3.Find the average order value per customer who has placed more than 18 orders and then return customer_name and avg order value**
```sql
SELECT 
    o.customer_id,
    c.customer_name,
    ROUND(AVG(total_amount),2) as average_order_value
FROM orders o
INNER JOIN customers c
USING(customer_id)
GROUP BY o.customer_id,c.customer_name
HAVING count(*)>18
ORDER BY average_order_value DESC
```
**4.List the customers who have spent more than 30K in total on food orders and then return customer_name and id**
```sql

SELECT
    customer_id,
    c.customer_name,
    ROUND(SUM(o.total_amount),2) as amount_spent
FROM orders o
INNER JOIN customers c
USING(customer_id)
GROUP BY o.customer_id
HAVING SUM(o.total_amount)>35000
ORDER BY amount_spent DESC
```
**5.Write a query to find orders that were placed but not delivered and then return each restuarant name,city and number of not delivered orders**
```sql
SELECT 
    r.restaurant_name,
    r.city,
    count(*) as order_not_delivered
FROM orders o
INNER JOIN restaurants r
USING(restaurant_id)
WHERE order_status<>'Delivered'
GROUP BY r.restaurant_name,r.city
ORDER BY order_not_delivered DESC
```
**6.Write a query to rank restaurants by their total revenue from the last year,including their name,total revenue and rank within their city**

```sql

SELECT 
    r.restaurant_id,
    r.restaurant_name,
    r.city,
    ROUND(SUM(total_amount),2) as total_revenue,
    DENSE_RANK() OVER(PARTITION BY city ORDER BY ROUND(SUM(total_amount),2) DESC) AS rank_city
FROM orders o
INNER JOIN restaurants r
USING(restaurant_id)
WHERE order_time>DATE_SUB(CURDATE(),INTERVAL 1 YEAR)
GROUP BY r.restaurant_id,r.restaurant_name,r.city
ORDER BY city,total_revenue DESC
```
**7.Write a query to identify the most popular dish in each city based on the number of orders**

```sql

WITH n_orders AS (
    SELECT
        r.city,
        o.order_item,
        DENSE_RANK() OVER(PARTITION BY city ORDER BY count(*) DESC) AS rank_city
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
```
**8.Write a query to find customers who haven't placed an order in 2025 but did in 2024**

```sql
SELECT
    DISTINCT customer_id
FROM orders
WHERE EXTRACT(YEAR FROM order_date)=2024 AND
      customer_id NOT IN(
          SELECT 
              customer_id
          FROM orders
          WHERE EXTRACT(YEAR FROM order_date)=2025
)
```
**9.Write a query to calculate and compare the order cancellation rate for each restaurant between the current year and the previous year**
```sql
WITH rate_2025 AS(
    SELECT 
        restaurant_id,
        restaurant_name,
        r.city,
        ROUND(SUM(CASE WHEN o.order_status='Cancelled' THEN 1 ELSE 0 END)*100/COUNT(*),2) AS cancellation_rate_25
    FROM orders o
    INNER JOIN restaurants r
    USING(restaurant_id)
    WHERE EXTRACT(YEAR FROM o.order_date)=2025
    GROUP BY r.restaurant_name,r.restaurant_id,r.city
),
rate_2024 AS(
    SELECT
        restaurant_id,
        restaurant_name,
        r.city,
        ROUND(SUM(CASE WHEN o.order_status='Cancelled' THEN 1 ELSE 0 END)*100/COUNT(*),2) AS cancellation_rate_24
    FROM orders o
    INNER JOIN restaurants r
    USING(restaurant_id)
    WHERE EXTRACT(YEAR FROM o.order_date)=2024
    GROUP BY r.restaurant_name,r.restaurant_id,r.city
)

SELECT
    r1.restaurant_name,
    r1.city,
    r1.cancellation_rate_25,
    r2.cancellation_rate_24,
    ROUND(r1.cancellation_rate_25-r2.cancellation_rate_24,2) as rate_difference
FROM rate_2025 r1
LEFT JOIN rate_2024 r2
USING(restaurant_id)
ORDER BY rate_difference
```
**10.Write a query to determine each rider's average delivery time**
```sql
WITH rider_delivery_time AS (
    SELECT 
        r.rider_id,
        r.rider_name,
        GREATEST(TIMESTAMPDIFF(SECOND, o.order_time, d.delivery_time), 0) AS seconds_taken
    FROM orders o
    INNER JOIN deliveries d USING (order_id)
    INNER JOIN riders r USING (rider_id)
    WHERE d.delivery_status='Delivered'
)
SELECT 
    r.rider_id,
    r.rider_name,
    DATE_FORMAT(SEC_TO_TIME(ROUND(AVG(seconds_taken))), '%H:%i') AS average_delivery_time
FROM rider_delivery_time r
GROUP BY r.rider_id, r.rider_name
ORDER BY average_delivery_time;
```
**11.Write a query to find the monthly restaurant growth ratio by calculate the each restaurant's growth ratio based on the total number of delivered orders since its joining**

```sql
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
```
## 12.  Customer Segmentation by Total Spending

Segment customers into **'Gold'** or **'Silver'** groups based on their **total spending** compared to the **average total spending** of all customers.

- If a customer's total spending **exceeds** the average total spending per customer, label them as **'Gold'**.  
- Otherwise, label them as **'Silver'**.

Write a **SQL query** to determine, for each segment, the following:

1. **Total number of orders**  
2. **Total revenue (spending)**


```sql
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
    ROUND(SUM(amount_spend),2) AS total_spend
FROM customer_segment
GROUP BY customer_category;
```
**13.Write a query to calculate each rider's total monthly earning,assuming they earn 8% of the order amount**
```sql

SELECT 
    rider_id,
    DATE_FORMAT(order_date,'%Y-%m') AS month,
    ROUND(SUM(total_amount)*0.08,2) as monthly_earn
FROM orders o
INNER JOIN deliveries d
USING(order_id)
GROUP BY 1,2
ORDER BY 1,2
```
**14.Write a query to find the number of 5 star,4 star and 3 star raings each riders has.
    Riders receive this rating based on delivery time
    If orders are delivered less than 15 minutes of order recived time the rider gets 5 star rating
    IF they delivered 15 and 20 minut they get 4 star rating
    If they delivered after 20 minute they get 3 star rating**
```sql
WITH time_taken_riders AS (
SELECT 
    rider_id,
    TIMESTAMPDIFF(MINUTE,order_time,delivery_time) as minutes
FROM orders
INNER JOIN deliveries
USING(order_id)
WHERE delivery_status='Delivered'
),
rating AS (
SELECT 
    rider_id,
    CASE
        WHEN minutes<15 THEN '5 Star'
        WHEN minutes BETWEEN 15 AND 20 THEN '4 Star'
        ELSE '3 Star'
    END AS rating  
FROM time_taken_riders
)

SELECT
    rider_id,
    SUM(CASE WHEN rating='3 Star' THEN 1 ELSE 0 END) AS 3stars,
    SUM(CASE WHEN rating='4 Star' THEN 1 ELSE 0 END) AS 4stars,
    SUM(CASE WHEN rating='5 Star' THEN 1 ELSE 0 END) AS 5stars
FROM rating
GROUP BY rider_id
ORDER BY 4 DESC,3 DESC,2 DESC
```
**15.Write a query to find the analyze order frequency per day of the week and identify the peak day for each restaurant**
```sql
WITH weekday_count AS(
SELECT 
    restaurant_id,
    restaurant_name,
    city,
    DATE_FORMAT(order_date,'%W') AS weekday,
    COUNT(*) AS order_count
FROM orders
INNER JOIN restaurants
USING(restaurant_id)
GROUP BY 1,2,3,4
),
top_rank_res AS(
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
WHERE top_rank=1
```
**16.Write a query to calcualte the total revenue generated by each customer over all their orders**
```sql
SELECT
    customer_id,
    customer_name,
    ROUND(SUM(total_amount),2) AS total_revenue
FROM customers
INNER JOIN orders
USING(customer_id)
GROUP BY customer_id,customer_name
ORDER BY 3 DESC
```
**17.Write a query to identify sales trend by comparing each month's total sales to the  previous month**
```sql

WITH monthly_sales AS (
SELECT
    DATE_FORMAT(order_date,'%Y-%m') AS month,
    ROUND(SUM(total_amount),2) AS total_sales
FROM orders
GROUP BY month)

SELECT 
    *,
    LAG(total_sales) OVER(ORDER BY month) as prev_month_sales,
    ROUND(total_sales-COALESCE(LAG(total_sales) OVER(ORDER BY month),0),2) AS amount_diff
FROM monthly_sales
ORDER BY 1
```
**18.Write a query to evaluate rider efficiency by determining average delivery times and identifying those with the lowest and highest averages**
```sql

WITH avg_delivery_time AS (
SELECT 
    rider_id,
    ROUND(AVG(CASE
        WHEN delivery_time<order_time
        THEN TIMESTAMPDIFF(MINUTE,order_time,ADDTIME(delivery_time,'24:00:00'))
        ELSE TIMESTAMPDIFF(MINUTE,order_time,delivery_time)
    END),2) AS average_delivery_time
FROM orders
INNER JOIN deliveries
USING(order_id)
WHERE delivery_status='Delivered'
GROUP BY 1
),
rank_riders AS(
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
WHERE riders_rank=(SELECT MIN(riders_rank) FROM rank_riders) OR riders_rank=(SELECT MAX(riders_rank) FROM rank_riders)
```
**19.Write a query to track the popularity of specific order items over time and identify seasonal demand spikes**
```sql
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
season_orders AS(
SELECT
    Season,
    order_item,
    COUNT(*) as order_count,
    RANK() OVER(PARTITION BY Season ORDER BY COUNT(*) DESC) AS season_rank
FROM order_season
GROUP BY 1,2
)
SELECT 
    Season,
    GROUP_CONCAT(order_item SEPARATOR ',') AS top_items
FROM season_orders
WHERE season_rank=1
GROUP BY Season
 ```
**20.Write a query to rank each city based on the total revenue for last year 2024**
```sql

SELECT 
    city,
    ROUND(SUM(total_amount),2) AS total_revenue,
    RANK() OVER(ORDER BY SUM(total_amount) DESC) AS city_rank
FROM orders
INNER JOIN restaurants
USING(restaurant_id)
WHERE order_date BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY city
```
