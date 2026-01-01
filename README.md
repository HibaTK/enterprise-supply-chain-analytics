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

