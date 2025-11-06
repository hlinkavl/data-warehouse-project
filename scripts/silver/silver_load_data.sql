/*
=======================================================================================
Load Data into Silver Layer
=======================================================================================
Script Purpose:
    This script creates new stored procedure, which starts with truncating every table
	  in the silver layer and then inserts clean & transformed data from bronze tables 
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN

DECLARE @start_time DATETIME, @end_time DATETIME;
SET @start_time = GETDATE ();

BEGIN TRY

PRINT '================================================================'
PRINT 'Loading silver layer - truncate & load clean & transformed data'
PRINT '================================================================'

  -- CUST_INFO
PRINT 'Truncating table'
TRUNCATE TABLE silver.crm_cust_info;

PRINT 'INSERT INTO silver.crm_cust_info'
insert into silver.crm_cust_info (cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date)
select cst_id,
cst_key,
TRIM (cst_firstname) as cst_firstname,
TRIM (cst_lastname) as cst_lastname,
CASE
WHEN cst_marital_status = 'M' THEN 'married'
WHEN cst_marital_status = 'S' THEN 'single'
END as cst_marital_status,
CASE 
WHEN UPPER (cst_gndr) = 'M' THEN 'male'
WHEN UPPER (cst_gndr) = 'F' THEN 'female'
END as cst_gndr,
cst_create_date
from (
select *,
ROW_NUMBER() over (partition by cst_id order by cst_create_date desc) as flag_id
from bronze.crm_cust_info
where cst_id IS NOT NULL
)t
where flag_id = 1


-- PRD_INFO
PRINT 'Truncating table'
TRUNCATE TABLE silver.crm_prd_info;

PRINT 'INSERT INTO silver.crm_prd_info'
insert into silver.crm_prd_info (prd_id, cat_key, prd_key, prd_nm, prd_cost,prd_line, prd_start_dt, prd_end_dt)
select prd_id,
REPLACE (SUBSTRING(prd_key, 1, 5), '-', '_') as cat_key,
SUBSTRING(prd_key, 7, LEN(prd_key)) as prd_key,
TRIM (prd_nm) as prd_nm,
COALESCE(prd_cost, 0) as prd_cost,
CASE
WHEN prd_line = 'R' THEN 'Road'
WHEN prd_line = 'M' THEN 'Mountain'
WHEN prd_line = 'S' THEN 'other Sales'
WHEN prd_line = 'T' THEN 'Touring'
END as prd_line,
prd_start_dt,
DATEADD(day, -1, LEAD(prd_start_dt) over (partition by prd_key order by prd_start_dt)) as new_end_dt
from bronze.crm_prd_info


-- SALES_DETAILS
PRINT 'Truncating table'
TRUNCATE TABLE silver.crm_sales_details;

PRINT 'INSERT INTO silver.crm_sales_details'
insert into silver.crm_sales_details (sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price)
select sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE
WHEN sls_order_dt = 0 OR LEN(sls_order_dt) <>8 THEN NULL
ELSE CAST(CAST (sls_order_dt as VARCHAR) as DATE)
END as sls_order_dt,
CASE
WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) <>8 THEN NULL
ELSE CAST(CAST (sls_ship_dt as VARCHAR) as DATE)
END as sls_ship_dt,
CASE
WHEN sls_due_dt = 0 OR LEN(sls_due_dt) <>8 THEN NULL
ELSE CAST(CAST (sls_due_dt as VARCHAR) as DATE)
END as sls_due_dt,
CASE
WHEN sls_sales <= 0 OR sls_sales <> ABS(sls_price)*sls_quantity THEN ABS(sls_price)*sls_quantity
ELSE sls_sales
END as sls_sales,
sls_quantity,
CASE
WHEN sls_price <= 0 OR sls_price IS NULL THEN sls_sales / sls_quantity
ELSE sls_price
END as sls_price
from bronze.crm_sales_details;


-- CUST_AZ12
PRINT 'Truncating table'
TRUNCATE TABLE silver.erp_cust_az12;

PRINT 'INSERT INTO silver.erp_cust_az12'
insert into silver.erp_cust_az12 (cid, bdate, gen)
select
CASE
WHEN cid LIKE 'NAS%' THEN  SUBSTRING(cid, 4, LEN(cid))
ELSE cid
END as cid,
CASE
WHEN bdate > GETDATE() THEN NULL
ELSE bdate
END as bdate,
CASE
WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
ELSE 'n/a'
END as gen
from bronze.erp_cust_az12;


-- LOC_A101
PRINT 'Truncating table'
TRUNCATE TABLE silver.erp_loc_a101;

PRINT 'INSERT INTO silver.erp_loc_a101'
insert into silver.erp_loc_a101 (cid, cntry)
select 
REPLACE(cid, '-', '') as cid,
CASE WHEN TRIM(cntry) IS NULL or TRIM(cntry) = '' THEN 'n/a'
	 WHEN TRIM (cntry) = 'DE' THEN 'Germany'
	 WHEN TRIM (cntry) IN ('US', 'USA') THEN 'United States'
ELSE TRIM(cntry)
END as cntry
from bronze.erp_loc_a101;


-- PX_CAT_G1V2
PRINT 'Truncating table'
TRUNCATE TABLE silver.erp_px_cat_g1v2;

PRINT 'INSERT INTO silver.erp_px_cat_g1v2'
insert into silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
select
REPLACE(id, 'CO_PD', 'CO_PE') as id,
cat,
subcat,
maintenance
from bronze.erp_px_cat_g1v2

SET @end_time = GETDATE ();
PRINT '===================================================================================';
PRINT 'Load duration:' + CAST (DATEDIFF(second, @start_time, @end_time) as VARCHAR) + 'sec';
PRINT '===================================================================================';

END TRY

BEGIN CATCH
PRINT '==================================================================';
PRINT 'Whoopsie-daisy, something went wrong. Ask god or ChatGPT for help';
PRINT 'Error Message'+ ERROR_MESSAGE ();
PRINT '==================================================================';
END CATCH
END
