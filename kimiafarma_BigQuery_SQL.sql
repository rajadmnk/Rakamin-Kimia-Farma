
-- BRANCH

SELECT * FROM `kimia_farma.branch` LIMIT 5;

SELECT
  COUNT(*) AS total_rows, -- 1725
  COUNT(DISTINCT branch_id) AS total_unique_b_id, -- 1725
  COUNT(DISTINCT branch_category) AS total_unique_br_cat, -- 3
  COUNT(DISTINCT branch_name) AS total_uniqe_b_name, -- 3 
  COUNT(DISTINCT kota) AS total_uniqeu_kota, -- 70
  COUNT(DISTINCT provinsi) AS total_unique_provinsi -- 31
FROM `kimia_farma.branch`;

CREATE OR REPLACE TABLE `kimia_farma.branch_pre` AS 
  SELECT
    branch_id,
    TRIM(branch_category) AS branch_category,
    TRIM(branch_name) AS branch_name,
    TRIM(kota) AS city,
    TRIM(provinsi) AS province,
    rating
  FROM `kimia_farma.branch`;

-- null checks
-- no null values found in the branch table
SELECT
  COUNTIF(branch_id IS NULL) AS null_id,
  COUNTIF(branch_category IS NULL) AS null_cat,
  COUNTIF(branch_name IS NULL) AS null_brnch,
  COUNTIF(city IS NULL) AS null_city,
  COUNTIF(province IS NULL) AS null_prov,
  COUNTIF(rating IS NULL) AS null_rat
FROM `kimia_farma.branch_pre`;

-- duplicate check
-- no duplicate data found in the branch table
WITH dup AS (
SELECT *,
  ROW_NUMBER() OVER(PARTITION BY branch_id) rn
FROM `kimia_farma.branch_pre`
)
SELECT
COUNT(*)
FROM dup
WHERE rn > 1;


-- TRANSACTION

SELECT * FROM `kimia_farma.transaction` LIMIT 5;

SELECT
  
  COUNT(*) AS total_rows, -- 672458
  COUNT(DISTINCT transaction_id) AS total_unique_transaction, -- 672458
  COUNT(DISTINCT branch_id) AS total_unique_branch, -- 1725
  COUNT(DISTINCT customer_name) AS total_unique_cust, -- 264601
  COUNT(DISTINCT product_id) AS total_unique_prod, -- 150

  MIN(`date`) AS min_date, -- 2020-01-01
  MAX(`date`) AS max_date, -- 2023-12-30

  AVG(price) AS avg_price, -- 516347
  MIN(price) AS min_price, -- 2100
  MAX(price) AS max_price, -- 997500

  AVG(discount_percentage) AS avg_discount, -- 0.07
  MIN(discount_percentage) AS min_discount,-- 0
  MAX(discount_percentage) AS max_discount, -- 0.15

  MIN(rating) AS min_rat, -- 3
  MAX(rating) AS max_rat -- 5

FROM `kimia_farma.transaction`;


CREATE OR REPLACE TABLE `kimia_farma.transaction_pre` AS
  SELECT
    TRIM(transaction_id) AS transaction_id,
    `date`,
    branch_id,
    TRIM(customer_name) AS customer_name,
    TRIM(product_id) AS product_id,
    price,
    discount_percentage AS discount,
    (price - price * discount_percentage) AS sales,
    rating
  FROM `kimia_farma.transaction`;

-- null checks
-- no null values found in the transaction table
SELECT
  COUNTIF(transaction_id IS NULL) AS null_id,
  COUNTIF(`date` IS NULL) AS null_date,
  COUNTIF(branch_id IS NULL) AS null_branch,
  COUNTIF(customer_name IS NULL) AS null_cust,
  COUNTIF(product_id IS NULL) AS null_prod,
  COUNTIF(price IS NULL) AS null_price,
  COUNTIF(discount IS NULL) AS null_disc,
  COUNTIF(sales IS NULL) AS null_sale,
  COUNTIF(rating IS NULL) AS null_rate
FROM `kimia_farma.transaction_pre`;

-- duplicate checks
-- no duplicate data found in the transaction table
WITH dup AS (
  SELECT *,
  ROW_NUMBER() OVER(PARTITION BY transaction_id, customer_name
  ORDER BY `date`) rn 
FROM `kimia_farma.transaction_pre`
)
SELECT *
FROM dup
WHERE rn > 1;

