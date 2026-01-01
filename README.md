## 🏢📦 Executive Summary — Enterprise Supply Chain Analytics

### Objective
Analyze inventory health, demand alignment, and supplier performance to identify near-stockout risk, planning inefficiencies, 
and operational gaps within a simulated enterprise supply-chain environment.

### Scope
The project was implemented in MySQL using a star-schema data model with a transactional fact table and supporting dimension tables (SKU, warehouse, supplier, date). 
The model incorporates surrogate keys, natural keys, and enforced primary and foreign key constraints, supported by comprehensive data validation including grain checks, 
orphan detection, null checks, and value sanity checks.

### 💡 Key Findings
- A limited subset of SKUs accounts for a disproportionate share of near-stockout days, indicating inventory prioritization issues rather than abnormal demand.

- Warehouse WH_3 consistently operates near safety stock levels across regions, pointing to a warehouse-level replenishment or planning inefficiency.

- Demand forecasts show consistent over- and under-forecasting for specific SKUs, reducing reorder effectiveness despite moderate inventory turnover.

- ABC classification identified 27 A-class SKUs contributing approximately 70% of total revenue, several of which also exhibit elevated near-stockout risk.

 ### 🧠 Assumptions
- SKU-level unit prices are sourced from the most recent available record.

- Historical price changes were not tracked; therefore, ABC classification reflects current price-based SKU prioritization, not historical revenue accounting. 

### ⚠️ Business Risks
- Revenue exposure and service-level impact due to repeated near-stockout conditions on high-value SKUs.

- Inefficient capital utilization driven by misaligned reorder points and safety stock policies.

- Reduced planning accuracy caused by persistent forecast bias.

### Recommendations
- Prioritize inventory control for A-class SKUs by recalibrating reorder points and safety stock thresholds.

- Review warehouse-level replenishment policies, particularly for WH_3.

- Improve demand forecasting inputs for SKUs with recurring forecast error and bias.

### 🏁 Outcome
This project demonstrates the ability to apply dimensional modeling and advanced SQL analytics to convert raw transactional data into actionable insights 
supporting inventory optimization, demand planning, and operational risk reduction.

## 📊 KPI Tables (Key Metrics)

| KPI | Description | Value / Insight |
|-----|------------|----------------|
| Total SKUs | Number of SKUs analyzed | 50 |
| A-Class SKUs | Top-performing SKUs contributing ~70% revenue | 27 |
| Near Stockout Days | Days SKUs were near stockout | 5915 |
| Forecast MAE | Mean Absolute Error of demand forecasts | 2.42–2.44 |
| High-Risk Warehouse | Warehouse with most near-stockout events | WH_3 |
| High-Risk SKUs | SKUs frequently near-stockout | SKU_18, SKU_49, SKU_8, SKU_3 |

### 📊 KPI: Near-Stockout Risk by SKU

| SKU_ID   | Near Stockout Days | Risk Level      |
|----------|-----------------|----------------|
| SKU_18   | 594             | 🚨 High Risk   |
| SKU_49   | 588             | 🚨 High Risk   |
| SKU_8    | 567             | 🚨 High Risk   |
| SKU_3    | 520             | 🚨 High Risk   |
| SKU_10   | 459             | ⚠️ Moderate Risk|
| SKU_7    | 439             | ⚠️ Moderate Risk|
| SKU_4    | 431             | ⚠️ Moderate Risk|
| SKU_42   | 429             | ⚠️ Moderate Risk|
| SKU_37   | 415             | ⚠️ Moderate Risk|

> **Note:** Remaining SKUs have lower near-stockout days but should be monitored for periodic replenishment optimization.

### 📊 KPI: Near-Stockout Risk by Warehouse

| Warehouse_ID | Region | Near Stockout Days | Risk Level      |
|--------------|--------|-----------------|----------------|
| WH_3         | North  | 715             | 🚨 High Risk   |
| WH_3         | East   | 709             | 🚨 High Risk   |
| WH_3         | West   | 698             | 🚨 High Risk   |
| WH_3         | South  | 647             | 🚨 High Risk   |
| WH_5         | East   | 558             | ⚠️ Moderate Risk|
| WH_5         | West   | 558             | ⚠️ Moderate Risk|
| WH_1         | North  | 530             | ⚠️ Moderate Risk|
| WH_5         | South  | 526             | ⚠️ Moderate Risk|
| WH_5         | North  | 526             | ⚠️ Moderate Risk|
| WH_1         | East   | 517             | ⚠️ Moderate Risk|
| WH_1         | South  | 498             | ⚠️ Moderate Risk|
| WH_1         | West   | 496             | ⚠️ Moderate Risk|

> **Insight:** Warehouse **WH_3** consistently operates at or below safety stock levels across all regions, with over **700 near-stockout days per region**, indicating systemic replenishment or inventory policy issues.  
> **Recommendations:** Increase safety stock for WH_3, review replenishment strategy, audit supplier lead times, and check forecast accuracy for WH_3 demand.

