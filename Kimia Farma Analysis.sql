
-- PARETO
--===========
-- Product
WITH pareto_prod AS (
SELECT
  product_id,
  SUM(nett_sales) AS revenue,
  SUM(nett_profit) AS profit,
FROM `kimia_farma.master_data`
GROUP BY 1
)
SELECT
  product_id,
  revenue,
  profit,
  profit / SUM(profit) OVER() AS profit_pct,
  SUM(profit) OVER(ORDER BY profit DESC) / SUM(profit) OVER() AS cummulative_profit_pct,
  revenue / SUM(revenue) OVER() AS revenue_pct,
  SUM(revenue) OVER(ORDER BY revenue DESC) / SUM(revenue) OVER() AS cummulative_revenue_pct
FROM pareto_prod;

-- prod.category
WITH pareto_product AS (
SELECT
  product_category,
  SUM(nett_sales) AS revenue,
  SUM(nett_profit) AS profit,
FROM `kimia_farma.master_data`
GROUP BY 1
)
SELECT
  product_category,
  revenue,
  profit,
  profit / SUM(profit) OVER() AS profit_pct,
  SUM(profit) OVER(ORDER BY profit DESC) / SUM(profit) OVER() AS cummulative_profit_pct,
  revenue / SUM(revenue) OVER() AS revenue_pct,
  SUM(revenue) OVER(ORDER BY revenue DESC) / SUM(revenue) OVER() AS cummulative_revenue_pct
FROM pareto_product;

-- province
WITH pareto_prov AS (
SELECT
  province,
  SUM(nett_sales) AS revenue,
  SUM(nett_profit) AS profit,
FROM `kimia_farma.master_data`
GROUP BY 1
)
SELECT
  province,
  revenue,
  profit,
  profit / SUM(profit) OVER() AS profit_pct,
  SUM(profit) OVER(ORDER BY profit DESC) / SUM(profit) OVER() AS cummulative_profit_pct,
  revenue / SUM(revenue) OVER() AS revenue_pct,
  SUM(revenue) OVER(ORDER BY revenue DESC) / SUM(revenue) OVER() AS cummulative_revenue_pct
FROM pareto_prov;

-- branchid
WITH pareto_brnch AS (
SELECT
  branch_id,
  SUM(nett_sales) AS revenue,
  SUM(nett_profit) AS profit,
FROM `kimia_farma.master_data`
GROUP BY 1
)
SELECT
  branch_id,
  revenue,
  profit,
  profit / SUM(profit) OVER() AS profit_pct,
  SUM(profit) OVER(ORDER BY profit DESC) / SUM(profit) OVER() AS cummulative_profit_pct,
  revenue / SUM(revenue) OVER() AS revenue_pct,
  SUM(revenue) OVER(ORDER BY revenue DESC) / SUM(revenue) OVER() AS cummulative_revenue_pct
FROM pareto_brnch;



-- 10% TOP & BOTTOM
--==================
WITH b_tile AS (
SELECT
  branch_id,
  province,
  ANY_VALUE(branch_rating) AS branch_rating,
  COUNT(DISTINCT transaction_id) AS total_transaction,
  COUNT(DISTINCT customer_name) AS total_customer,
  SUM(nett_sales) AS revenue,
  SUM(nett_profit) AS profit,
  AVG(discount_percentage) AS avg_discount,
  AVG(trasaction_rating) AS avg_transaction_rating
FROM `kimia_farma.master_data`
GROUP BY 1, 2
),ranked AS (
  SELECT *,
    NTILE(10) OVER (ORDER BY profit DESC) AS profit_decile
  FROM b_tile
),
labeled AS (
  SELECT *,
    CASE
      WHEN profit_decile = 1 THEN 'Top 10% Branch'
      WHEN profit_decile = 10 THEN 'Bottom 10% Branch'
    END AS branch_group
  FROM ranked
  WHERE profit_decile IN (1, 10)
)
SELECT
  branch_group,
  COUNT(*) AS branch_count,
  ROUND(AVG(total_transaction), 0) AS avg_transaction,
  ROUND(AVG(revenue), 0) AS avg_revenue,
  ROUND(AVG(profit), 0) AS avg_profit,
  ROUND(AVG(avg_discount), 2) AS avg_discount_pct,
  ROUND(AVG(branch_rating), 3) AS avg_branch_rating,
  ROUND(AVG(avg_transaction_rating), 3) AS avg_transaction_rating
FROM labeled
GROUP BY branch_group;


-- Kontribusi berdasarkan kategori per provinsi -> periksa apakah setiap provinsi memiliki “3 kategori utama”
--============================================================================================================
SELECT
  province,
  product_category,
  SUM(nett_sales) AS revenue,
  SUM(nett_sales) / SUM(SUM(nett_sales)) OVER (PARTITION BY province) AS pct_within_province
FROM `kimia_farma.master_data`
GROUP BY province, product_category
QUALIFY ROW_NUMBER() OVER (PARTITION BY province ORDER BY revenue DESC) <= 3;



-- Distribusi revenue antar produk
--=================================
WITH rev AS (
  SELECT
    branch_id,
    SUM(nett_sales) AS revenue
  FROM `kimia_farma.master_data`
  GROUP BY 1
),
pareto AS (
  SELECT
    *,
    ROW_NUMBER() OVER(ORDER BY revenue DESC) AS rn,
    COUNT(*) OVER() AS total_product,
    SUM(revenue) OVER() AS total_revenue,
    SUM(revenue) OVER(ORDER BY revenue DESC) AS cummulative_revenue
  FROM rev
)
SELECT
  branch_id,
  ROUND(
  100.0 * rn / total_product,2) AS cummulative_prd_pct,
  ROUND(
  100.0 * cummulative_revenue / total_revenue,2) AS cummulative_rev_pct,
FROM pareto
ORDER BY cummulative_prd_pct;



-- correlation coefficient
--=========================
SELECT
CORR(total_branch, total_profit) as correlation
FROM(SELECT
province,
count(distinct branch_id) total_branch,
sum(nett_profit) as total_profit
FROM `kimia_farma.master_data`
GROUP BY 1);



--coefficient of variation
--=========================
WITH cor AS (
SELECT
province,
COUNT(DISTINCT branch_id) AS total_branch,
SUM(nett_profit) AS total_profit,
ROUND(
  SUM(nett_profit) / COUNT(DISTINCT branch_id) * 100.0, 2
) AS avg_profit
FROM `kimia_farma.master_data`
GROUP BY 1)
SELECT
ROUND(
STDDEV_SAMP(cor.avg_profit) / AVG(cor.avg_profit) * 100.0,2) AS correlation_variation
FROM cor;





