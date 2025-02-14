-- Create database
CREATE DATABASE sales_db;
USE sales_db;

-- Create gold users table
DROP TABLE IF EXISTS goldusers_signup;
CREATE TABLE goldusers_signup (
    userid INTEGER,
    gold_signup_date DATE
); 

INSERT INTO goldusers_signup (userid, gold_signup_date) 
VALUES 
    (1, '2017-09-22'),
    (3, '2017-04-21');

Create users table
DROP TABLE IF EXISTS users;
CREATE TABLE users (
    userid INTEGER,
    signup_date DATE
); 

INSERT INTO users (userid, signup_date) 
VALUES 
    (1, '2014-09-02'),
    (2, '2015-01-15'),
    (3, '2014-04-11');

Create sales table
DROP TABLE IF EXISTS sales;
CREATE TABLE sales (
    userid INTEGER,
    created_date DATE,
    product_id INTEGER
); 

INSERT INTO sales (userid, created_date, product_id) 
VALUES 
    (1, '2017-04-19', 2),
    (3, '2019-12-18', 1),
    (2, '2020-07-20', 3),
    (1, '2019-10-23', 2),
    (1, '2018-03-19', 3),
    (3, '2016-12-20', 2),
    (1, '2016-11-09', 1),
    (1, '2016-05-20', 3),
    (2, '2017-09-24', 1),
    (1, '2017-03-11', 2),
    (1, '2016-03-11', 1),
    (3, '2016-11-10', 1),
    (3, '2017-12-07', 2),
    (3, '2016-12-15', 2),
    (2, '2017-11-08', 2),
    (2, '2018-09-10', 3);

Create product table
DROP TABLE IF EXISTS product;
CREATE TABLE product (
    product_id INTEGER,
    product_name TEXT,
    price INTEGER
); 

INSERT INTO product (product_id, product_name, price) 
VALUES
    (1, 'p1', 980),
    (2, 'p2', 870),
    (3, 'p3', 330);

-- Verify data
SELECT * FROM sales;
SELECT * FROM product;
SELECT * FROM goldusers_signup;
SELECT * FROM users;

-- 1. What is the total amount each customer spent on Zomato?
SELECT sales.userid, SUM(product.price) AS total_amnt_spent
FROM sales
INNER JOIN product ON sales.product_id = product.product_id
GROUP BY sales.userid;

-- 2. How many days each customer visited zomato?
SELECT sales.userid, COUNT(DISTINCT created_date) AS distinct_days
FROM sales
GROUP BY sales.userid;

-- 3. What was the first product purchased by each customer?
SELECT * 
FROM (
    SELECT *, RANK() OVER (PARTITION BY userid ORDER BY created_date) AS rnk
    FROM sales
) sales 
WHERE rnk = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customer?
SELECT sales.userid, COUNT(sales.product_id) AS cnt
FROM sales 
JOIN (
    SELECT product_id
    FROM sales
    GROUP BY product_id
    ORDER BY COUNT(product_id) DESC
    LIMIT 1
) AS top_product
ON sales.product_id = top_product.product_id
GROUP BY sales.userid;

-- 5. Which item was the most popular for each customer?
SELECT * 
FROM (
    SELECT *, RANK() OVER (PARTITION BY userid ORDER BY cnt DESC) AS rnk 
    FROM (
        SELECT userid, product_id, COUNT(product_id) AS cnt
        FROM sales
        GROUP BY userid, product_id
    ) AS product_count
) AS ranked_products
WHERE rnk = 1;

-- 6. Which item was purchased first by the customer after they became a member?
select * from(
	select c.*, rank() over(partition by userid order by created_date) rnk 
	from(
		select sales.userid, sales.created_date, sales.product_id, goldusers_signup.gold_signup_date 
		from sales 
		inner join goldusers_signup 
		on sales.userid = goldusers_signup.userid 
		and created_date>=gold_signup_date
	) c
)d 
where rnk=1;

-- 7. Which item was purchased just before the customer became a member?
SELECT * 
FROM (
    SELECT c.*, 
           RANK() OVER (PARTITION BY userid ORDER BY created_date DESC) AS rnk 
    FROM (
        SELECT sales.userid, 
               sales.created_date, 
               sales.product_id, 
               goldusers_signup.gold_signup_date 
        FROM sales 
        INNER JOIN goldusers_signup 
        ON sales.userid = goldusers_signup.userid 
        AND created_date <= gold_signup_date
    ) c
) d 
WHERE rnk = 1;


