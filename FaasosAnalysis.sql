drop table if exists driver;
CREATE TABLE driver(driver_id integer,reg_date date); 

INSERT INTO driver(driver_id,reg_date) 
 VALUES (1,'01-01-2021'),
(2,'01-03-2021'),
(3,'01-08-2021'),
(4,'01-15-2021');


drop table if exists ingredients;
CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60)); 

INSERT INTO ingredients(ingredients_id ,ingredients_name) 
 VALUES (1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');

drop table if exists rolls;
CREATE TABLE rolls(roll_id integer,roll_name varchar(30)); 

INSERT INTO rolls(roll_id ,roll_name) 
 VALUES (1	,'Non Veg Roll'),
(2	,'Veg Roll');

drop table if exists rolls_recipes;
CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24)); 

INSERT INTO rolls_recipes(roll_id ,ingredients) 
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');

drop table if exists driver_order;
CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time datetime,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
 VALUES(1,1,'01-01-2021 18:15:34','20km','32 minutes',''),
(2,1,'01-01-2021 19:10:54','20km','27 minutes',''),
(3,1,'01-03-2021 00:12:37','13.4km','20 mins','NaN'),
(4,2,'01-04-2021 13:53:03','23.4','40','NaN'),
(5,3,'01-08-2021 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'01-08-2020 21:30:45','25km','25mins',null),
(8,2,'01-10-2020 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'01-11-2020 18:50:20','10km','10minutes',null);


drop table if exists customer_orders;
CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date datetime);
INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
values (1,101,1,'','','01-01-2021  18:05:02'),
(2,101,1,'','','01-01-2021 19:00:52'),
(3,102,1,'','','01-02-2021 23:51:23'),
(3,102,2,'','NaN','01-02-2021 23:51:23'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,2,'4','','01-04-2021 13:23:46'),
(5,104,1,null,'1','01-08-2021 21:00:29'),
(6,101,2,null,null,'01-08-2021 21:03:13'),
(7,105,2,null,'1','01-08-2021 21:20:29'),
(8,102,1,null,null,'01-09-2021 23:54:33'),
(9,103,1,'4','1,5','01-10-2021 11:22:59'),
(10,104,1,null,null,'01-11-2021 18:34:49'),
(10,104,1,'2,6','1,4','01-11-2021 18:34:49');

select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;


-- 1. how many rolls were ordered ?

SELECT COUNT(roll_id) AS no_of_ordered_rolls
FROM customer_orders;


-- 2. how many unique customers were made ?

SELECT COUNT(DISTINCT customer_id) AS unique_customers
FROM customer_orders;

--3. how many successful orders were delivered by each driver ?

UPDATE driver_order SET cancellation = null
WHERE order_id IN (1,2,3,4,5,7,8, 10)

SELECT driver_id, count(*) AS successful_orders
FROM driver_order
WHERE cancellation IS NULL 
GROUP BY driver_id;


-- 4. how many of each roll type was delivered ?

SELECT r.roll_name, COUNT(*) AS no_of_rolls_delivered
FROM rolls r
JOIN customer_orders c ON r.roll_id = c.roll_id
JOIN driver_order d ON c.order_id = d.order_id
WHERE d.cancellation IS NULL
GROUP BY r.roll_name;


-- 5. how many veg and non veg rolls were ordered by each customer ?

SELECT c.customer_id, r.roll_name, COUNT(*) AS no_of_rolls_ordered
FROM rolls r
JOIN customer_orders c ON r.roll_id = c.roll_id
GROUP BY c.customer_id, r.roll_name;


-- 6. what was the maximum number of rolls delivered in a single order ?

SELECT TOP 1 c.order_id, c.customer_id, COUNT(c.roll_id) as max_no_of_rolls_delivered
FROM customer_orders c 
JOIN driver_order d ON c.order_id = d.order_id
WHERE d.cancellation IS NULL 
GROUP BY c.order_id, c.customer_id
ORDER BY max_no_of_rolls_delivered DESC;


-- 7. for each customer, how many delivered rolls had atleast 1 change and how many had no changes ?

UPDATE customer_orders SET not_include_items = NULL
WHERE order_id IN (1,2,3);

UPDATE customer_orders SET extra_items_included = NULL
WHERE order_id IN (1,2,3,4);

WITH cte AS (
SELECT c.*, CASE WHEN c.not_include_items IS NULL AND c.extra_items_included IS NULL THEN 'No Change' ELSE 'Change' END AS col_chg
FROM customer_orders c 
JOIN driver_order d ON c.order_id = d.order_id
WHERE d.cancellation IS NULL
)
SELECT customer_id, 
COUNT(CASE WHEN col_chg = 'No Change' THEN roll_id END) AS no_change, 
COUNT(CASE WHEN col_chg = 'Change' THEN roll_id END) AS atleast_1_change 
FROM cte
GROUP BY customer_id;


-- 8. how many rolls were delivered that had both exclusions and extras ?

SELECT *
FROM customer_orders c 
JOIN driver_order d ON c.order_id = d.order_id AND (c.not_include_items IS NOT NULL AND c.extra_items_included IS NOT NULL)
WHERE d.cancellation IS NULL;


-- 9. what was total number of rolls ordered for each hour of the day ?

SELECT DAY(order_date) AS day , DATEPART(HOUR, order_date) AS hour_of_the_day, COUNT(*) AS num_of_rolls
FROM customer_orders
GROUP BY DAY(order_date), DATEPART(HOUR, order_date)
ORDER BY 1;


-- 10. what was the total number of rolls ordered for each day of the week

SELECT DATEPART(WEEK, order_date) AS week_no, DAY(order_date) AS day, DATENAME(DW, order_date) AS day_name, COUNT(DISTINCT order_id) AS num_of_rolls
FROM customer_orders
GROUP BY DATEPART(WEEK, order_date), DAY(order_date), DATENAME(DW, order_date)
ORDER BY 1;


-- 11. what was the average time in minutes it took for each drivers to arrive at the faasos HQ to pickup the order ?

WITH cte AS (
SELECT DISTINCT d.order_id, d.driver_id, c.order_date, d.pickup_time 
FROM driver_order d
JOIN customer_orders c ON d.order_id = c.order_id AND cancellation IS NULL
)
SELECT driver_id, SUM(ABS(DATEPART(MINUTE, order_date) - DATEPART(MINUTE, pickup_time))) / COUNT(*) AS avg_of_each_drivers
FROM cte
GROUP BY driver_id;


-- 12. is there any relationship between the number of rolls and how long the order takes to prepare ?

SELECT  d.order_id, COUNT(c.roll_id) AS no_of_rolls, CONCAT(DATEPART(MINUTE, pickup_time - order_date), ' min') AS time_took_to_prepare
FROM driver_order d
JOIN customer_orders c ON d.order_id = c.order_id AND cancellation IS NULL
GROUP BY d.order_id, DATEPART(MINUTE, pickup_time - order_date)
ORDER BY order_id;


-- 13. what was the average distance travelled for each customer ?

SELECT customer_id, CONCAT(AVG(CAST(distance AS INT)), ' km') AS avg_distance_travelled
FROM (
SELECT DISTINCT c.customer_id, LEFT(d.distance, 2) AS distance
FROM driver_order d
JOIN customer_orders c ON d.order_id = c.order_id AND cancellation IS NULL
) a
GROUP BY customer_id;



-- 14. what was the difference between the longest and shortest delivery times for all orders ?

SELECT CONCAT(MAX(CAST(LEFT(duration, 2) AS INT)) - MIN(CAST(LEFT(duration, 2) AS INT)), ' min') AS time_diff
FROM driver_order;


-- 15. what was the average speed for each driver for each delivery and do you notice any trend for these values ?

SELECT driver_id, CONCAT(AVG(CAST(LEFT(distance, 2) AS DECIMAL(5, 2)) / CAST(LEFT(duration, 2) AS DECIMAL(5, 2))), ' km/min') AS avg_speed
FROM driver_order
WHERE cancellation IS NULL
GROUP BY driver_id;


-- 16. what is the successful delivery percentage for each driver ?

SELECT driver_id, CONCAT(CAST(100.0 * SUM(CASE WHEN cancellation IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS INT), ' %') AS successful_percent
FROM driver_order
GROUP BY driver_id;
