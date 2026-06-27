# Retail Analytics Pipeline



End-to-end data pipeline on the Superstore dataset covering ingestion, star schema modeling, ML customer segmentation & churn prediction, and interactive BI reporting.

---

## Pipeline

```
Sales.csv → [Python] Clean & Ingest → staging → [SQL] Star Schema → dwh → [SQL] Aggregations → mart → [Python] ML → Power BI
```

---

## Screenshots

| Customers | Sales | Products |
|---|---|---|
| ![](screenshots/IMG-20251026-WA0106.jpg) | ![](screenshots/IMG-20251026-WA0107.jpg) | ![](screenshots/IMG-20251026-WA0109.jpg) |

---

## Tech Stack

| Layer | Tools |
|---|---|
| Database | PostgreSQL |
| ETL & Cleaning | Python, Pandas, NumPy, SQLAlchemy |
| Warehousing | SQL — Star Schema (staging → dwh → mart) |
| ML | Scikit-learn, XGBoost, SciPy, sklearn-extra |
| BI | Power BI Desktop |

---

## Database Design

Three-schema architecture:

- **`staging`** — raw ingested data from CSV
- **`dwh`** — star schema with `fact_sales` + 4 dimensions (`dim_customer`, `dim_product`, `dim_date`, `dim_ship`)
- **`mart`** — aggregated tables: `sales_daily`, `sales_monthly`, `product_sales`, `customers`, `customer_cohorts`, `executive_summary`, `customers_ML_results`

**`fact_sales` measures:** sales, profit, cost, discount, quantity, profit margin %
Indexed on customer, product, order date, ship date, and order ID.

---

## ML Analysis

**Customer Segmentation** — compared K-Means, Hierarchical, Gaussian Mixture, DBSCAN, and K-Medoids using Silhouette, Calinski-Harabasz, and Davies-Bouldin scores. K-Medoids (k=2) performed best:
- Cluster 0 → Occasional Buyers (221 customers)
- Cluster 1 → Loyal High-Value Customers (169 customers)

**Churn Prediction** — XGBoost classifier (max_depth=4, lr=0.1, n_estimators=150) using RFM-based features. Evaluated with ROC-AUC, confusion matrix, and feature importance. Churn probability per customer stored back to `mart.customers_ML_results`.

---

## Dashboard Highlights

- **Customers** — 793 customers, 98.49% repeat rate, ML cluster distribution, status breakdown, LTV
- **Sales** — 2.39M revenue, 46.79% YoY growth, discount impact analysis, revenue by region
- **Products** — 1,862 products across 3 categories, profit vs revenue by product, top sellers

---

## Getting Started

**Prerequisites:** PostgreSQL, Python 3.10+, Power BI Desktop

```bash
# 1. Install dependencies
pip install pandas numpy sqlalchemy psycopg2 scikit-learn xgboost sklearn-extra matplotlib seaborn scipy

# 2. Create a PostgreSQL database named 'Sales', then run SQL files in order:
#    sql/0_Scheme.sql → 2_create_dimensions.sql → 3_create_fact_table.sql → 4_data_mart.sql

# 3. Run notebooks in order (update CSV path and DB credentials first):
#    1_CSV_Ingestion_Cleaning.ipynb → 5_ML_Analysis.ipynb

# 4. Open dashboard.pbix in Power BI Desktop and refresh the connection
```

---

## Project Structure

```
├── data/Sales.csv
├── sql/
│   ├── 0_Scheme.sql
│   ├── 2_create_dimensions.sql
│   ├── 3_create_fact_table.sql
│   └── 4_data_mart.sql
├── notebooks/
│   ├── 1_CSV_Ingestion_Cleaning.ipynb
│   └── 5_ML_Analysis.ipynb
├── dashboard/dashboard.pbix
└── screenshots/
```

---

## License

MIT — free to use and modify.

**Repository:** [LoubnaSaad/retail-analytics-pipeline](https://github.com/LoubnaSaad/retail-analytics-pipeline)
