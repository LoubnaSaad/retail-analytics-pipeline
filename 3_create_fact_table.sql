--Create fact sales 
drop table if exists  dwh.fact_sales CASCADE;

create table dwh.fact_sales as
select row_number() over (order by s."Order ID" ,s."Row ID") as sales_key,

COALESCE(c.customer_key,-1) as customer_key,
COALESCE(p.product_key,-1) as product_key,
COALESCE(sh.ship_mode_key,-1) as ship_mode_key,
COALESCE(d.date_key,-1) as order_date_key,
COALESCE(d2.date_key,-1) as ship_date_key,


s."Row ID" as row_id,
s."Order ID" as order_id,

"Sales" as sales,
"Quantity" as quantity,
"Discount" as discount,
"Profit" as profit,

(s."Sales"-s."Profit") as "cost",
case 
	when s."Sales" > 0 then(s."Profit"/s."Sales") * 100
	else 0
end	as profit_margin_pct,

CURRENT_TIMESTAMP AS loaded_at
from staging.staging_raw s
---joins
left join dwh.dim_customer c on c.customer_id=s."Customer ID"
left join dwh.dim_product p  on p.product_id = s."Product ID"
left join dwh.dim_ship sh    on sh.ship_mode=s."Ship Mode"
left join dwh.dim_date 	d	 on d.date_key= to_char(s."Order Date",'YYYYMMDD') :: integer  --order date
left join dwh.dim_date d2	 on d2.date_key= to_char(s."Ship Date",'YYYYMMDD') :: integer  --ship date
WHERE s."Order ID" IS NOT NULL;
--Primary key of sales fact table
ALTER TABLE dwh.fact_sales ADD PRIMARY KEY (sales_key);
--Foreign key of sales fact table
alter table dwh.fact_sales 
	add constraint fk_customer foreign key(customer_key) references dwh.dim_customer(customer_key),
	add constraint fk_product foreign key(product_key) references dwh.dim_product(product_key),
	add constraint fk_ship foreign key(ship_mode_key) references dwh.dim_ship(ship_mode_key),
	add constraint fk_ship_date foreign key(ship_date_key) references dwh.dim_date(date_key),
	add constraint fk_order_date foreign key(order_date_key) references dwh.dim_date(date_key);
-- Create Indexes for performance
CREATE INDEX idx_fact_customer ON dwh.fact_sales(customer_key);
CREATE INDEX idx_fact_product ON dwh.fact_sales(product_key);
CREATE INDEX idx_fact_order_date ON dwh.fact_sales(order_date_key);
CREATE INDEX idx_fact_ship_date ON dwh.fact_sales(ship_date_key);
CREATE INDEX idx_fact_order_id ON dwh.fact_sales(order_id);

