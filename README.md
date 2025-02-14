# SQL_Sales
This SQL project analyzes customer purchases and reward points distribution. It tracks spending, calculates points based on product categories, and ranks top products. Using **joins, window functions, and aggregation**, it provides insights into customer behavior and spending trends to refine loyalty programs. 🚀
Sure! Below is a sample README file that explains the project, tables, and queries included in the SQL script.

---

# Sales Database Project

## Overview
This project involves creating a sales database to analyze user behavior and purchases on a platform (e.g., Zomato). The database contains multiple tables to track user sign-ups, their purchases, and product details. Various SQL queries are written to answer business questions, such as the total amount spent by customers, the first product purchased, customer loyalty points, and more.

## Database Schema

The database consists of the following tables:

### 1. **goldusers_signup**
This table stores information about users who signed up for a gold membership.

- `userid`: The unique identifier for each user.
- `gold_signup_date`: The date the user became a gold member.

```sql
CREATE TABLE goldusers_signup (
    userid INTEGER,
    gold_signup_date DATE
);
```

### 2. **users**
This table stores information about users who signed up for the platform.

- `userid`: The unique identifier for each user.
- `signup_date`: The date the user signed up for the platform.

```sql
CREATE TABLE users (
    userid INTEGER,
    signup_date DATE
);
```

### 3. **sales**
This table tracks purchases made by users.

- `userid`: The unique identifier for each user who made the purchase.
- `created_date`: The date the purchase was made.
- `product_id`: The ID of the purchased product.

```sql
CREATE TABLE sales (
    userid INTEGER,
    created_date DATE,
    product_id INTEGER
);
```

### 4. **product**
This table stores product details.

- `product_id`: The unique identifier for each product.
- `product_name`: The name of the product.
- `price`: The price of the product.

```sql
CREATE TABLE product (
    product_id INTEGER,
    product_name TEXT,
    price INTEGER
);
```

## Queries

Below are some of the SQL queries used to extract insights from the database.

### 1. **Total Amount Spent by Each Customer**

```sql
SELECT sales.userid, SUM(product.price) AS total_amnt_spent
FROM sales
INNER JOIN product ON sales.product_id = product.product_id
GROUP BY sales.userid;
```

This query calculates the total amount spent by each customer.

### 2. **Number of Days Each Customer Visited**

```sql
SELECT sales.userid, COUNT(DISTINCT created_date) AS distinct_days
FROM sales
GROUP BY sales.userid;
```

This query calculates the number of distinct days each customer made a purchase.

### 3. **First Product Purchased by Each Customer**

```sql
SELECT * 
FROM (
    SELECT *, RANK() OVER (PARTITION BY userid ORDER BY created_date) AS rnk
    FROM sales
) sales 
WHERE rnk = 1;
```

This query finds the first product purchased by each customer.

### 4. **Most Purchased Product by All Customers**

```sql
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
```

This query identifies the most purchased item on the platform and how many times it was purchased by each customer.

### 5. **Most Popular Product for Each Customer**

```sql
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
```

This query finds the most popular product for each customer based on their purchase history.

### 6. **First Product Purchased After Becoming a Member**

```sql
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
```

This query determines the first product purchased by a customer after they became a gold member.

### 7. **First Product Purchased Before Becoming a Member**

```sql
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
```

This query identifies the first product purchased by a customer just before becoming a gold member.

### 8. **Total Orders and Amount Spent Before Becoming a Member**

```sql
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
```

This query calculates the total number of orders and amount spent for each member before they became a gold member.

### 9. **Zomato Points**

- **(a) Calculate Points Collected by Each Customer**

```sql
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
```

This query calculates the total points collected by each customer based on their purchases.

- **(b) Most Points Awarded Product**

```sql
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
```

This query identifies the product that has accumulated the most points till now.

### 10. **Zomato Points in the First Year of Membership**

```sql
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
```

This query calculates the points earned by a customer during their first year of gold membership.

### 11. **Rank Transactions by Customer**

```sql
SELECT *, 
       RANK() OVER (PARTITION BY userid ORDER BY created_date) AS rnk 
FROM sales;
```

This query ranks all transactions made by customers.

### 12. **Rank Transactions for Gold Members**

```sql
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
```

This query ranks the transactions of each gold member and marks non-gold member transactions as 'NA'.

---

## Conclusion

This project demonstrates how to design a relational database and use SQL queries to gain insights into customer behavior, product purchases, loyalty program participation, and points accumulation. The queries provide useful information for business analysis and decision-making.