-- 8. What is the total orders and amount spent for each member before they became a member?
SELECT 
    userid, 
    COUNT(created_date) AS order_purchased, 
    SUM(price) AS total_amt_spent 
FROM (
    SELECT 
        sales.userid, 
        sales.created_date, 
        sales.product_id, 
        product.price 
    FROM sales 
    INNER JOIN goldusers_signup 
        ON sales.userid = goldusers_signup.userid 
        AND sales.created_date <= goldusers_signup.gold_signup_date
    INNER JOIN product 
        ON sales.product_id = product.product_id
) AS subquery
GROUP BY userid;

-- 9 if buying each product generate points 
-- 		(for example: 5rs = 2 Zomato points and each product has different purchasing points 
--      	(for example: P1 5rs = 1 Zomato point, P2 10rs = 5 Zomato pointsand P3 5rs = 1 Zomato point))
--  a. Calculate points collected by each customer 
--  b. for which product most points have been given till now.

-- a)
SELECT userid, 
       SUM(total_points) * 2.5 AS total_money_earned 
FROM (
    SELECT e.*, 
           amt / points AS total_points 
    FROM (
        SELECT d.*, 
               CASE 
                   WHEN product_id = 1 THEN 5 
                   WHEN product_id = 2 THEN 2 
                   WHEN product_id = 3 THEN 5 
                   ELSE 0 
               END AS points 
        FROM (
            SELECT c.userid, 
                   c.product_id, 
                   SUM(price) AS amt 
            FROM (
                SELECT sales.*, 
                       product.price 
                FROM sales 
                INNER JOIN product 
                ON sales.product_id = product.product_id
            ) c 
            GROUP BY userid, product_id
        ) d
    ) e
) f 
GROUP BY userid;

-- b)
SELECT * 
FROM (
    SELECT *, 
           RANK() OVER (ORDER BY total_points_earned DESC) AS rnk 
    FROM (
        SELECT product_id, 
               SUM(total_points) AS total_points_earned 
        FROM (
            SELECT e.*, 
                   amt / points AS total_points 
            FROM (
                SELECT d.*, 
                       CASE 
                           WHEN product_id = 1 THEN 5 
                           WHEN product_id = 2 THEN 2 
                           WHEN product_id = 3 THEN 5 
                           ELSE 0 
                       END AS points 
                FROM (
                    SELECT c.userid, 
                           c.product_id, 
                           SUM(price) AS amt 
                    FROM (
                        SELECT sales.*, 
                               product.price 
                        FROM sales 
                        INNER JOIN product 
                        ON sales.product_id = product.product_id
                    ) c 
                    GROUP BY userid, product_id
                ) d
            ) e
        ) f 
        GROUP BY product_id
    ) f
) g 
WHERE rnk = 1;

-- 10. In the first one year after a customer joins a gold program(including their join date) irrespective of what the customer has purchased they earn 5 Zomato points for every 10rs spent who earned more 1 or 3 and what was their points earnings in their first year?

SELECT c.*, product.price * 0.5 AS total_points_earned 
FROM (
    SELECT sales.userid, sales.created_date, sales.product_id, goldusers_signup.gold_signup_date 
    FROM sales 
    INNER JOIN goldusers_signup 
    ON sales.userid = goldusers_signup.userid 
    AND created_date >= gold_signup_date 
    AND created_date <= DATE_ADD(gold_signup_date, INTERVAL 1 YEAR)
) c 
INNER JOIN product 
ON c.product_id = product.product_id;

-- 11. Rank all the transaction of the customers
SELECT *, 
       RANK() OVER (PARTITION BY userid ORDER BY created_date) AS rnk 
FROM sales;

-- 12. Rank all the transactions for each member whenever they are a zomato gold member for every non gold member transaction mark as NA
SELECT e.*, 
       CASE 
           WHEN rnk = '0' THEN 'NA' 
           ELSE rnk 
       END AS rnkk 
FROM (
    SELECT c.*, 
           CAST((
               CASE 
                   WHEN gold_signup_date IS NULL THEN 0
                   ELSE RANK() OVER (PARTITION BY userid ORDER BY created_date DESC) 
               END) AS CHAR) AS rnk 
    FROM (
        SELECT sales.userid, 
               sales.created_date, 
               sales.product_id, 
               goldusers_signup.gold_signup_date 
        FROM sales 
        LEFT JOIN goldusers_signup 
        ON sales.userid = goldusers_signup.userid 
        AND sales.created_date > goldusers_signup.gold_signup_date
    ) c
) e;




