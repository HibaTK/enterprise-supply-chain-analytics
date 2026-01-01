CREATE DATABASE supply_chain_analytics;
USE supply_chain_analytics;
CREATE TABLE raw_inventory_data (
date DATE,
sku_id VARCHAR(50),
warehouse_id VARCHAR(50),
supplier_id VARCHAR(50),
region VARCHAR(50),
units_sold INT,
inventory_level INT,
supplier_lead_time_days INT,
reorder_point INT,
order_quantity INT,
unit_cost DECIMAL(10, 2),
unit_price DECIMAL(10, 2),
promotion_flag TINYINT,
stockout_flag TINYINT,
demand_forecast INT
);
SHOW VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;
LOAD DATA LOCAL INFILE '/Users/muhammedmushfiq/Downloads/supply_chain_dataset1.csv'
INTO TABLE raw_inventory_data
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
SET GLOBAL local_infile = 0;
SELECT COUNT(*) FROM raw_inventory_data;

-- 1️⃣ DATE DIMENSION TABLE
CREATE TABLE dim_date AS 
SELECT DISTINCT 
       date,
       extract(YEAR FROM date)  AS year,
       extract(MONTH FROM date) AS month,
       extract(QUARTER FROM date) AS quarter
FROM raw_inventory_data;
SELECT date, year, month, quarter FROM dim_date;
ALTER TABLE dim_date ADD PRIMARY KEY (date);

-- 2️⃣ SKU DIMENSION TABLE
CREATE TABLE dim_sku AS
SELECT
    sku_id,
    reorder_point,
    unit_cost,
    unit_price
FROM (
SELECT *, ROW_NUMBER() OVER(PARTITION BY sku_id ORDER BY date DESC) AS rn
FROM raw_inventory_data
)t
WHERE rn=1;
--  ⚠️ To verify uniqueness
SELECT COUNT(*) AS total_rows,COUNT(DISTINCT sku_id) AS distinct_skus FROM dim_sku;  
SELECT * FROM dim_sku;


-- 3️⃣ WAREHOUSE DIMENSION
CREATE TABLE dim_warehouse AS
SELECT DISTINCT 
    warehouse_id,
    region
FROM raw_inventory_data;
SELECT * FROM dim_warehouse;


-- 4️⃣ SUPPLIER DIMENSION
CREATE TABLE dim_supplier AS
SELECT 
	supplier_id,
    supplier_lead_time_days
FROM (
    SELECT *, ROW_NUMBER() OVER(PARTITION BY supplier_id ORDER BY date DESC) AS rn
    FROM raw_inventory_data
) t
WHERE rn=1;
SELECT * FROM dim_supplier;
SELECT COUNT(*) FROM dim_supplier;


-- 📘 FACT TABLE  ---❌-- new fact table have been made
CREATE TABLE fact_inventory AS 
SELECT
    date,
    sku_id,
    warehouse_id,
    supplier_id,
    units_sold,
    inventory_level,
    order_quantity,
    promotion_flag,
    stockout_flag,
    demand_forecast
FROM raw_inventory_data;
SELECT COUNT(*) FROM fact_inventory;
DROP TABLE dim_sku;
ALTER TABLE dim_sku ADD PRIMARY KEY (sku_id);
-- Adding surrogate key to dim_warehouse
ALTER TABLE dim_warehouse ADD COLUMN warehouse_key INT AUTO_INCREMENT PRIMARY KEY FIRST;
SELECT * FROM dim_warehouse;
DROP TABLE dim_supplier;
ALTER TABLE dim_supplier ADD PRIMARY KEY(supplier_id);

-- Adding warehouse_key to fact_inventory
ALTER TABLE fact_inventory ADD COLUMN warehouse_key INT;

-- ＋📄 POPULATE THE FOREIGN KEYS
-- Warehouse 

SET SQL_SAFE_UPDATES = 0;
UPDATE fact_inventory_new f
JOIN dim_warehouse w
ON f.warehouse_id = w.warehouse_id AND f.region = w.region
SET f.warehouse_key = w.warehouse_key;

