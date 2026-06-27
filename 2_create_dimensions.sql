-- Customer Dim Table
drop table if exists dwh.dim_Customer CASCADE ;

Create Table dwh.dim_Customer as
select  
Row_Number() over (order by customer_id_temp) as customer_key, --simpler than the original customer id
customer_id_temp as customer_id,
"Region" as region,
"Postal Code" as postal_code,
"City" as city,
"Customer Name" as customer_name,
"State" as state,
"Segment" as segment,
"Country/Region" as country,
CURRENT_TIMESTAMP AS created_at --for audit 

from (select 
distinct on ("Customer ID")
"Customer ID" as customer_id_temp,
"City",
"State",
"Segment",
"Country/Region",
"Postal Code",
"Region",
"Customer Name"
from staging.staging_raw
where "Customer ID" is not null
) as customer_data;
alter table dwh.dim_customer add primary key (customer_key);
CREATE UNIQUE INDEX idx_customer_id ON dwh.dim_customer(customer_id);

--Create Dim product
drop table if exists dwh.dim_product CASCADE;

create table dwh.dim_product as 
select  row_number() over (order by "Product ID") as product_key,
"Category" as category,
"Product ID" as product_id,
"Sub-Category" as sub_category,
"Product Name" as product_name,
current_timestamp as created_at
from ( select distinct "Product ID",
"Category",
"Sub-Category",
"Product Name"
from staging.staging_raw
where "Product ID" is not null
) as product_data ;
alter table dwh.dim_product add primary key (product_key);
CREATE UNIQUE INDEX idx_product_id ON dwh.dim_product(product_key);

--Create Dim Date
drop table if exists dwh.dim_date;
create table dwh.dim_date as 
select 
to_char(date_val,'YYYYMMDD'):: integer as date_key,-- an index for date to make joins faster
date_val as full_date,
extract(year from date_val) :: integer as year,
extract(day from date_val) :: integer as day,
extract(quarter from date_val) :: integer as quarter,
extract(month from date_val) :: integer as month,
extract(week from date_val) :: integer as week_of_year ,--1:52 in a year
extract(dow from date_val) :: integer as day_of_week ,--0:6 0= sunday 
to_char(date_val,'MONTH') as month_name,
to_char(date_val,'Day') as day_name,
CASE WHEN EXTRACT(DOW FROM date_val) IN (0,6) THEN TRUE ELSE FALSE END AS is_weekend

from ( select
distinct "Order Date" :: date as date_val
    FROM staging.staging_raw
where "Order Date" is not null
union 
select distinct "Ship Date" :: date as date_val
    FROM staging.staging_raw
where "Ship Date" is not null
) as date_data;
alter table dwh.dim_date add primary key (date_key);
CREATE UNIQUE INDEX idx_date_id ON dwh.dim_date(date_key);

-- Create ship dim 
-- Drop the broken table first
DROP TABLE IF EXISTS dwh.dim_ship CASCADE;

-- Create it correctly (remove DISTINCT ON, just use DISTINCT)
CREATE TABLE dwh.dim_ship AS 
SELECT 
    row_number() OVER (ORDER BY ship_mode) as ship_mode_key,
    ship_mode,
    CURRENT_TIMESTAMP as created_at
FROM (
    SELECT DISTINCT "Ship Mode" as ship_mode
    FROM staging.staging_raw
    WHERE "Ship Mode" IS NOT NULL
      AND "Ship Mode" != 'sas'
) as ship_data;

ALTER TABLE dwh.dim_ship ADD PRIMARY KEY (ship_mode_key);
CREATE UNIQUE INDEX idx_ship_mode ON dwh.dim_ship(ship_mode);

-- Verify it's fixed (should show 4-5 rows now)
SELECT * FROM dwh.dim_ship ORDER BY ship_mode_key;