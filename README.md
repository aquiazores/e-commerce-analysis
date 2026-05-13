# Olist Brazilian E-Commerce — Sales Performance & Revenue Loss Analysis (2016–2018)

## Overview

I built this project to analyze sales performance and cancellation-driven revenue loss in a Brazilian e-commerce marketplace. Using the Olist public dataset, I wanted to answer two questions: where is the business growing, and where is it losing money it shouldn't be losing?

This is my third portfolio project, following my DPWH Flood Control analysis. The goal here was to work with a multi-table relational dataset, write more complex SQL joins across six tables, and build a two-page Power BI dashboard that tells a complete story — one page on growth, one page on loss.

---

## Business Questions

1. How did Olist's revenue grow between 2016 and 2018, and which categories and states drove that growth?
2. Which product categories are responsible for the most revenue lost to cancellations — and is cancellation a growing problem over time?

---

## Tools Used

- **Python (pandas, Google Colab)** — data cleaning and null handling
- **Google BigQuery (SQL)** — querying and aggregating across six tables
- **Power BI Desktop** — two-page interactive dashboard
- **GitHub** — version control and project documentation

---

## Dataset

- **Source:** [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) — Kaggle
- **Original dataset by:** Olist / André Sionek
- **Coverage:** ~100,000 orders placed between October 2016 and August 2018
- **Tables used:** orders, order items, payments, reviews, products, customers, category translation

---

## Data Cleaning

The raw dataset was spread across seven CSV files and required the following before analysis:

- **Timestamp columns** in the orders table were stored as strings — converted all five to proper datetime format using `pd.to_datetime()`
- **610 product rows** were missing category name and dimension data — dropped from the products table
- **2 product rows** had missing weight and size values — also dropped
- **13 products** had no English category translation — filled with `'uncategorized'`
- Merged the English category translation table into the products table so all category labels appear in English throughout the dashboard
- Exported six clean CSVs for BigQuery upload

Total products after cleaning: **32,340** (down from 32,951)

---

## SQL Queries (Google BigQuery)

All queries filter to `order_status = 'delivered'` for sales analysis, and `order_status = 'canceled'` for cancellation analysis.

### Query 1 — Monthly Revenue Trend
```sql
SELECT
  SUM(payment_value) as Revenue,
  FORMAT_TIMESTAMP('%Y-%m', o.order_purchase_timestamp) as Month
FROM `olist.clean_payments` p
JOIN `olist.clean_orders` o ON p.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY Month
ORDER BY Month ASC
```

### Query 2 — Revenue by Product Category (Monthly)
```sql
SELECT
  pr.product_category_name_english as Category,
  SUM(p.payment_value) as Revenue,
  FORMAT_TIMESTAMP('%Y-%m', o.order_purchase_timestamp) as Month
FROM `olist.clean_products` pr
LEFT JOIN `olist.clean_items` i ON pr.product_id = i.product_id
LEFT JOIN `olist.clean_orders` o ON o.order_id = i.order_id
LEFT JOIN `olist.clean_payments` p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY Month, Category
HAVING Revenue IS NOT NULL
ORDER BY Revenue DESC
```

### Query 3 — Revenue by Customer State (Monthly)
```sql
SELECT
  c.customer_state as State,
  SUM(p.payment_value) as Revenue,
  FORMAT_TIMESTAMP('%Y-%m', o.order_purchase_timestamp) as Month
FROM `olist.clean_customers` c
JOIN `olist.clean_orders` o ON c.customer_id = o.customer_id
JOIN `olist.clean_payments` p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY Month, State
ORDER BY Month ASC, Revenue DESC
```

### Query 4 — Average Order Value by Month
```sql
SELECT
  SUM(payment_value) / COUNT(DISTINCT o.order_id) as AOV,
  FORMAT_TIMESTAMP('%Y-%m', o.order_purchase_timestamp) as Month
FROM `olist.clean_payments` p
JOIN `olist.clean_orders` o ON p.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY Month
ORDER BY Month ASC
```

### Query 5 — Cancellation Summary by Month
```sql
SELECT
  FORMAT_TIMESTAMP('%Y-%m', order_purchase_timestamp) as Month,
  COUNTIF(order_status = 'canceled') as cancelled_orders,
  COUNT(order_id) as total_orders,
  COUNTIF(order_status = 'canceled') / COUNT(order_id) as cancellation_rate
FROM `olist.clean_orders`
GROUP BY Month
ORDER BY Month ASC
```