DROP TABLE fact_inventory;  -- Didnt work, let's try creating a brand new fact table
-- 🆕 FACT TABLE {fact_inventory_new}
CREATE TABLE fact_inventory_new AS
SELECT
    date, sku_id,warehouse_id, region, supplier_id, units_sold, inventory_level, order_quantity, promotion_flag, 
    stockout_flag, demand_forecast 
FROM raw_inventory_data;

-- Link fact to dim_warehouse
ALTER TABLE fact_inventory_new ADD COLUMN warehouse_key INT;
ALTER TABLE fact_inventory_new ADD CONSTRAINT fk_fact_warehouse
FOREIGN KEY (warehouse_key) REFERENCES dim_warehouse(warehouse_key);

-- Link fact to dim_date
ALTER TABLE fact_inventory_new ADD CONSTRAINT fk_fact_date
FOREIGN KEY (date) REFERENCES dim_date(date);

-- Link fact to dim_sku
ALTER TABLE fact_inventory_new ADD CONSTRAINT fk_fact_sku
FOREIGN KEY (sku_id) REFERENCES dim_sku(sku_id);

-- Link fact to dim_supplier
ALTER TABLE fact_inventory_new ADD CONSTRAINT fk_fact_supplier
FOREIGN KEY (supplier_id) REFERENCES dim_supplier(supplier_id);

SHOW TABLES;
SELECT * FROM fact_inventory_new;
DESCRIBE dim_date;
DESCRIBE dim_sku;
DESCRIBE dim_warehouse;
DESCRIBE dim_supplier;
DESCRIBE fact_inventory_new;

SHOW INDEX FROM dim_date;
SHOW INDEX FROM dim_sku;
SHOW INDEX FROM dim_warehouse;
SHOW INDEX FROM dim_supplier;

SELECT COUNT(*) FROM fact_inventory_new;
SELECT COUNT(*) FROM raw_inventory_data;

-- ✅🗃️ Confirming Foreign Keys
SELECT
    TABLE_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = DATABASE()
AND REFERENCED_TABLE_NAME IS NOT NULL;

-- ✅ Orphan check
-- (1) Waregouse Integrity
SELECT COUNT(*) AS missing_warehouses
FROM fact_inventory_new f
LEFT JOIN dim_warehouse w
  ON f.warehouse_key = w.warehouse_key
WHERE w.warehouse_key IS NULL;
-- (2) Supplier Integrity
SELECT COUNT(*) AS missing_suppliers
FROM fact_inventory_new f
LEFT JOIN dim_supplier s
  ON f.supplier_id = s.supplier_id
WHERE s.supplier_id IS NULL;
-- (3) sku Integrity
SELECT COUNT(*) AS missing_sku
FROM fact_inventory_new f
LEFT JOIN dim_sku sk
  ON f.sku_id = sk.sku_id
WHERE sk.sku_id IS NULL;
-- (3) date Integrity
SELECT COUNT(*) AS missing_dates
FROM fact_inventory_new f
LEFT JOIN dim_date d
  ON f.date = d.date
WHERE d.date IS NULL;
-- ✅ Grain Check
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT date, sku_id, warehouse_key, supplier_id) AS distinct_grain
FROM fact_inventory_new;

-- ✅ NULL check
SELECT
    SUM(date IS NULL) AS null_dates,
    SUM(sku_id IS NULL) AS null_skus,
    SUM(warehouse_key IS NULL) AS null_warehouses,
    SUM(supplier_id IS NULL) AS null_suppliers
FROM fact_inventory_new;

-- ✅🔢 Value Sanity Check
-- >(*) Negative sales? Shouldn't happen
SELECT COUNT(*) AS negative_sales
FROM fact_inventory_new
WHERE units_sold < 0;
-- >(*) Negative Inventory? Usually wrong
SELECT COUNT(*) AS negative_inventory
FROM fact_inventory_new
WHERE inventory_level < 0;
-- >(*) Negative order quantities?
SELECT COUNT(*) AS negative_quantities
FROM fact_inventory_new
WHERE order_quantity < 0;
-- >(*) Promotion & Stockout flags (should be 0 or 1)
SELECT COUNT(*) AS invalid_promotion_flag
FROM fact_inventory_new
WHERE promotion_flag NOT IN (0,1);

