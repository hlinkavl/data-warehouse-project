-- change over  time
select 
YEAR(orderdate) order_year,
SUM(sales_amount) sales_sum,
COUNT (DISTINCT customer_key) cust_count,
SUM(quantity) items_sold
from gold.fact_sales
where orderdate IS NOT NULL
group by YEAR(orderdate)
order by order_year;


select 
DATETRUNC(month, orderdate) as orderdate_trunc,
SUM(sales_amount) sales_sum,
COUNT (DISTINCT customer_key) cust_count,
SUM(quantity) items_sold
from gold.fact_sales
where orderdate IS NOT NULL
group by DATETRUNC(month, orderdate)
order by DATETRUNC(month, orderdate);


-- seasonal changes
select 
MONTH(orderdate) order_month,
SUM(sales_amount) sales_sum,
COUNT (DISTINCT customer_key) cust_count,
SUM(quantity) items_sold
from gold.fact_sales
where orderdate IS NOT NULL
group by MONTH(orderdate)
order by order_month;


-- cumulative analysis
with sales_over_time as (
select DATETRUNC(month, orderdate) as orderdate,
SUM(sales_amount) as sales_sum
from gold.fact_sales
where orderdate IS NOT NULL
group by DATETRUNC(month, orderdate)
)
select *, SUM(sales_sum) over (order by orderdate) as cumulated_sales
from sales_over_time;


-- performance analysis
with prod_yr_sales as (
select
YEAR(s.orderdate) order_yr,
p.product_name,
SUM(s.sales_amount) sales_sum
from gold.fact_sales s
left join gold.dim_products p
	on s.product_key = p.product_key
where s.orderdate IS NOT NULL
group by YEAR(s.orderdate), p.product_name
)
select *,
AVG(sales_sum) over (partition by product_name) avg_prod_sales,
sales_sum - AVG(sales_sum) over (partition by product_name) avg_diff,
LAG(sales_sum) over (partition by product_name order by product_name, order_yr) pre_yr_sales,
sales_sum - LAG(sales_sum) over (partition by product_name order by product_name, order_yr) yoy_diff
from prod_yr_sales
order by product_name, order_yr;


-- part-to-whole analysis
with category_sales as (
select 
p.category,
SUM(s.sales_amount) as sales_per_cat
from gold.fact_sales s
left join gold.dim_products p
	on s.product_key = p.product_key
group by p.category
)
select *, ROUND (CAST(sales_per_cat as float)/SUM(sales_per_cat) over (), 2) as cat_percentage
from category_sales;


-- data segmentation
with cost_segmentation as (
select
product_key,
product_name,
cost,
CASE
WHEN cost < 100 then 'below 100'
WHEN cost < 500 then '100-500'
WHEN cost < 1000 then '500-1000'
ELSE 'above 1000'
END as cost_bins
from gold.dim_products
)
select distinct cost_bins,
COUNT(product_key) over (partition by cost_bins) product_count
from cost_segmentation
order by product_count desc;


-- customer spending bins
with customer_spending as (
select 
c.customer_key,
SUM(s.sales_amount) as sales_per_cust,
MIN(s.orderdate) as first_order,
MAX(s.orderdate) as last_order,
DATEDIFF(month, MIN(s.orderdate), MAX(s.orderdate)) as customer_lifespan
from gold.dim_customers c
left join gold.fact_sales s
on c.customer_key = s.customer_key
group by c.customer_key
),
spending_categories as (
select *,
CASE 
WHEN customer_lifespan > 12 AND sales_per_cust > 5000 then 'VIP'
WHEN customer_lifespan > 12 AND sales_per_cust <= 5000 then 'regular'
ELSE 'newbie'
END as cust_ranked
from customer_spending
)
select cust_ranked,
COUNT(customer_key) as cust_count
from spending_categories
group by cust_ranked;
