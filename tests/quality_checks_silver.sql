/*
============================================================
Quality checks
============================================================
Script Purpose:
This script performs various data quality checks including:
- NULL or duplicate in primary key
- unwanted spaces in string variables
- invalid date ranges
- other checks, which I forgot to save and report
*/

-- DUPLICATES CHECK
select cid, COUNT(*) as flag
from bronze.erp_cust_az12
group by cid
having COUNT(*) > 1 OR cid IS NULL;


-- TRIM CHECK
select sls_ord_num
from bronze.crm_sales_details
where sls_ord_num <> TRIM(sls_ord_num);


--  DATE CHECK
select bdate
from bronze.erp_cust_az12
where bdate > GETDATE();

-- DERIVED COLUMNS
select prd_id,
prd_key,
prd_nm,
prd_start_dt,
DATEADD(day, -1, LEAD(prd_start_dt) over (partition by prd_key order by prd_start_dt)) as new_end_dt
from bronze.crm_prd_info