SELECT COUNT(*) AS invalid_stockout_flag
FROM fact_inventory_new
WHERE stockout_flag NOT IN (0,1);

-- >(*) Invalid unit cost or price
SELECT COUNT(*) AS invalid_unit_cost_price
FROM dim_sku
WHERE unit_cost <= 0 OR unit_price <= 0;

-- ✅ Date Coverage Check
# Checking min/max dates in fact table & in dim_date
SELECT 
    MIN(date) AS min_fact_date,
    MAX(date) AS max_fact_date
FROM fact_inventory_new;
SELECT 
    MIN(date) AS min_dim_date,
    MAX(date) AS max_dim_date
FROM dim_date;
    
-- >(*) Check for missing dates in dim_date
SELECT f.date
FROM fact_inventory_new f
JOIN dim_date d ON f.date = d.date
WHERE d.date IS NULL;

# =====================
#      ANALYSIS
# =====================

-- ✅ STOCKOUT RISK ANALYSIS
# Which SKUs and warehouses experience the most stockouts?

SELECT
   sku_id,
   COUNT(DISTINCT date) AS total_days,
   SUM(stockout_flag) AS stockout_days,
   ROUND(SUM(stockout_flag) / COUNT(DISTINCT date), 3) AS stockout_rate
FROM fact_inventory_new 
GROUP BY sku_id
ORDER BY stockout_rate DESC;
SELECT
   stockout_flag,
   COUNT(*) AS row_count
FROM fact_inventory_new
GROUP BY stockout_flag;
-- "🛑 No stockout events were observed during the analyzed period"

-- ✅ NEAR STOCKOUT RISK ANALYSIS
# Which SKU's frequently operate at or below their reorder point?

SELECT
     f.sku_id, COUNT(*) AS near_stockout_days
FROM fact_inventory_new f 
JOIN dim_sku sk
    ON f.sku_id = sk.sku_id
WHERE f.inventory_level <= sk.reorder_point
GROUP BY f.sku_id
ORDER BY near_stockout_days DESC;
# "SKU18 operates frequently at dangerously low inventory levels"
# "High near stockout days = 🚨 HIGH RISK"
# Identified SKUs(SKU18,SKU49,SKU8,SKU3) consistently operating near safety stock levels,
# highlighting potential inventory risk for high priority items and providing opportunities
# to optimize replenishment to prevent stockouts"

# Which warehouses are operationally risky?
SELECT
    w.warehouse_id,
    w.region,
    COUNT(*) AS near_stockout_days
FROM fact_inventory_new f
JOIN dim_sku sk ON f.sku_id = sk.sku_id
JOIN dim_warehouse w ON f.warehouse_key = w.warehouse_key
WHERE f.inventory_level <= sk.reorder_point
GROUP BY w.warehouse_id,w.region
ORDER BY near_stockout_days DESC;

-- "Near stockout analysis revealed that Warehouse WH_3 consistently operates at or below safety 
-- stock level across all regions(North, East, West, South), with over 700 near stockout days in each region. 
-- This indicates a systemic replenishment or inventory policy issue specific to WH_3 rather than regional demand variability"
# Actionable Recommendations
 -- > Increase safety stock threshold for WH_3
 -- > Review replenishment and order quantities
 -- > Audit supplier lead times serving WH_3
 -- > Investigate forecast accuracy specific to WH_3 demand flows
 
 -- ✅ INVENTORY TURNOVER ANALYSIS
 # Prep 
 SELECT
    COUNT(*) AS total_rows,
    COUNT(units_sold) AS units_sold_rows,
    COUNT(inventory_level) AS inventory_rows