-- Z-SCORE METHOD FOR SALES
-- Based on calculations using the z-score method with sales as the metric, no outliers were found

WITH z AS (
  SELECT
    AVG(sales) AS avg_sales, -- 477607
    MIN(sales) AS min_sales, -- 1785
    MAX(sales) AS max_sales, -- 997500
    STDDEV(sales) AS std_sales -- 264422
  FROM `kimia_farma.transaction_pre`
)
  SELECT
    a.transaction_id,
    a.sales,
    ROUND(
      (a.sales - z.avg_sales) / z.std_sales
    )
  FROM `kimia_farma.transaction_pre` a
  CROSS JOIN z
  WHERE ABS((a.sales - z.avg_sales) / z.std_sales) > 3;


-- IQR METHOD FOR SALES
-- Based on calculations using the IQR method with sales as the metric, no outliers were found.

WITH quartile AS (
  SELECT DISTINCT
    PERCENTILE_CONT(sales, 0.25) OVER () AS Q1, -- 273702
    PERCENTILE_CONT(sales, 0.50) OVER () AS median, -- 480150
    PERCENTILE_CONT(sales, 0.75) OVER () AS Q3 -- 703380
  FROM `kimia_farma.transaction_pre`
), QR AS (
  SELECT
    Q1, median, Q3,
    (Q3 - Q1) AS IQR, -- 429678
    (Q1 - 1.5 * (Q3 - Q1)) AS lower_treshold, -- -370815
    (Q3 + 1.5 * (Q3 - Q1)) AS upper_treshold -- 1347897
  FROM quartile
)
SELECT
  a.transaction_id,
  a.sales
FROM `kimia_farma.transaction_pre` a
CROSS JOIN QR
WHERE a.sales < QR.lower_treshold
OR a.sales > QR.upper_treshold
ORDER BY a.sales ASC;


-- INVENTORY

SELECT * FROM `kimia_farma.inventory` LIMIT 5;

SELECT
  COUNT(*) AS total_rows, -- 1035000
  COUNT(DISTINCT Inventory_ID) AS total_unique_id, -- 1035000
  COUNT(DISTINCT branch_id) AS total_unique_b_id, -- 1725
  COUNT(DISTINCT product_id) AS total_unique_p_id, -- 150
  COUNT(DISTINCT product_name) AS total_unique_p_name -- 8
FROM `kimia_farma.inventory`;

CREATE OR REPLACE TABLE `kimia_farma.inventory_pre` AS
  SELECT
    TRIM(Inventory_ID) AS inventory_id,
    branch_id,
    TRIM(product_id) AS product_id,
    TRIM(product_name) AS product_name,
    opname_stock
  FROM `kimia_farma.inventory`;

-- NULL checks
-- No null values were found in the inventory table

SELECT
  COUNTIF(inventory_id IS NULL) AS null_id,
  COUNTIF(branch_id IS NULL) AS null_branch,
  COUNTIF(product_id IS NULL) AS null_prod,
  COUNTIF(product_name IS NULL) AS null_prod,
  COUNTIF(opname_stock IS NULL) AS null_stock
FROM `kimia_farma.inventory_pre`;

-- duplicate checks
-- no duplicate data found in the inventory table

WITH dup AS(
SELECT *,
  ROW_NUMBER() OVER(PARTITION BY inventory_id) AS rn
FROM `kimia_farma.inventory_pre`
)
SELECT 
COUNT(*)
FROM dup
WHERE rn > 1;


-- PRODUCT

SELECT * FROM `kimia_farma.product` LIMIT 5;

SELECT
  COUNT(*) AS total_rows, -- 150
  COUNT(DISTINCT product_id) AS total_unique_id, -- 150
  COUNT(DISTINCT product_name) AS total_unique_p_name, -- 8
  COUNT(DISTINCT product_category) AS total_unique_p_cat, -- 8
  AVG(price) AS avg_price, -- 517024.66
  MAX(price) AS max_price, -- 997500
  MIN(price) AS min_price -- 2100
FROM `kimia_farma.product`;

CREATE OR REPLACE TABLE `kimia_farma.product_pre` AS
  SELECT
    TRIM(product_id) AS product_id,
    TRIM(product_name) AS product_name,
    TRIM(product_category) AS product_category,
    price
  FROM `kimia_farma.product`;

