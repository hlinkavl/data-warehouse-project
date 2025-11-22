

USE DataWarehouse;

select *
from gold.fact_sales;

select *
from gold.dim_customers;

select *
from gold.dim_products;


-- product hierarchy
select distinct category, subcategory, product_name
from gold.dim_products;

-- date ranges
select MIN(orderdate) as min_dt, MAX(orderdate) as max_dt, DATEDIFF(YEAR, MIN(orderdate), MAX(orderdate)) as dt_diff
from gold.fact_sales;

select DATEDIFF(YEAR, MIN(birthdate), GETDATE()) as age_old, DATEDIFF(YEAR, MAX(birthdate), GETDATE()) as age_young
from gold.dim_customers;


-- exploring measures
select COUNT(DISTINCT order_num) as total_orders, AVG(price) as avg_price, SUM(sales_amount) as total_sales, SUM(quantity) as items_sold
from gold.fact_sales;


-- products sold & customers with orders
select COUNT(DISTINCT product_key) as products_sold, COUNT (DISTINCT customer_key) as cust_count
from gold.fact_sales;

select COUNT(DISTINCT customer_key) as all_cust
from gold.dim_customers;

select COUNT(DISTINCT product_key) as all_prod
from gold.dim_products;

-- MEASURES OVERVIEW
select 'total_orders' as measure_name, COUNT(DISTINCT order_num) as measure_value from gold.fact_sales
UNION
select 'avg_price', AVG(price) from gold.fact_sales
UNION
select 'total_sales', SUM(sales_amount) from gold.fact_sales
UNION
select 'items_sold', SUM(quantity) from gold.fact_sales
UNION
select 'products_sold', COUNT(DISTINCT product_key) from gold.fact_sales
UNION
select 'cust_count', COUNT(DISTINCT customer_key) from gold.fact_sales;


-- MAGNITUDE ANALYSIS
select country, COUNT(customer_key) as cust_count, SUM(COUNT(customer_key)) over (order by COUNT(customer_key) desc) as running_cust
from gold.dim_customers
group by country;


select gender, COUNT(customer_key) as cust_count
from gold.dim_customers
group by gender
order by cust_count desc;


-- product categories
select category, COUNT(product_key) as product_count
from gold.dim_products
group by category
order by product_count desc;

select category, AVG(cost) as avg_cost
from gold.dim_products
group by category
order by avg_cost desc;


-- sales by product
select p.category, SUM(s.sales_amount) as total_sales
from gold.fact_sales s
left join gold.dim_products p
	on s.product_key = p.product_key
group by p.category
order by total_sales desc;

select s.*, p.category, p.subcategory, p.product_name
from gold.fact_sales s
left join gold.dim_products p
	on s.product_key = p.product_key
where category = 'Components';


-- sales by customer
select c.customer_key, c.first_name, c.last_name, SUM(s.sales_amount) as cust_sales
from gold.fact_sales s
left join gold.dim_customers c
	on s.customer_key = c.customer_key
group by c.customer_key, c.first_name, c.last_name
order by cust_sales desc;


-- sales by country
select *, SUM(cust_count) over (order by cust_sales desc) as running_total
from (
select c.country, COUNT (DISTINCT c.customer_key) as cust_count, SUM(s.sales_amount) as cust_sales
from gold.fact_sales s
left join gold.dim_customers c
	on s.customer_key = c.customer_key
group by c.country
)t

select c.country, SUM(s.quantity) as total_items
from gold.fact_sales s
left join gold.dim_customers c
	on s.customer_key = c.customer_key
group by c.country
order by total_items desc;


-- RANKING ANALYSIS
select top 5
p.product_key, p.category, p.product_name, SUM(s.sales_amount) as sales_per_product
from gold.fact_sales s
left join gold.dim_products p
	on s.product_key = p.product_key
group by p.product_key, p. category, p.product_name
order by sales_per_product desc;


select *
from (
select
p.product_key, p.category, p.product_name, SUM(s.sales_amount) as sales_per_product, RANK() over (order by SUM(s.sales_amount) desc) as prod_rank
from gold.fact_sales s
left join gold.dim_products p
	on s.product_key = p.product_key
group by p.product_key, p. category, p.product_name
)t
where prod_rank < 11;


-- sales by subcategory
select top 5
p.subcategory, SUM(s.sales_amount) as sales_per_subcat
from gold.fact_sales s
left join gold.dim_products p
	on s.product_key = p.product_key
group by p.subcategory
order by sales_per_subcat desc;


-- sales by customer
select top 10
c.customer_key, c.first_name, c.last_name, SUM(s.sales_amount) as cust_sales
from gold.fact_sales s
left join gold.dim_customers c
	on s.customer_key = c.customer_key
group by c.customer_key, c.first_name, c.last_name
order by cust_sales desc;