### Query 6 — Revenue Lost to Cancellations by Category (Monthly)
```sql
SELECT
  pr.product_category_name_english as Category,
  SUM(p.payment_value) as Revenue,
  FORMAT_TIMESTAMP('%Y-%m', o.order_purchase_timestamp) as Month
FROM `olist.clean_products` pr
LEFT JOIN `olist.clean_items` i ON pr.product_id = i.product_id
LEFT JOIN `olist.clean_orders` o ON o.order_id = i.order_id
LEFT JOIN `olist.clean_payments` p ON o.order_id = p.order_id
WHERE o.order_status = 'canceled'
AND o.order_purchase_timestamp IS NOT NULL
GROUP BY Month, Category
HAVING Revenue IS NOT NULL
ORDER BY Revenue DESC
```

---

## What I Found

### Page 1 — Sales Performance

**Revenue grew consistently from 2016 to 2018**
Monthly revenue grew from near zero in late 2016 to over R$1.1M per month by mid-2018. This growth was driven by order volume increasing — not by customers spending more per order.

**Average Order Value stayed flat**
AOV hovered between R$147 and R$175 across most months with no meaningful upward trend. This tells us that Olist's revenue growth came from acquiring more customers, not from getting existing customers to spend more.

**Bed Bath Table, Health Beauty, and Computers Accessories are the top three categories**
These three categories account for a disproportionate share of total revenue. Notably, these same categories appear rarely in the cancellation data — suggesting they are both high-revenue and high-reliability categories.

**São Paulo (SP) dominates revenue by a wide margin**
SP accounts for R$5.77M — roughly 37% of all delivered revenue. RJ and MG are distant second and third. This concentration makes sense given SP's economic weight in Brazil, but it also means Olist's performance is heavily tied to a single state.

---

### Page 2 — Cancellation & Revenue Loss

**Overall cancellation rate is low at 0.63%**
625 out of 99,441 orders were cancelled. While the rate is low, the revenue impact is real — R$148,450 in lost revenue across the dataset period.

**Cancellations grew steadily through 2017 into 2018**
The cancelled orders trend line shows a clear upward pattern from late 2016 through mid-2018 — consistent with overall order volume growth. Cancellations are growing alongside the business, not faster than it.

**Cool Stuff and Garden Tools lead revenue lost to cancellations**
These two categories account for the largest share of cancellation revenue loss — despite not being top earners in delivered revenue. This is worth flagging: they lose relatively more than they earn compared to top-performing categories like Bed Bath Table.

**Top revenue earners are also the most reliable**
Bed Bath Table (R$1.69M delivered) barely appears in the cancellation data. Health Beauty and Computers Accessories follow the same pattern. The categories that sell the most also cancel the least.

---

## Limitations

- Dataset covers only 2016–2018 — findings may not reflect Olist's current performance
- Payment values are used as a proxy for revenue — actual seller payouts after fees are not available in this dataset
- Review data was not used in this analysis — a follow-up project could combine cancellation rates with review scores to identify categories with both high cancellations and poor ratings
- Edge months (Sep 2016, Sep–Oct 2018) have very few orders and were excluded from cancellation trend analysis to avoid misleading spikes

---

## Dashboard

Power BI dashboard — two pages:
- **Page 1:** Sales Performance (Monthly Revenue, AOV Trend, Revenue by Category, Revenue by State)
- **Page 2:** Cancellation & Revenue Loss (Cancellation Rate, Cancelled Orders Trend, Revenue Lost by Category)

<img width="1164" height="656" alt="image" src="https://github.com/user-attachments/assets/8f07fa33-3e7f-472b-b511-879d999c493b" />

<img width="1165" height="659" alt="image" src="https://github.com/user-attachments/assets/8a413f85-6275-4bf5-9c80-0f9aece7d5b2" />


--

## Files

- `olist_cleaning.ipynb` — Python data cleaning notebook (Google Colab)
- `clean_orders.csv` — cleaned orders table
- `clean_items.csv` — cleaned order items table
- `clean_payments.csv` — cleaned payments table
- `clean_reviews.csv` — cleaned reviews table
- `clean_products.csv` — cleaned products table (with English category names)
- `clean_customers.csv` — cleaned customers table
- `sql_queries/` — folder containing all 6 BigQuery SQL queries as `.sql` files