-- NULL checks
-- No null values were found in the product table
SELECT
  COUNTIF(product_id IS NULL) AS null_id,
  COUNTIF(product_name IS NULL) AS null_name,
  COUNTIF(product_category IS NULL) AS null_cat,
  COUNTIF(price IS NULL) AS null_price
FROM `kimia_farma.product_pre`;

-- duplicate check
-- No duplicate data found in the product table

WITH dup AS (
SELECT *,
  ROW_NUMBER() OVER(PARTITION BY product_id) AS rn
FROM `kimia_farma.product_pre`
)
SELECT
COUNT(*)
FROM dup
WHERE rn > 1;


-- Create a New Table Master Table

CREATE OR REPLACE TABLE `kimia_farma.master_data` AS 
SELECT
  
  t.transcation_id AS transaction_id,
  t.date,
  t.branch_id,
  b.branch_name,
  b.city,
  b.province,
  b.rating AS branch_rating,
  t.product_id,
  p.product_category,
  t.customer_name,
  p.product_name,
  p.price AS actual_price,
  t.discount AS discount_percentage,

  CASE
    WHEN p.price <= 50000 THEN 0.10
    WHEN p.price <= 100000 THEN 0.15
    WHEN p.price <= 300000 THEN 0.20
    WHEN p.price <= 500000 THEN 0.25
    ELSE 0.30
  END AS gross_profit_percentage,

  t.sales AS nett_sales,

  t.sales * CASE
    WHEN p.price <= 50000 THEN 0.10
    WHEN p.price <= 100000 THEN 0.15
    WHEN p.price <= 300000 THEN 0.20
    WHEN p.price <= 500000 THEN 0.25
    ELSE 0.30
  END AS nett_profit,

  t.rating AS trasaction_rating

FROM `kimia_farma.transaction_pre` t 
JOIN `kimia_farma.product_pre` p ON t.product_id = p.product_id
JOIN `kimia_farma.branch_pre` b ON t.branch_id = b.branch_id;


-- business questions

-- 1. Year-over-Year Comparison of Kimia Farma's Revenue

SELECT
  EXTRACT(YEAR FROM `date`) AS year,
  COUNT(DISTINCT transaction_id) AS total_transaction,
  SUM(nett_sales) AS total_revenue,
  ROUND(
  SUM(nett_profit)) AS total_profit
FROM `kimia_farma.master_data`
GROUP BY 1
ORDER BY 1 ASC;


-- Top 10 Provincial Branches by Total Transactions

SELECT
  province,
  COUNT(DISTINCT transaction_id) AS total_transaction,
  SUM(nett_sales) AS total_revenue,
  ROUND(
  SUM(nett_profit)) AS total_profit
FROM `kimia_farma.master_data`
GROUP BY 1
ORDER BY 2 DESC, 3 DESC
LIMIT 10;

-- Top 5 Branches with the Highest Ratings but the Lowest Transaction Volumes

WITH a AS (
SELECT
  branch_name,
  city,
  MAX(branch_rating) AS max_rt,
  MIN(trasaction_rating) AS min_rt
FROM `kimia_farma.master_data`
WHERE trasaction_rating = (select MIN(trasaction_rating) FROM `kimia_farma.master_data`)
GROUP BY 1, 2
LIMIT 5
)
SELECT
CONCAT(branch_name,' - ', city) AS branch,
max_rt AS branch_rating,
min_rt AS transaction_rating,
FROM a;

-- Profit Growth MoM

WITH pft AS (
SELECT
  FORMAT_DATE('%Y-%m', `date`) AS Period,
  SUM(nett_profit) AS Profit,
  COUNT(transaction_id) AS total_transaction
FROM `kimia_farma.master_data`
GROUP BY 1
ORDER BY 1 ASC
)
SELECT
  CAST(pft.Period AS DATE) AS Period,
  pft.total_transaction,
  pft.Profit,

  ROUND(
    (pft.total_transaction - LAG(pft.total_transaction) OVER(ORDER BY pft.Period)) / 
    LAG(pft.total_transaction) OVER(ORDER BY pft.Period), 2
    )AS transaction_growth_pct,

  ROUND(
    (pft.Profit - LAG(pft.Profit) OVER(ORDER BY pft.Period)) / 
    LAG(pft.Profit) OVER(ORDER BY pft.Period), 2
  ) AS profit_growth_pct

FROM pft;






