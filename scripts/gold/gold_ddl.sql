/*
================================================================================================
Creating 3 views based on 3 predefined objects - sales (fact), products (dim) & customers (dim)
================================================================================================
*/

-- CUSTOMER object view
CREATE VIEW gold.dim_customers AS
select ROW_NUMBER () over (order by cst_id) as customer_key,
cust.cst_id as customer_id,
cust.cst_key as customer_num,
cust.cst_firstname as first_name,
cust.cst_lastname as last_name,
birth.bdate as birthdate,
loc.cntry as country,
CASE
WHEN cust.cst_gndr IS NOT NULL THEN cust.cst_gndr
WHEN birth.gen = 'n/a' THEN NULL
ELSE lower(birth.gen)
END as gender,
cust.cst_marital_status as marital_status,
cust.cst_create_date as create_date
from silver.crm_cust_info cust
left join silver.erp_loc_a101 loc
	on cust.cst_key = loc.cid
left join silver.erp_cust_az12 birth
	on cust.cst_key = birth.cid;


-- PRODUCT object view
CREATE VIEW gold.dim_products AS
select ROW_NUMBER() over (order by prd_start_dt) as product_key,
p.prd_id as product_id,
p.prd_key as product_num,
p.prd_nm as product_name,
p.prd_cost as cost,
p.prd_line as product_line,
p.prd_start_dt as startdate,
p.prd_end_dt as enddate,
p.cat_key as category_num,
cat.cat as category,
cat.subcat as subcategory,
cat.maintenance as maintenance
from silver.crm_prd_info p
left join silver.erp_px_cat_g1v2 cat
	on p.cat_key = cat.id
where p.prd_end_dt IS NULL;


-- SALES object view
CREATE VIEW gold.fact_sales AS
select s.sls_ord_num as order_num,
p.product_key,
c.customer_key,
s.sls_order_dt orderdate,
s.sls_ship_dt shipdate,
s.sls_due_dt duedate,
s.sls_sales sales_amount,
s.sls_quantity quantity,
s.sls_price price
from silver.crm_sales_details s
left join gold.dim_products p
	on s.sls_prd_key = p.product_num
left join gold.dim_customers c
	on s.sls_cust_id = c.customer_id;
