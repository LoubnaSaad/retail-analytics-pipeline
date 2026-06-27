--Schema
create schema if not exists mart;

--tables
--1:Time KPIS
--1.1:days
drop table if exists mart.sales_daily;
create table mart.sales_daily as
select 
 d.full_date,
d.year,
d.month,
d.month_name,
d.quarter,
d.day_name,
d.is_weekend,
case when d.is_weekend then 'Weekend' else 'Weekday' end as day_type,
case when d.year = 2021 then true else false end as is_current_year,
count(distinct f.order_id) as numbers_of_orders,
sum(sales) as total_sales,
sum(profit) as total_profit,
sum(cost) as total_costs,
sum(quantity) as total_quantity,
AVG(f.sales::numeric) as avg_order_value,
(SUM(f.profit) / nullif(SUM(f.sales),0)) * 100 as profit_margin_pct,
COUNT(DISTINCT f.customer_key) as active_customers,
sum(case when f.discount > 0 then f.sales else 0 end) as sales_with_discount,
sum(case when f.discount = 0 then f.sales else 0 end) as sales_without_discount,
(sum(case when f.discount > 0 then f.sales else 0 end) / nullif(sum(f.sales),0) * 100) as discount_sales_pct
from dwh.fact_sales f
left join dwh.dim_date d on d.date_key= f.order_date_key
group by d.full_date,d.year , d.month, d.month_name,d.quarter,d.day_name,d.is_weekend
order by d.full_date;

--1.2:months
drop table if exists mart.sales_monthly;
create table  mart.sales_monthly as
select 
d.year,
d.month,
d.month_name,
d.quarter,
case when d.year = 2021 then true else false end as is_current_year,
lag(sum(f.sales)) over (order by d.year,d.month )as prev_month_sales,
((sum(f.sales)-lag(sum(f.sales)) over (order by d.year,d.month))/
nullif(lag(sum(f.sales)) over (order by d.year,d.month),0)* 100) as monthly_sales_growth_pct,
count(distinct f.order_id) as numbers_of_orders,
sum(sales) as total_sales,
sum(profit) as total_profit,
sum(cost) as total_costs,
sum(quantity) as total_quantity,
COUNT(DISTINCT f.customer_key) as active_customers,
AVG(f.sales)as avg_order_value,
(SUM(f.profit) / nullif(SUM(f.sales),0) * 100) as profit_margin_pct,
sum(case when f.discount > 0 then f.sales else 0 end) as sales_with_discount,
sum(case when f.discount = 0 then f.sales else 0 end) as sales_without_discount,
(sum(case when f.discount > 0 then f.sales else 0 end) / nullif(sum(f.sales),0) * 100) as discount_sales_pct,
125000 as monthly_target,
(sum(f.sales) / 125000 * 100) as target_achievement_pct
from dwh.fact_sales f
left join dwh.dim_date d on d.date_key= f.order_date_key
group by d.year, d.month, d.month_name,d.quarter
order by d.year, d.month;

--2:products KPIS
drop table if exists mart.product_sales;
create table mart.product_sales as
select p.category,
p.sub_category,
min(p.product_name) as product_name,
p.product_id,
count(distinct f.order_id) as times_ordered,
sum(sales) as total_sales,
sum(profit) as total_profit,
sum(cost) as total_costs,
AVG(f.sales) as avg_sale_price,
(AVG(f.discount) * 100) as avg_discount_pct,
sum(quantity) as total_quantity,
(SUM(f.profit) / nullif(SUM(f.sales),0) * 100) as profit_margin_pct,
Rank() over (order by sum(f.sales) desc ) as sales_rank,
Rank() over (order by sum(f.profit) desc ) as profit_rank,
RANK() OVER (PARTITION BY p.category ORDER BY SUM(f.sales) DESC) as rank_in_category, 
CURRENT_DATE as last_updated
from dwh.fact_sales f
left join dwh.dim_product p on p.product_key= f.product_key
group by p.category,
p.sub_category,
p.product_id
order by total_sales desc;
alter table mart.product_sales ADD PRIMARY KEY (product_id);
create index idx_product_sales_rank on mart.product_sales(sales_rank); 

--3:Customers KPIS
--3.1: Customers 
drop table if exists mart.customers;
create table mart.customers as 
with customer_base as ( select     
 c.customer_id,
        c.customer_name,
        c.segment,
        c.region,
        c.state,
        c.city,
max(d.full_date) as last_purchase_date,
min(d.full_date) as first_purchase_date,
count(distinct f.order_id) as total_orders,
sum(f.profit) as total_profit,
sum(f.sales) as total_sales,
avg(f.sales) as avg_order_value,
avg(f.discount) as avg_discount_rate,
current_date - max(d.full_date) as days_since_last_purchase,
max(d.full_date) -min(d.full_date) as customer_lifetime_days
from dwh.fact_sales f
JOIN dwh.dim_date d ON f.order_date_key = d.date_key
left join  dwh.dim_customer c on c.customer_key=f.customer_key
group by  c.customer_id,
        c.customer_name,
        c.segment,
        c.region,
        c.state,
        c.city
)
select 
 c.customer_id,
