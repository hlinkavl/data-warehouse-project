/*
========================================================================
CUSTOMER REPORT
========================================================================

Highlights:
1) gathers basic customer info (name, age...)
2) aggregates customer level metrics (orders, sales, quantity)
3) segments customers into categories based on spending & age groups
4) calculates valuable KPIs (avg order value, avg monthly revenue)

========================================================================
*/

CREATE OR ALTER VIEW gold.report_customers AS
with base_query as (
-- step 1: base query (retrieves core columns from tables)
select
order_num,
f.product_key,
orderdate,
quantity,
sales_amount,
c.customer_key,
concat(first_name, ' ', last_name) full_name,
DATEDIFF(year, birthdate, GETDATE()) age
from gold.fact_sales f
left join gold.dim_customers c
on f.customer_key = c.customer_key
left join gold.dim_products p
on f.product_key = p.product_key
where orderdate IS NOT NULL
),


customer_aggregations as (
-- step 2: customer agg (calculates agg measures per every customer)
select
customer_key,
full_name,
age,
COUNT(distinct order_num) order_count,
SUM(sales_amount) total_sales,
SUM(quantity) total_quantity,
COUNT(distinct product_key) total_products,
DATEDIFF(month, MIN(orderdate), MAX(orderdate)) lifespan
from base_query
group by customer_key, full_name, age
)
-- step 3: segmenting customers based on age & spendings
select
customer_key,
full_name,
age,
CASE WHEN age < 20 THEN 'under 20'
	 WHEN age between 20 and 40 THEN '20-40'
	 WHEN age between 41 and 60 THEN '41-60'
ELSE 'over 60'
END as age_group,
CASE WHEN lifespan > 12 AND total_sales > 5000 then 'VIP'
	 WHEN lifespan > 12 AND total_sales <= 5000 then 'regular'
ELSE 'newbie'
END as cust_segments,
order_count,
total_sales,
total_quantity,
total_products,
lifespan,
-- step 4: avg order value
CASE WHEN order_count = 0 THEN 0
ELSE total_sales/order_count
END AS avg_order_value,
--step 4: avg monthly spendings
CASE WHEN lifespan = 0 THEN total_sales
ELSE total_sales/lifespan
END AS avg_monthly_spent
from customer_aggregations