### 📊 KPI: SKU-Level Inventory Turnover (Monthly)

| SKU_ID | Year | Month | Total Units Sold | Avg Inventory | Inventory Turnover |
|--------|------|-------|----------------|---------------|------------------|
| SKU_50 | 2024 | 3     | 4631           | 389.95        | 11.88            |
| SKU_50 | 2024 | 4     | 4402           | 383.82        | 11.47            |
| SKU_14 | 2024 | 3     | 4692           | 412.18        | 11.38            |
| SKU_29 | 2024 | 3     | 4760           | 421.45        | 11.29            |
| SKU_3  | 2024 | 3     | 4682           | 419.46        | 11.16            |

> **Insight:** SKU_18 shows the highest near-stockout days despite normal inventory turnover, indicating that stockouts are primarily driven by **replenishment or planning inefficiencies** rather than unusually high demand.

### 📊 KPI: Warehouse-Level Inventory Turnover (Monthly)

| Warehouse_ID | Total Units Sold | Avg Inventory | Inventory Turnover |
|--------------|----------------|---------------|------------------|
| WH_3         | 93430          | 457.00        | 204.44           |
| WH_3         | 92133          | 453.22        | 203.29           |
| WH_3         | 91015          | 453.54        | 200.68           |
| WH_1         | 93435          | 466.02        | 200.49           |
| WH_1         | 92863          | 468.24        | 198.32           |

> **Insight:** Warehouse WH_3 exhibits the **highest inventory turnover** along with frequent near-stockout occurrences across multiple regions, suggesting that stockouts are driven by a combination of **high demand and potential operational planning inefficiencies**.

### 📊 Demand vs Forecast Accuracy by SKU (Monthly)

| sku_id  | actual_units | forecast_units | forecast_error | mean_absolute_error | forecast_bias_percent |
|---------|--------------|----------------|----------------|-------------------|---------------------|
| SKU_47  | 36912        | 36890          | 22             | 2.44              | 0.06                |
| SKU_24  | 36381        | 36571          | -190           | 2.44              | -0.52               |
| SKU_23  | 36698        | 36730          | -32            | 2.44              | -0.09               |
| SKU_44  | 36683        | 36650          | 33             | 2.43              | 0.09                |
| SKU_17  | 36449        | 36411          | 38             | 2.42              | 0.10                |

> **Insight:**  
Analysis of forecast accuracy revealed SKU_47, SKU_44, and SKU_17 were slightly under-forecasted, while SKU_24 and SKU_23 were over-forecasted. The mean absolute errors ranged from 2.42 to 2.44, indicating potential inefficiencies in demand planning. These SKUs are prime candidates for forecast adjustments to reduce overstock and stockout risk.

### 📊 Supplier Lead Time vs Near-Stockout Risk

| supplier_id | supplier_lead_time_days | total_records | near_stockout_days | near_stockout_rate_percent |
|------------|------------------------|---------------|------------------|---------------------------|
| SUP_3      | 6                      | 8395          | 1308             | 15.58                     |
| SUP_2      | 3                      | 9490          | 1394             | 14.69                     |
| SUP_10     | 11                     | 9855          | 1297             | 13.16                     |
| SUP_6      | 6                      | 7300          | 957              | 13.11                     |
| SUP_5      | 12                     | 8395          | 905              | 10.78                     |

> **Insight:**  
Near-stockout risk occurs across both short- and long-lead-time suppliers. SUP_2 showed high risk despite a short lead time, while SUP_5 ranked mid-range, highlighting that reorder points, safety stock, and demand patterns drive inventory risk more than lead time.

### 📊 Reorder Point Effectiveness (SKU-Level Near-Stockout Risk)

| sku_id | total_days | near_stockout_days | near_stockout_rate_percent |
|--------|------------|------------------|---------------------------|
| SKU_18 | 1825       | 594              | 32.55                     |
| SKU_49 | 1825       | 588              | 32.22                     |
| SKU_8  | 1825       | 567              | 31.07                     |
| SKU_3  | 1825       | 520              | 28.49                     |
| SKU_10 | 1825       | 459              | 25.15                     |

> **Insight:**  
SKU_3 shows demand-driven near-stockout risk, while SKU_18, SKU_49, and SKU_8 face planning-related risks despite moderate turnover. SKU_50 maintains high demand without near-stockout issues, reflecting effective inventory planning.

### 📊 ABC Classification – SKU Prioritization

| sku_id | total_value | cum_pct | abc_class |
|--------|------------:|--------:|-----------|
| SKU_22 | 1,193,926.68 | 3.77%  | A         |
| SKU_11 | 1,064,925.82 | 7.13%  | A         |
| SKU_31 | 1,021,795.02 | 10.35% | A         |
| SKU_38 | 1,014,731.18 | 13.55% | A         |
| SKU_35 |   950,016.87 | 16.55% | A         |

> **Insight:**  
A small set of 27 high-value SKUs (~54% of total SKUs) contributes ~70% of revenue, emphasizing the need to prioritize these SKUs for inventory control and stockout prevention.