FROM fact_inventory_new;
# How many units did we sell and how much inventory did we carry per SKU per month?
SELECT
    sku_id,
    YEAR(date) AS year,
    MONTH(date) AS month,
    SUM(units_sold) AS total_units_sold,
    AVG(inventory_level) AS avg_inventory
FROM fact_inventory_new
GROUP BY
    sku_id,
    YEAR(date),
    MONTH(date);
# Inventory turnover tells us how many times our inventory was sold and replenished during a period, or in other way
# "Did this product move, or did it just sit in the warehouse?"
# Inventory Turnover = Units sold / Average Inventory
# Units sold --> demand, Average inventory --> how much stock we kept
# Division --> how efficiently e used that stock?
# Let's say if turnover is 12, this means 12 times we sold the stock with average inventory level per month[MOVEMENT EFFICIENCY]
# We found that certain SKUs and warehouses are near stockout often, turnover tells us why
# High turnover --> demand driven risk, low turnover --> Planning failure

-- SKU level inventory turnover (Monthly)
SELECT
    sku_id,
    year,
    month,
    total_units_sold,
    avg_inventory,
    ROUND(total_units_sold / NULLIF(avg_inventory, 0), 2) AS inventory_turnover
FROM (
    SELECT
    sku_id,
    YEAR(date) AS year,
    MONTH(date) AS month,
    SUM(units_sold) AS total_units_sold,
    AVG(inventory_level) AS avg_inventory
FROM fact_inventory_new
GROUP BY
    sku_id,
    YEAR(date),
    MONTH(date)
) t
ORDER BY inventory_turnover DESC;

-- "SKU_18 exhibits the highest frequency of near stockout days despite normal inventory turnover, indicating stockouts are  
-- are driven by replenishment or planning inefficiencies rather than unusually high demand"

-- Warehouse level inventory turnover(Monthly)
SELECT
    f.warehouse_key,
    w.warehouse_id,
    SUM(f.units_sold) AS total_units_sold,
    AVG(f.inventory_level) AS avg_inventory,
    ROUND(SUM(f.units_sold) / NULLIF(AVG(f.inventory_level),0),2) AS inventory_turnover
FROM fact_inventory_new f
JOIN dim_warehouse w
ON f.warehouse_key = w.warehouse_key
GROUP BY f.warehouse_key, w.warehouse_id
ORDER BY inventory_turnover DESC;
-- > “WH_3 exhibits the highest inventory turnover and frequent near-stockout occurrences across multiple regions,
-- suggesting that stockouts are driven by a combination of high demand and potential operational planning inefficiencies.”

-- ✅ Demand vs forecast accuracy analysis
# How well forecast matches actual demand
# Metrics --> Forecast error - [actual - forecast], Mean absolute error - avg magnitude of errors, 
# forecast bias - over or under forecasting tendency
# High error --> forecast isnt reliable, positive bias --> consistently over-forecasting, negative bias --> 
# consistently under-forecasting, forecast bias tells you whether you over-forecasted or under-forecasted (actual demand - forecasted demand)
# +ve bias --> under forecasted --> actual > Forecast 
# -ve bias --> over forecasted --> actual < Forecast
# Bias = 0 --> forecast is unbiased
SELECT
    sku_id, SUM(units_sold) AS actual_units, SUM(demand_forecast) AS forecast_units,
    SUM(units_sold - demand_forecast) AS forecast_error,
    ROUND(AVG(ABS(units_sold - demand_forecast)),2) AS mean_absolute_error,
    ROUND(SUM(units_sold - demand_forecast) / NULLIF(SUM(demand_forecast), 0)*100, 2) AS forecast_bias_percent
FROM fact_inventory_new
GROUP BY sku_id
ORDER BY ROUND(AVG(ABS(units_sold - demand_forecast)),2) DESC;
-- “Analysis of forecast accuracy revealed SKU_47, SKU_44, and SKU_17 were slightly under-forecasted, while SKU_24 and SKU_23 were over-forecasted. 
-- The mean absolute errors for these SKUs ranged from 2.42 to 2.44, with magnitude of errors indicating potential inefficiencies in demand planning.
-- These insights highlight SKUs where forecasting adjustments could improve inventory management and reduce both overstock and stockout risk."

