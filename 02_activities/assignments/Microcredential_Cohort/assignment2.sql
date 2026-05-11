/* ASSIGNMENT 2 */
--Please write responses between the QUERY # and END QUERY blocks
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product


But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a blank for the first column with
nulls, and 'unit' for the second column with nulls. 

**HINT**: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same. */
--QUERY 1

SELECT 
	product_name || ', ' || COALESCE(product_size, "") || ' (' || COALESCE(product_qty_type,"unit") || ')' AS list
FROM product;


--END QUERY


--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). 
Filter the visits to dates before April 29, 2022. */
--QUERY 2

SELECT
	*, 
	DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY market_date ASC) AS counter
FROM customer_purchases
WHERE market_date < "2022-04-29";


--END QUERY


/* 2. Reverse the numbering of the query so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit.
HINT: Do not use the previous visit dates filter. */
--QUERY 3

WITH ordered_customer_purchases AS (
	SELECT
		*, 
		ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY market_date DESC, transaction_time DESC) AS counter
	FROM customer_purchases)

SELECT 
	product_id, vendor_id, market_date, customer_id, quantity, cost_to_customer_per_qty, transaction_time
FROM ordered_customer_purchases
WHERE counter = 1;


--END QUERY


/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. 

You can make this a running count by including an ORDER BY within the PARTITION BY if desired.
Filter the visits to dates before April 29, 2022. */
--QUERY 4

SELECT
	*,
	COUNT(*) OVER (PARTITION BY customer_id, product_id) AS count_per_product
FROM customer_purchases
WHERE market_date < "2022-04-29";


--END QUERY


-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */
--QUERY 5

SELECT
	product_name,
	CASE 
		WHEN INSTR(product_name," - ") > 0 THEN TRIM(SUBSTR(product_name, INSTR(product_name, " - ") + 3))  
		ELSE NULL 
	END AS description
FROM product;


--END QUERY


/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */
--QUERY 6


SELECT
	product_name,
	CASE 
		WHEN INSTR(product_name," - ") > 0 THEN TRIM(SUBSTR(product_name, INSTR(product_name, " - ") + 3))  
		ELSE NULL 
	END AS description
FROM product
WHERE product_size REGEXP  '[0-9]';

--END QUERY


-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */
--QUERY 7

WITH total_sales_per_day AS (
	SELECT
		market_date,
		SUM(quantity * cost_to_customer_per_qty) AS total_sales
	FROM customer_purchases
	GROUP BY market_date)
	
SELECT
	market_date,
	MAX(total_sales) AS total_sales
FROM total_sales_per_day
UNION
SELECT
	market_date,
	MIN(total_sales)
FROM total_sales_per_day


--END QUERY



/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */
--QUERY 8

WITH vendor_products AS (
    SELECT DISTINCT
        vi.vendor_id,
        vi.product_id,
        vi.original_price
    FROM vendor_inventory vi
)
SELECT
    v.vendor_name,
    p.product_name,
    SUM(5 * vp.original_price) AS amount
FROM vendor_products vp
CROSS JOIN customer c
JOIN vendor v 
    ON v.vendor_id = vp.vendor_id
JOIN product p 
    ON p.product_id = vp.product_id
GROUP BY
    v.vendor_name,
    p.product_name;


--END QUERY


-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */
--QUERY 9


CREATE TABLE "product_units" (
  "product_id" int(11) NOT NULL,
  "product_name" varchar(45) DEFAULT NULL,
  "product_size" varchar(45) DEFAULT NULL,
  "product_category_id" int(11) NOT NULL,
  "product_qty_type" varchar(45) DEFAULT NULL,
  "snapshot_timestamp" date NOT NULL,
  PRIMARY KEY ("product_id","product_category_id"),
  CONSTRAINT "fk_product_product_category1" FOREIGN KEY ("product_category_id") REFERENCES "product_category" ("product_category_id")
);

INSERT INTO product_units
SELECT
	*,
	CURRENT_TIMESTAMP AS snapshot_timestamp
FROM product
WHERE product_qty_type = 'unit';


--END QUERY


/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */
--QUERY 10


INSERT INTO product_units 
SELECT
	24, product_name, product_size, product_category_id, product_qty_type,
	CURRENT_TIMESTAMP
FROM product
WHERE product_name = "Cut Zinnias Bouquet"
LIMIT 1;

--END QUERY


-- DELETE
/* 1. Delete the older record for whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/
--QUERY 11

DELETE FROM product_units
WHERE product_name = "Cut Zinnias Bouquet" 
	AND snapshot_timestamp <> (SELECT MAX(snapshot_timestamp) FROM product_units);


--END QUERY


-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */
--QUERY 12

ALTER TABLE product_units
ADD current_quantity INT;

WITH latest_inventory AS (
    SELECT
        vendor_id,
        product_id,
        quantity,
        ROW_NUMBER() OVER (
            PARTITION BY vendor_id, product_id
            ORDER BY market_date DESC
        ) AS rn
    FROM vendor_inventory
),
current_quantity_table AS (
    SELECT
        product_id,
        SUM(COALESCE(quantity, 0)) AS current_quantity
    FROM latest_inventory
    WHERE rn = 1
    GROUP BY product_id
)
UPDATE product_units
SET current_quantity = COALESCE((
    SELECT cqt.current_quantity
    FROM current_quantity_table cqt
    WHERE cqt.product_id = product_units.product_id
), 0);


--END QUERY



