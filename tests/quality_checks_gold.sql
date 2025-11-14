/*
============================================================
Quality checks
============================================================
Script Purpose:
This script performs various data quality checks including:
- NULL or duplicate in primary key
- missing values in the dimension tables
*/


-- NEW GENDER COLUMN CHECK
select * from (
select cust.*,
birth.gen as old_gen,
CASE
WHEN cust.cst_gndr IS NOT NULL THEN cust.cst_gndr
WHEN birth.gen = 'n/a' THEN NULL
ELSE lower(birth.gen)
END as new_gen
from silver.crm_cust_info cust
left join silver.erp_loc_a101 loc
	on cust.cst_key = loc.cid
left join silver.erp_cust_az12 birth
	on cust.cst_key = birth.cid
)t
where cst_gndr IS NULL
and old_gen = 'n/a';

select *
from silver.erp_px_cat_g1v2;


-- PRIMARY KEY DUPLICATES CHECK
select prd_key, COUNT(*) as flag
from (
select p.prd_id,
p.cat_key,
p.prd_key,
p.prd_nm,
p.prd_cost,
p.prd_line,
p.prd_start_dt,
p.prd_end_dt,
cat.cat,
cat.subcat,
cat.maintenance
from silver.crm_prd_info p
left join silver.erp_px_cat_g1v2 cat
	on p.cat_key = cat.id
where p.prd_end_dt IS NULL
)t
group by prd_key
having COUNT(*) > 1;


-- MISSING PRODUCTS CHECK
select *
from gold.fact_sales f
left join gold.dim_products p
	on f.product_key = p.product_key
where p.product_key IS NULL;


-- MISSING CUSTOMERS CHECK
select *
from gold.fact_sales f
left join gold.dim_customers c
	on f.customer_key = c.customer_key
where c.customer_key IS NULL;