-- ✅ Supplier Lead Time Impact Analysis
# Do longer supplier lead times correlate with higher stockouts and inventory issues?
# (1)Average stockout rate by supplier --> measures how often the products supplied y a particularupplier run out
# How many days SKUs supplied by this supplier had stockouts
# Divide by total number of days those SKUs were tracked
# Multiply by 100 --> gives % of days with stockouts
# identify suppliers causing inventory problems
# (2) Compare lead time vs inventory buffer
# (3) Identify high risk suppliers
# stockout percentage --> percentage of time inventory was out of stock
SELECT
    f.supplier_id,
    s.supplier_lead_time_days,
    SUM(f.stockout_flag) AS total_stockouts,
    COUNT(*) AS total_days,
    ROUND(SUM(f.stockout_flag) / COUNT(*) * 100, 2) AS stockout_rate_percent
FROM fact_inventory_new f
JOIN dim_supplier s ON f.supplier_id = s.supplier_id
GROUP BY f.supplier_id, s.supplier_lead_time_days
ORDER BY stockout_rate_percent DESC;
-- "In this dataset, no supplier ever caused a true stockout"
-- ✅ Near stockout risk analysis by supplier
# Near stockout --> inventory_level <= reorder_point
SELECT
     f.supplier_id, s.supplier_lead_time_days, COUNT(*) AS total_records,
     SUM(CASE WHEN f.inventory_level <= sk.reorder_point THEN 1 ELSE 0 END) AS near_stockout_days,
     ROUND(SUM(CASE WHEN f.inventory_level <= sk.reorder_point THEN 1 ELSE 0 END) / COUNT(*) *100,2) AS near_stockout_rate_percent
FROM fact_inventory_new f JOIN dim_supplier s ON f.supplier_id = s.supplier_id
JOIN dim_sku sk ON f.sku_id = sk.sku_id
GROUP BY f.supplier_id, s.supplier_lead_time_days
ORDER BY near_stockout_rate_percent DESC; 
# Now the story automatically flows into "REORDER POINT EFFECTIVENESS ANALYSIS" - We have proven
# risk even without long lead times
# 🛑 “Supplier-level near-stockout analysis revealed elevated inventory risk across both short and long lead-time suppliers.
#  Notably, SUP_2 exhibited one of the highest near-stockout rates despite having one of the shortest lead times,
#  while the longest lead-time supplier (SUP_5) ranked mid-range. This indicates that reorder point calibration, 
# safety stock levels, and demand patterns play a more critical role in inventory risk than lead time alone.”

-- ✅ Reorder point Effectiveness analysis
# Are reorder points set at the right levels to prevent inventory risk?
SELECT f.sku_id, COUNT(*) AS total_days, 
        SUM( CASE WHEN f.inventory_level <= sk.reorder_point THEN 1 ELSE 0 END ) AS near_stockout_days,
        ROUND( SUM( CASE WHEN f.inventory_level <= sk.reorder_point THEN 1 ELSE 0 END ) / COUNT(*) * 100, 2 ) AS near_stockout_rate_percent 
FROM fact_inventory_new f 
JOIN dim_sku sk ON f.sku_id = sk.sku_id 
GROUP BY f.sku_id 
ORDER BY near_stockout_rate_percent DESC; 
-- “Cross-analysis of inventory turnover and reorder point effectiveness revealed that SKU_3 experiences 
-- demand-driven near-stockout risk in specific regions, while other SKUs such as SKU_18, SKU_49, and SKU_8 
-- exhibit planning-related near-stockout risk despite moderate turnover. In contrast, SKU_50 demonstrated high demand 
-- across regions without elevated near-stockout rates, indicating effective inventory planning.”

-- ✅ ABC Classification - An inventory prioritization technique
# Are these problematic SKUs actually high-value or low-value? 
# Rank SKUs by importance # Categories - A --> Top 10 - 20%, B --> Middle 20 - 30 %, C--> Remaining SKUs 
# Help companies to focus on high value SKUs for inventory control, stockouts and planning
-- Step 1 : Aggregate total value per SKU
SELECT 
    f.sku_id, 
    SUM(sk.units_sold * sk.unit_price) AS total_value 
