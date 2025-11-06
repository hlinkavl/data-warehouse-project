/*
==================================================================================
Load Data into Bronze Layer
==================================================================================
Script Purpose:
    This script creates new stored procedure, which starts with truncating a table
    and then bulk inserting from appropriate CSV file into that table. Also added 
    variables to track the upload duration time in seconds.
*/

-- creating stored procedure
GO
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN

DECLARE @start_time DATETIME, @end_time DATETIME;
SET @start_time = GETDATE ();

BEGIN TRY
PRINT '===========================================================';
PRINT 'Loading bronze layer - truncate & bulk insert into 6 tables';
PRINT '===========================================================';

PRINT '-------------------------------------------------------------';
PRINT 'Loading CRM system tables: cust_info, prd_info, sales_details';
PRINT '-------------------------------------------------------------';
-- cust_info bulk insert
TRUNCATE table bronze.crm_cust_info;

BULK INSERT bronze.crm_cust_info
FROM 'C:\Users\hlink\OneDrive\Dokumenty\Data Analytika\_data_warehouse\datasets\source_crm\cust_info.csv'
WITH (
FIRSTROW = 2,
FIELDTERMINATOR = ',',
TABLOCK
);

-- prd_info bulk insert
TRUNCATE table bronze.crm_prd_info;

BULK INSERT bronze.crm_prd_info
FROM 'C:\Users\hlink\OneDrive\Dokumenty\Data Analytika\_data_warehouse\datasets\source_crm\prd_info.csv'
WITH (
FIRSTROW = 2,
FIELDTERMINATOR = ',',
TABLOCK
);

-- sales_details bulk insert
TRUNCATE table bronze.crm_sales_details;

BULK INSERT bronze.crm_sales_details
FROM 'C:\Users\hlink\OneDrive\Dokumenty\Data Analytika\_data_warehouse\datasets\source_crm\sales_details.csv'
WITH (
FIRSTROW = 2,
FIELDTERMINATOR = ',',
TABLOCK
);
PRINT '-------------------------------------------------------------';
PRINT 'Loading ERP system tables: cust_az12, loc_a101, px_cat_g1v2';
PRINT '-------------------------------------------------------------';

-- cust_az12 bulk insert
TRUNCATE table bronze.erp_cust_az12;

BULK INSERT bronze.erp_cust_az12
FROM 'C:\Users\hlink\OneDrive\Dokumenty\Data Analytika\_data_warehouse\datasets\source_erp\CUST_AZ12.csv'
WITH (
FIRSTROW = 2,
FIELDTERMINATOR = ',',
TABLOCK
);

-- loc_a101 bulk insert
TRUNCATE table bronze.erp_loc_a101

BULK INSERT bronze.erp_loc_a101
FROM 'C:\Users\hlink\OneDrive\Dokumenty\Data Analytika\_data_warehouse\datasets\source_erp\LOC_A101.csv'
WITH (
FIRSTROW = 2,
FIELDTERMINATOR = ',',
TABLOCK
);

-- px_cat_g1v2 bulk insert
TRUNCATE table bronze.erp_px_cat_g1v2

BULK INSERT bronze.erp_px_cat_g1v2
FROM 'C:\Users\hlink\OneDrive\Dokumenty\Data Analytika\_data_warehouse\datasets\source_erp\PX_CAT_G1V2.csv'
WITH (
FIRSTROW = 2,
FIELDTERMINATOR = ',',
TABLOCK
);

SET @end_time = GETDATE ();
PRINT '===================================================================================';
PRINT 'Load duration:' + CAST (DATEDIFF(second, @start_time, @end_time) as VARCHAR) + 'sec';
PRINT '===================================================================================';

END TRY

BEGIN CATCH
PRINT '=================================================================';
PRINT 'Whoopsie-daisy, something went wrong. Ask god or ChatGPT for help';
PRINT 'Error Message'+ ERROR_MESSAGE ();
PRINT '=================================================================';
END CATCH
END