c.customer_name,
c.segment,
c.region,
c.state,
c.city,
c.avg_discount_rate,
last_purchase_date,
first_purchase_date,
days_since_last_purchase,
customer_lifetime_days,
total_sales,
total_profit,
total_orders,
avg_order_value,
(total_profit / nullif(total_sales,0) * 100) as profit_margin_pct,
--flags
case when days_since_last_purchase <=90 then true else false end as is_active,
case when total_orders > 1 then true else false end as is_repeat_customer ,
--statuse
case
	when days_since_last_purchase <= 30 then 'Very Active'
	when days_since_last_purchase <= 90 then 'Active'
	when days_since_last_purchase <= 180 then 'At Risk'
	when days_since_last_purchase <= 365 then 'Dormant'
else 'Lost'
end as customer_status,
 -- Value Tier
case 
	when total_sales >= 10000 then 'VIP'
	when total_sales >= 5000 then 'High Value'
	when total_sales >= 1000 then 'Medium Value'
	else 'Low Value'
end as value_tier,
--LTV 
total_sales as ltv_total,
case when customer_lifetime_days >0 then ((total_sales/customer_lifetime_days)*365) else total_sales end as ltv_projected_annual,
--RFM
ntile(5) over (order by total_sales desc) as rfm_spending_score,
ntile(5) over (order by days_since_last_purchase asc) as rfm_recency_score,
ntile(5) over (order by total_orders desc) as rfm_frequency_score,
CURRENT_DATE as last_updated	
from  customer_base c;
ALTER TABLE mart.customers ADD PRIMARY KEY (customer_id);
create index idx_customers_active on mart.customers(is_active);
create index idx_customers_segment on mart.customers(segment);

--3.2: Customer Cohorts
drop table if exists mart.customer_cohorts;
create table mart.customer_cohorts as
with customer_first_purchase as (
    select 
        customer_key,
        min(order_date_key) as first_order_date_key
    from dwh.fact_sales
    group by customer_key
),
monthly_activity as (
    select distinct
        date_trunc('month', d.full_date)::date as cohort_month,
        d.year,
        d.month,
        f.customer_key,
        date_trunc('month', fd.full_date)::date as first_purchase_month
    from dwh.fact_sales f
    join dwh.dim_date d on f.order_date_key = d.date_key
    join customer_first_purchase cfp on f.customer_key = cfp.customer_key
    join dwh.dim_date fd on cfp.first_order_date_key = fd.date_key
),
monthly_counts as (
    select 
        cohort_month,
        year,
        month,
        count(distinct customer_key) as active_customers,
        count(distinct case when cohort_month = first_purchase_month then customer_key end) as new_customers,
        count(distinct case when cohort_month > first_purchase_month then customer_key end) as returning_customers
    from monthly_activity
    group by cohort_month, year, month
)
select 
    cohort_month,
    year,
    month,
    active_customers,
    new_customers,
    returning_customers,
    lag(active_customers) over (order by cohort_month) as prev_month_active,
    lag(active_customers) over (order by cohort_month) - (active_customers - new_customers) as churned_customers,
    (case 
        when lag(active_customers) over (order by cohort_month) = 0 then 0
        else ((lag(active_customers) over (order by cohort_month) - (active_customers - new_customers))::numeric / 
              lag(active_customers) over (order by cohort_month) * 100)
    end) as churn_rate_pct,
    (case 
        when lag(active_customers) over (order by cohort_month) = 0 then 0
        else (returning_customers::numeric / lag(active_customers) over (order by cohort_month) * 100)
    end) as retention_rate_pct
from monthly_counts
order by cohort_month;
alter table mart.customer_cohorts add primary key (cohort_month);

--4:Overall KPIS
drop table if exists mart.executive_summary;
create table mart.executive_summary as 
select 
'Overall Business' as metric_scope,
current_date as last_updated,
count(distinct order_id) as total_number_orders,
count(distinct customer_key) as total_number_customers,
count(distinct product_key) as total_number_products,
((select count(*) from mart.customers where is_active = true)::numeric / 
          nullif((select count(*) from mart.customers),0) * 100) as active_customer_pct,
((select count(*) from mart.customers where is_repeat_customer = true)::numeric / 
          nullif((select count(*) from mart.customers),0) * 100) as repeat_customer_pct,
    
(select count(*) from mart.customers where is_active = true) as active_customers,
(select count(*) from mart.customers where is_repeat_customer = true) as repeat_customers,
(select avg(ltv_total) from mart.customers) as avg_customer_ltv,
sum(sales) as total_sales,
sum(profit) as total_profit,
sum(cost) as total_costs,
sum(quantity) as total_quantity,
sum(sales)/nullif(count(distinct customer_key),0) as sales_per_customer,
sum(sales)/nullif(count(distinct order_id),0) as sales_per_order,
avg(discount)*100 as avg_discount_pct,
sum(profit)/nullif(sum(sales),0) * 100 as profit_margin_pct,
count(case when discount > 0 then 1 end ) as discounted_orders,
(count(case when discount > 0 then 1 end ):: numeric / nullif(count(*),0) ) *100 as discount_penetration_pct
from dwh.fact_sales;
alter table mart.executive_summary add PRIMARY KEY (metric_scope);

--verification
select 
    'sales_daily' as table_name, count(*) as rows from mart.sales_daily
union all
select 'sales_monthly', count(*) from mart.sales_monthly
union all
select 'product_sales', count(*) from mart.product_sales
union all
select 'customers', count(*) from mart.customers
union all
select 'customer_cohorts', count(*) from mart.customer_cohorts
union all
select 'executive_summary', count(*) from mart.executive_summary;

--drop redundant tables
drop table if exists dwh.fact_sales_test cascade;
drop table if exists mart.sales_quartely cascade;
drop table if exists mart.sales_by_day_type cascade;
drop table if exists mart.aggregations cascade;