FROM fact_inventory_new f 
JOIN dim_sku sk ON f.sku_id = sk.sku_id 
GROUP BY sku_id 
ORDER BY total_value DESC; 
-- Revenue per SKU 👆
-- Step 2 : Calculate cumulative percentage
SELECT 
    sku_id,
    total_value,
    ROUND(total_value / SUM(total_value) OVER() * 100, 2) AS pct_of_total,
    ROUND(
        SUM(total_value) OVER (
            ORDER BY total_value DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) / SUM(total_value) OVER() * 100,
        2
    ) AS cum_pct
FROM (
    SELECT 
        f.sku_id,
        SUM(f.units_sold * sk.unit_price) AS total_value
    FROM fact_inventory_new f
    JOIN dim_sku sk ON f.sku_id = sk.sku_id
    GROUP BY f.sku_id
) t
ORDER BY total_value DESC;
-- Step 3 : Assign 🅰️🅱️🅲 categories
SELECT *,
     CASE
        WHEN cum_pct <= 70 THEN 'A'
        WHEN cum_pct <= 90 THEN 'B'
        ELSE 'C'
	END AS abc_class
FROM (
     SELECT
         f.sku_id,
         SUM(f.units_sold * sk.unit_price) AS total_value,
         ROUND(
            SUM(SUM(f.units_sold * sk.unit_price)) OVER(
               ORDER BY SUM(f.units_sold * sk.unit_price) DESC
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
			) / SUM(SUM(f.units_sold * sk.unit_price)) OVER() * 100,2
		) AS cum_pct
	FROM fact_inventory_new f
    JOIN dim_sku sk ON f.sku_id = sk.sku_id
    GROUP BY f.sku_id
) t
ORDER BY total_value DESC;
-- few SKUs dominate the revenue → that’s why A is “small % of SKUs but large % of value.”

WITH abc_classification AS (
   SELECT
        f.sku_id,
        SUM(f.units_sold * sk.unit_price) AS total_value,
        ROUND(
           SUM(SUM(f.units_sold * sk.unit_price)) OVER(
			  ORDER BY SUM(f.units_sold * sk.unit_price) DESC
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
		   ) / SUM(SUM(f.units_sold * sk.unit_price)) OVER() * 100, 2
		) AS cum_pct,
        CASE
           WHEN ROUND(
			  SUM(SUM(f.units_sold * sk.unit_price)) OVER(
			  ORDER BY SUM(f.units_sold * sk.unit_price) DESC
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
		   ) / SUM(SUM(f.units_sold * sk.unit_price)) OVER() * 100, 2
		) <= 70 THEN 'A'
        WHEN ROUND(
            SUM(SUM(f.units_sold * sk.unit_price)) OVER(
			  ORDER BY SUM(f.units_sold * sk.unit_price) DESC
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
		   ) / SUM(SUM(f.units_sold * sk.unit_price)) OVER() * 100, 2
		) <= 90 THEN 'B'
        ELSE 'C'
	END AS abc_class
    FROM fact_inventory_new f
    JOIN dim_sku sk ON f.sku_id = sk.sku_id
    GROUP BY f.sku_id
)
SELECT
    abc_class,
    COUNT(*) AS sku_count,
    SUM(total_value) AS total_revenue,
    ROUND(SUM(total_value) / SUM(SUM(total_value)) OVER() * 100, 2) AS revenue_pct,
    SUM(CASE WHEN f.inventory_level <= sk.reorder_point THEN 1 ELSE 0 END) AS near_stockout_days
FROM abc_classification abc
JOIN fact_inventory_new f ON abc.sku_id = f.sku_id
JOIN dim_sku sk ON abc.sku_id = sk.sku_id
GROUP BY abc_class
ORDER BY FIELD(abc_class, 'A', 'B', 'C');
                


        
