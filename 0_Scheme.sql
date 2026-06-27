--Create schema for staging and datawarehouse
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS dwh;
--Confirm if they created
SELECT schema_name 
FROM information_schema.schemata 
WHERE schema_name IN ('staging', 'dwh');