create table customers (customer_id varchar(32), customer_unique_id varchar(32), customer_zip_code_prefix char(5), customer_city text,
customer_state char (2))

create table sellers (seller_id varchar(32), seller_zip_code_prefix char(5), seller_city text, seller_state char(2))

CREATE TABLE payments (order_id varchar(32), payment_sequential smallint, payment_type text, payment_installments smallint, 
payment_value numeric(7,2))

create type status as enum (
  'approved',
  'canceled',
  'created',
  'delivered',
  'invoiced',
  'processing',
  'shipped',
  'unavailable'
)


--view enum
SELECT enum_range(NULL::status)

create table orders (order_id varchar(32), customer_id varchar(32), order_status status, order_purchase_timestamp timestamp, order_approved_at timestamp,
order_delivered_carrier_date timestamp, order_delivered_customer_date timestamp, order_estimated_delivery_date date)





--create table geolocation
Create table geolocation (geolocation_zip_code_prefix char(5), geolocation_lat float, geolocation_lng float,
geolocation_city text, geolocation_state char(2))


-- look at count and compare it to excel file
select count(*) 
from geolocation

--geolocation_zip_code_prefix cannot be primary key

--create order_items table
CREATE TABLE order_items (order_id varchar(32), order_item_id smallint, product_id varchar(32), seller_id varchar(32), 
shipping_limit_date timestamp, price numeric(6,2), freight_value numeric(6,2))

--112651 excel rows
select count(*)
from order_items
--count is 112650 correct

--need to fix this one
create table order_reviews_copy (review_id varchar(32), order_id varchar(32), review_score smallint, review_comment_title text,
review_creation_date text, review_answer_timestamp text)

ALTER TABLE order_reviews
ALTER COLUMN review_answer_timestamp TYPE text;

show datestyle;

-- create products table
create table products (product_id varchar(32), product_category_name text, product_name_length smallint,
product_description_length smallint, product_photos_qty smallint, product_weight_g int, product_length_cm smallint, 
product_height_cm smallint, product_width_cm smallint)

-- redo order reviews table
create table order_reviews (review_id varchar(32), order_id varchar(32), review_score smallint, review_comment_title text,
review_creation_date timestamp, review_answer_timestamp timestamp)


-- pk 
alter table customers add primary key (customer_id);
alter table orders add primary key (order_id);
alter table sellers add primary key (seller_id);
alter table products add primary key (product_id);
alter table geolocation add primary key (geolocation_zip_code_prefix);



--fk for payments
alter table payments
add constraint fk_payments_orders foreign key (order_id) references orders (order_id); 

--fk for orders table
alter table orders
add constraint fk_orders_customers foreign key (customer_id) references customers (customer_id);

-- fk for reviews table
alter table order_reviews
add constraint fk_reviews_orders foreign key (order_id) references orders (order_id);


--fk for order_items
alter table order_items
add constraint fk_orderitems_orders foreign key (order_id) references orders (order_id);

alter table order_items
add constraint fk_orderitems_products foreign key (product_id) references products (product_id);

alter table order_items
add constraint fk_orderitems_sellers foreign key (seller_id) references sellers (seller_id);



--cant make primary key because of duplicate values
SELECT geolocation_lat, geolocation_lng, COUNT(*)
FROM geolocation
GROUP BY geolocation_lat, geolocation_lng
HAVING COUNT(*) > 1;
-- 132207 rows affected.



SELECT COUNT(*)
FROM geolocation
--1000163 rows (total)

---SELECT * INTO public.geolocation_copy FROM public.geolocation

---after delete 2 columns lat and long and pk

select distinct * into public.geolocation
from location

----drop table location

select * 
from geolocation
order by geolocation_city
--27912 
--start cleaning data in geolocation

--check data if any zip code have more than 1 city

select geolocation_zip_code_prefix, count(geolocation_city)
from geolocation
group by geolocation_zip_code_prefix
having count(geolocation_city) > 1;

-- put into temp table
select geolocation_zip_code_prefix, count(geolocation_city) as cnt_city
into temp_dup_zipcode
from geolocation
group by geolocation_zip_code_prefix
having count(geolocation_city) > 1;


select *
from temp_dup_zipcode
--8559 

select * into temp_dupcity
from geolocation
where geolocation_zip_code_prefix in (select geolocation_zip_code_prefix from temp_dup_zipcode)
order by 1 ---17456

--- there is 2 values for the same city
--sao paulo vs são paulo

-- we remove são paulo and keep sao paulo
select * 
from temp_dupcity

select distinct (geolocation_city)
from temp_dupcity
order by geolocation_city desc

select count(distinct(geolocation_zip_code_prefix))
from temp_dupcity

select 8559 * 2

select geolocation_city
from temp_dupcity 
where geolocation_city like '%ã%'  ---4481

--ribeirão pires, são bernardo do camp, são desidério

select geolocation_city
from temp_dupcity 
where geolocation_city like '%ã%'

select geolocation_city, replace(geolocation_city, 'ã', 'a')
from geolocation
where geolocation_city like '%ã%'


--test update command on temp_dupcity
update temp_dupcity 
set geolocation_city = replace(geolocation_city, 'ã é ç í á', 'a,e,c,i');

---santa barbara d'oeste, mogi-guacu, mogi guacu, 

select * 
from temp_dupcity

CREATE EXTENSION unaccent;
SELECT unaccent('ã é ç í á');

update temp_dupcity
set geolocation_city = unaccent(geolocation_city);

select geolocation_zip_code_prefix, count(*)
from temp_dupcity
group by geolocation_zip_code_prefix
having count(*) > 2

select geolocation_zip_code_prefix, count(*) as cnt_city into temp_triplecity
from temp_dupcity
group by geolocation_zip_code_prefix
having count(*) > 2  ---293

---find out which city name is mismatched and fix it
select * 
from temp_dupcity 
where geolocation_zip_code_prefix in (select geolocation_zip_code_prefix from temp_triplecity)
order by 2

select *
from public.geolocation_copy 
where geolocation_zip_code_prefix = '02116'

--need to remove record due to user error input


select * 
from temp_triplecity

select *
from temp_dupcity
where geolocation_city = 'santa barbara d''oeste'

--Brazil	Minas Gerais	Vicosa	36570-000



-- order by geolocation_city desc
--in ('santa barbara d''''oeste', 'santa barbara d oeste', 'santa barbara doeste')

-- update record city with this correct name = santa barbara d'oeste
update temp_dupcity
set geolocation_city = 'santa barbara d''oeste'
where geolocation_city in ('santa barbara d oeste', 'santa barbara doeste')

update temp_dupcity
set geolocation_city = 'aparecida d''oeste'
where geolocation_city in ('aparecida d oeste', 'aparecida doeste')

select *
from temp_dupcity
--- geolocation_city = 'vicosa'
where geolocation_city in ('vicosa', 'cachoeira de santa cruz')
where geolocation_zip_code_prefix = '36574'

select * 
from public.sellers
--where customer_city like '%paulo'

--change name of customer_text
ALTER TABLE public.customers
RENAME COLUMN customer_text TO customer_state;

select *
from public.geolocation_copy
--with distinct 738332 rows

select seller_zip_code_prefix, seller_city, seller_state
into geolocation_test
from public.sellers 
union all
select customer_zip_code_prefix, customer_city, customer_state
from public.customers
--102536

select distinct seller_zip_code_prefix as geolocation_zip_code_prefix, seller_city as geolocation_city, seller_state as geolocation_state
into geolocation
from geolocation_test
--15249

select * 
from geolocation_copy
--1000163

select distinct *
from geolocation_copy
--738332

--use unaccent extension to get rid of accent marks
CREATE EXTENSION unaccent;

DROP extension unaccent

select * 
from geolocation_copy
order by geolocation_city asc

select unaccent(geolocation_city)
from public.geolocation_copy_1
where geolocation_city in ('aparecida d oeste', 'aparecida doeste')
order by geolocation_city asc

update public.geolocation_copy_1
set geolocation_city = unaccent(geolocation_city)

update public.geolocation_copy_1
set geolocation_city = 'santa barbara d''oeste'
where geolocation_city in ('santa barbara d oeste', 'santa barbara doeste')

update public.geolocation_copy_1
set geolocation_city = 'aparecida d''oeste'
where geolocation_city in ('aparecida d oeste', 'aparecida doeste')

select geolocation_city
from public.geolocation_copy_1
where geolocation_city like '%do livramento%'
order by geolocation_city asc

--data cleaning comparing these word in the excel filter(anything that contains an apostrophe for geolocation city)
--  doeste, d oeste, d alho, d%26apos%3balho, dalho, d agua, d avila, davila, d ajuda, d  arco, d alianca, dalianca, sant'ana 
-- olho d agua das flores also needs hyphen to be consistent with other data

--use these two commands to update table to make string consistent
update public.geolocation_copy_1
set geolocation_city = replace(geolocation_city, '* cidade', 'cidade')

update public.geolocation_copy_1
set geolocation_city = replace(geolocation_city, '...arraial do cabo', 'arraial do cabo')

update public.geolocation_copy_1
set geolocation_city = replace(geolocation_city, '´teresopolis', 'teresopolis')

update public.geolocation_copy_1
set geolocation_city = replace(geolocation_city, '4º centenario', 'quarto centenario')

update public.geolocation_copy_1
set geolocation_city = replace(geolocation_city, '4o. centenario', 'quarto centenario')


select geolocation_city
from public.geolocation_copy_1
order by 1

select distinct * into geolocation_copy_2
from public.geolocation_copy_1
order by 1
---1000163 - 720461

select geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state, count(*)
from public.geolocation_copy_2
group by geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state
having count(*) > 1

select *
from public.geolocation_copy_2
where geolocation_zip_code_prefix = '01331'

---remove trailing spaces
select * into geolocation_copy_ltrim
from public.geolocation_copy_2
order by 1

select to_char(geolocation_lat)
from public.geolocation_copy_ltrim

ALTER TABLE public.geolocation_copy_ltrim ALTER COLUMN geolocation_lat TYPE varchar;

select LTRIM(geolocation_lat, ' ')
from public.geolocation_copy_ltrim

ALTER TABLE public.geolocation_copy_ltrim ALTER COLUMN geolocation_lng TYPE varchar;

select LTRIM(geolocation_lng, ' ')
from public.geolocation_copy_ltrim

select distinct *
from geolocation_copy_ltrim
order by geolocation_city asc

--add location_id to make it easier for joining
ALTER TABLE public.geolocation_copy_ltrim
ADD COLUMN location_id INTEGER PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY;

select *
from geolocation_copy_ltrim

--i will use ltrim as my final table so I am going to rename it 
ALTER TABLE geolocation_copy_ltrim
RENAME TO geolocation;

select *
from geolocation

select seller_zip_code_prefix, count(*)
from 
group by seller_zip_code_prefix

-- impossible to use seller_zip_code_prefix to join sellers table with geolocation table
-- because seller_zip_code_prefix is not a primary key of the geolocation table
-- plus sellers and customers tables have zip_code_prefix, city, and state
-- so in this case I only have 7 tables to use for the project (I eventually have 8 as I make my own 8th table)

select *
from public.sellers
where seller_zip_code_prefix = '04438';


select *
from geolocation
where geolocation_zip_code_prefix = '04438';
-- compare

--join 3 tables orders, order_items, sellers in order to find the top 5 states with highest and lowest average delivery time
-- time_to_deliver = order_delivered_customer_date - order_purchase_timestamp

alter table orders
add column time_to_deliver interval generated always as (order_delivered_customer_date - order_purchase_timestamp) STORED

alter table orders
drop column time_to_deliver

SELECT to_date()
from orders

select * 
from orders

select (order_delivered_customer_date - order_purchase_timestamp) as time_to_deliver 
from orders

----state time delivery in days
SELECT orders.order_id,sellers.seller_state , EXTRACT(day from order_delivered_customer_date - order_purchase_timestamp) AS time_to_deliver_days
from orders 
inner join order_items
on orders.order_id = order_items.order_id
inner join sellers
on order_items.seller_id = sellers.seller_id

--- report 1: top 5 states with highest and lowest average delivery time 

SELECT state_name, ROUND(AVG(EXTRACT(day from order_delivered_customer_date - order_purchase_timestamp)),2) AS avg_time_to_deliver_days
from orders 
inner join order_items
on orders.order_id = order_items.order_id
inner join sellers
on order_items.seller_id = sellers.seller_id
inner join states_fullname
on sellers.seller_state = states_fullname.state_abb
group by sellers.seller_state, state_name
order by avg_time_to_deliver_days desc nulls last
-- or asc (top 5)

-- I decided to create my own table called states_fullname
-- I used a website https://brazil-help.com/brazilian_states.htm to create my own csv

-- create table called states to find the states full name and capital of that state
create table states_fullname(
	state_abb char(2) primary key,
	state_name varchar(25),
	state_capital varchar(25),
	brazil_region varchar(25)
)

--join state_fullname table to sellers table and customers table
alter table sellers 
add constraint fk_sellers_fullname foreign key (seller_state) references public.states_fullname (state_abb);

alter table customers 
add constraint fk_customers_fullname foreign key (customer_state) references public.states_fullname (state_abb);

--report 8: revenue by payment type
select payment_type, sum(payment_value) as sum_of_payment
from payments
inner join orders
on payments.order_id = orders.order_id
group by payment_type
order by sum_of_payment desc
-- credit card is used the most followed by UPI, voucher, debit 

--report 9: Are certain payment methods more popular in specific regions?
select payment_type, customer_state, state_name, sum(payment_value) as sum_of_payment
from payments
inner join orders
on payments.order_id = orders.order_id
inner join customers
on customers.customer_id = orders.customer_id
inner join states_fullname
on state_abb = customer_state
group by payment_type, customer_state, state_name
order by sum_of_payment desc 
--delete from payments where payment_type = 'not_defined'



--report 10: how many products sold in each state, find the 5 loweset states and see if they have higher payment installments
-- I could not correlate installments with poor states because population makes this biased
-- scrapped this report
select customer_state, state_name, sum(payment_installments) as sum_of_installments, sum(payment_value) as sum_of_payment
from payments
inner join orders
on payments.order_id = orders.order_id
inner join customers
on customers.customer_id = orders.customer_id
inner join states_fullname
on state_abb = customer_state
group by customer_state, state_name
order by sum_of_payment asc 



--report 11: which month has the most profit over the last 2 years?
-- extract month from purchase timestamp
select EXTRACT(month from order_purchase_timestamp)
from orders

--select to_char(EXTRACT(month from order_purchase_timestamp), 'Jan') as month_name
--from orders

--select to_char(to_date(order_purchase_timestamp, 'DD/MM/YYYY'), 'Month')
--from orders

SELECT sum(payment_value) as sum_payments, to_char(order_purchase_timestamp, 'Month') as month
from orders
inner join payments
on payments.order_id = orders.order_id
group by month
--order by number_of_orders desc
--sum(payment_value) as sum_payments

--report 11: Find the month on month no. of orders placed using different payment types.
-- This code had weird spacing for year_month look below for correct code
select payment_type, TO_CHAR(order_purchase_timestamp::date, 'Month YYYY') as year_month, count(order_purchase_timestamp) as num_orders
from payments
inner join orders
on payments.order_id = orders.order_id
---where payments.order_id = '0bbb3f7791a87d0307555e57da3a1ff1'--- check back later  ////////
group by payment_type, year_month
--order by sum_of_payment desc 
--TO_CHAR(TO_DATE(order_purchase_timestamp, 'YYYY-MM'), 'Month YYYY')
--replace('NES 123_4_5', ' ', '')

--to_char(order_purchase_timestamp, 'Month') as month
--TO_CHAR(DATE '2010-07-10', 'Month') AS init_cap

select payment_type
, TO_CHAR(order_purchase_timestamp, 'Mon') || ' ' || EXTRACT(YEAR FROM order_purchase_timestamp) as month_year
, count(order_purchase_timestamp) as num_orders
from payments
inner join orders
on payments.order_id = orders.order_id
group by payment_type, month_year
--- "credit_card"	"Apr 2017"	1846

select count(*)
--select *
from orders
where TO_CHAR(order_purchase_timestamp, 'Mon') = 'Apr' 
and EXTRACT(YEAR FROM order_purchase_timestamp) = '2017'
--and order_id = '0bbb3f7791a87d0307555e57da3a1ff1' ---11 records in payment table due to multiple payment types
--2404

---fix the count
-- one order_id in payments can be paid by multiple payment types such as voucher/debit/credit/UPI
-- CORRECT CODE
select payment_type
, TO_CHAR(order_purchase_timestamp, 'Mon') || ' ' || EXTRACT(YEAR FROM order_purchase_timestamp) as month_year
, count(payments.order_id) as orders_placed_by_payment_type
from payments
inner join orders
on payments.order_id = orders.order_id
group by payment_type, month_year
--where TO_CHAR(order_purchase_timestamp, 'Mon') = 'Apr' 
--and EXTRACT(YEAR FROM order_purchase_timestamp) = '2017'
---2571
1846
27
496
202


--select count(*)
select * 
from payments 
inner join orders
on payments.order_id = orders.order_id 
where TO_CHAR(order_purchase_timestamp, 'Mon') = 'Apr' 
and EXTRACT(YEAR FROM order_purchase_timestamp) = '2017'
and payments.order_id = '136cce7faa42fdb2cefd53fdc79a6098'

select payments.order_id, count(*)
select *
from payments 
inner join orders
on payments.order_id = orders.order_id 
where TO_CHAR(order_purchase_timestamp, 'Mon') = 'Apr' 
and EXTRACT(YEAR FROM order_purchase_timestamp) = '2017'
and payments.order_id = '0bbb3f7791a87d0307555e57da3a1ff1'
--group by payments.order_id
--having count(*) > 1
select *
from payments
where order_id = '0bbb3f7791a87d0307555e57da3a1ff1'






--SELECT EXTRACT(YEAR FROM TIMESTAMP '2023-10-25 12:30:00')






select payment_type,to_char(order_purchase_timestamp, 'Month') as month, count(order_purchase_timestamp) as num_orders 
from payments 
inner join orders
on payments.order_id = orders.order_id
where payment_type = 'credit_card'
group by payment_type, month
order by num_orders

select * from temp_payments

select payment_type, count(num_orders)
from temp_payments
group by payment_type


--find states equal null
select customer_state, state_name, sum(payment_value) as sum_of_payment
from payments
inner join orders
on payments.order_id = orders.order_id
inner join customers
on customers.customer_id = orders.customer_id
inner join states_fullname
on state_abb = customer_state
group by customer_state, state_name
--where customer_state = 


--fix avg time to deliver in days for power bi 
--CORRECT CODE
SELECT state_name, ROUND(AVG(EXTRACT(day from order_delivered_customer_date - order_purchase_timestamp)),2) AS avg_time_to_deliver_days
from orders 
inner join order_items
on orders.order_id = order_items.order_id
inner join sellers
on order_items.seller_id = sellers.seller_id
inner join states_fullname
on sellers.seller_state = states_fullname.state_abb
where orders.order_delivered_customer_date is not null AND orders.order_purchase_timestamp is not null
group by sellers.seller_state, state_name
order by avg_time_to_deliver_days desc nulls last




--report 3: products sold with day,night
--hint case statement

--wrong code
SELECT 
    --EXTRACT(hour FROM order_purchase_timestamp) AS purchase_hour,
    CASE
        ---WHEN EXTRACT(hour FROM order_purchase_timestamp) <= 6 THEN 'Dawn'
        WHEN EXTRACT(hour FROM order_purchase_timestamp) <= 12 THEN 'Morning'
        WHEN EXTRACT(hour FROM order_purchase_timestamp) <= 18 THEN 'Afternoon'
        WHEN EXTRACT(hour FROM order_purchase_timestamp) <= 23 THEN 'Night'
    END AS time_of_day,
    COUNT(order_id) AS order_count
FROM orders
GROUP BY time_of_day
ORDER BY order_count desc


SELECT 
    --EXTRACT(hour FROM order_purchase_timestamp) AS purchase_hour,
    CASE
        WHEN EXTRACT(hour FROM order_purchase_timestamp) <= 6 THEN 'Dawn'
        WHEN (EXTRACT(hour FROM order_purchase_timestamp) > 6 AND EXTRACT(hour FROM order_purchase_timestamp) <= 12) THEN 'Morning'
        WHEN (EXTRACT(hour FROM order_purchase_timestamp) > 12 AND EXTRACT(hour FROM order_purchase_timestamp) <= 18) THEN 'Afternoon'
        WHEN (EXTRACT(hour FROM order_purchase_timestamp) > 18 AND EXTRACT(hour FROM order_purchase_timestamp) <= 23) THEN 'Night'
    END AS time_of_day,
    COUNT(order_id) AS order_count
FROM orders
GROUP BY time_of_day
ORDER BY order_count desc

select *
from orders


-- BETWEEN FUNCTION is dangerous and should not be used like this
-- Better to use greater than or less than symbols
SELECT
--EXTRACT(hour FROM order_purchase_timestamp) AS purchase_hour,
CASE
WHEN EXTRACT(hour FROM order_purchase_timestamp) BETWEEN 0 AND 6 THEN 'Dawn'
WHEN (EXTRACT(hour FROM order_purchase_timestamp) >6 AND EXTRACT(hour FROM order_purchase_timestamp) <= 12) THEN 'Morning'
WHEN EXTRACT(hour FROM order_purchase_timestamp) > 12 AND EXTRACT(hour FROM order_purchase_timestamp) <= 18 THEN 'Afternoon'
WHEN EXTRACT(hour FROM order_purchase_timestamp) > 18 AND EXTRACT(hour FROM order_purchase_timestamp) <= 23 THEN 'Night'
END AS time_of_day,
COUNT(order_id) AS order_count
FROM orders
GROUP BY time_of_day
ORDER BY order_count desc


SELECT 
    CASE
        WHEN EXTRACT(hour FROM order_purchase_timestamp) BETWEEN 0 AND 6 THEN 'Dawn'
        WHEN EXTRACT(hour FROM order_purchase_timestamp) BETWEEN 7 AND 12 THEN 'Morning'
        WHEN EXTRACT(hour FROM order_purchase_timestamp) BETWEEN 13 AND 18 THEN 'Afternoon'
        WHEN EXTRACT(hour FROM order_purchase_timestamp) BETWEEN 19 AND 23 THEN 'Night'
    END AS time_of_day,
    COUNT(order_id) AS order_count
FROM orders
GROUP BY time_of_day
ORDER BY order_count DESC;

-- THIS SHOULD BE THE CORRECT CODE for report 3
select 
CASE
        WHEN EXTRACT(hour FROM order_purchase_timestamp) <= 6 THEN 'Dawn'
        WHEN (EXTRACT(hour FROM order_purchase_timestamp) > 6 AND EXTRACT(hour FROM order_purchase_timestamp) <= 12 ) THEN 'Morning'
		WHEN (EXTRACT(hour FROM order_purchase_timestamp) > 12 AND EXTRACT(hour FROM order_purchase_timestamp) <= 18 ) THEN 'Afternoon'
		WHEN (EXTRACT(hour FROM order_purchase_timestamp) > 18 AND EXTRACT(hour FROM order_purchase_timestamp) <= 23 ) THEN 'Night'
		ELSE 'NA'
    END AS time_of_day,
    COUNT(*) AS order_count
FROM orders
GROUP BY 
		CASE WHEN EXTRACT(hour FROM order_purchase_timestamp) <= 6 THEN 'Dawn'
        WHEN (EXTRACT(hour FROM order_purchase_timestamp) > 6 AND EXTRACT(hour FROM order_purchase_timestamp) <= 12 ) THEN 'Morning'
		WHEN (EXTRACT(hour FROM order_purchase_timestamp) > 12 AND EXTRACT(hour FROM order_purchase_timestamp) <= 18 ) THEN 'Afternoon'
		WHEN (EXTRACT(hour FROM order_purchase_timestamp) > 18 AND EXTRACT(hour FROM order_purchase_timestamp) <= 23 ) THEN 'Night'
		ELSE 'NA'
		END
ORDER BY order_count DESC;


"Afternoon"	38135
"Night"	28331
"Morning"	27733
"Dawn"	5242

--report X: which product category sold at what time of day
SELECT 
    --EXTRACT(hour FROM order_purchase_timestamp) AS purchase_hour,
    CASE
        WHEN EXTRACT(hour FROM order_purchase_timestamp) <= 6 THEN 'Dawn'
        WHEN EXTRACT(hour FROM order_purchase_timestamp) <= 12 THEN 'Morning'
        WHEN EXTRACT(hour FROM order_purchase_timestamp) <= 18 THEN 'Afternoon'
        WHEN EXTRACT(hour FROM order_purchase_timestamp) <= 23 THEN 'Night'
    END AS time_of_day,
    COUNT(orders.order_id) AS order_count,
	product_category_name
FROM orders
inner join order_items
on orders.order_id = order_items.order_id
inner join products
on products.product_id = order_items.product_id
GROUP BY time_of_day, product_category_name
ORDER BY order_count desc

--report X2: does a long avg time to deliver effect purchasing of orders
SELECT 
    CASE
        WHEN (order_delivered_customer_date::date - order_purchase_timestamp::date) <= 3 THEN 'Short'
        WHEN (order_delivered_customer_date::date - order_purchase_timestamp::date) BETWEEN 4 AND 7 THEN 'Medium'
        ELSE 'Long'
    END AS delivery_time_range,
    ROUND(AVG(order_delivered_customer_date::date - order_purchase_timestamp::date),2) AS avg_delivery_days,
    SUM(payment_value) AS total_revenue,
    COUNT(orders.order_id) AS order_count
FROM orders
inner join payments
on payments.order_id = orders.order_id
WHERE order_delivered_customer_date IS NOT NULL
GROUP BY delivery_time_range
ORDER BY delivery_time_range;

-- X2: find correlation for this
SELECT 
    CORR(order_delivered_customer_date::date - order_purchase_timestamp::date, payment_value) AS delivery_time_revenue_corr
FROM orders
inner join payments
on payments.order_id = orders.order_id
WHERE order_delivered_customer_date IS NOT NULL;

-- 0.06719843982048802 corr value
-- X2: positive correlation means that long delivery times DO NOT negatively effect revenue
-- DID NOT USE THIS BUT LEAVING IT HERE 


--report X3: make a chi square for order_count to review score
-- REPORT WAS SCRAPPED I DECIDED TO NOT USE THIS
-- make the sql query that extracts long, medium, short from delivery_time_range
SELECT 
    CASE
        WHEN (order_delivered_customer_date::date - order_purchase_timestamp::date) <= 3 THEN 'Short'
        WHEN (order_delivered_customer_date::date - order_purchase_timestamp::date) BETWEEN 4 AND 7 THEN 'Medium'
        ELSE 'Long'
    END AS delivery_time_range,
	CASE
        WHEN review_score = 1 THEN 'Very Poor'
        WHEN review_score = 2 THEN 'Poor'
		WHEN review_score = 3 THEN 'Average'
        WHEN review_score = 4 THEN 'Good'
		WHEN review_score = 5 THEN 'Excellent'
    END AS review_word	
FROM orders
inner join order_reviews
on orders.order_id = order_reviews.order_id

-- used python chi square test. p-value is 0.0 Therefore delivery time in days does not effect review score at all as they are both 
-- independent of each other
-- redo query cause review score should be numerical
SELECT 
    CASE
        WHEN (order_delivered_customer_date::date - order_purchase_timestamp::date) <= 3 THEN 'Short'
        WHEN (order_delivered_customer_date::date - order_purchase_timestamp::date) BETWEEN 4 AND 7 THEN 'Medium'
        ELSE 'Long'
    END AS delivery_time_range,
 	review_score
FROM orders
inner join order_reviews
on orders.order_id = order_reviews.order_id

-- take out both case statements and requery
SELECT (order_delivered_customer_date::date - order_purchase_timestamp::date) as delivery_time_rang, review_score
FROM orders
inner join order_reviews
on orders.order_id = order_reviews.order_id
-- SCRAPPED 

--report 4: which product category have >=4 star review compared to a product category <4 star review
-- use number of orders instead of payment_value
-- decided to not use this
select product_category_name, count(orders.order_id) as num_orders, review_score
from order_reviews
inner join orders
on order_reviews.order_id = orders.order_id
inner join order_items
on order_items.order_id = orders.order_id
inner join products
on order_items.product_id = products.product_id
group by product_category_name, review_score
order by num_orders desc nulls last



-- report 5: What time of day sells the most product? 
SELECT 
    CASE
        WHEN EXTRACT(hour FROM order_purchase_timestamp) <= 6 THEN 'Dawn'
        WHEN EXTRACT(hour FROM order_purchase_timestamp) <= 12 THEN 'Morning'
        WHEN EXTRACT(hour FROM order_purchase_timestamp) <= 18 THEN 'Afternoon'
        WHEN EXTRACT(hour FROM order_purchase_timestamp) <= 23 THEN 'Night'
    END AS time_of_day
	--product_category_name,
	--customer_state,
	--state_name
FROM orders

-- report 6: does a >= 4 star review product got sold more than <4 star product and null review
-- hint: need to use case statement

--report 7: order date can tell whether buyers buy more during seasonal months?
select to_char(order_purchase_timestamp, 'Month') as month, count(order_id) as num_orders 
from orders
where order_id is not null
group by month
order by num_orders desc

--report x3: which state sells the most product SP makes the most
select customer_state, state_name, sum(payment_value) as sum_of_payment
from payments
inner join orders
on payments.order_id = orders.order_id
inner join customers
on customers.customer_id = orders.customer_id
inner join states_fullname
on state_abb = customer_state
group by customer_state, state_name
order by sum_of_payment desc

-- report x4: since sao paulo is the most popular city which product category and what types of payment in sao paulo is used the most
select customer_state, state_name, product_category_name,  sum(payment_value) as sum_of_payment
from payments
inner join orders
on payments.order_id = orders.order_id
inner join customers
on customers.customer_id = orders.customer_id
inner join states_fullname
on state_abb = customer_state
inner join order_items
on order_items.order_id = orders.order_id
inner join products
on products.product_id = order_items.product_id
group by customer_state, state_name, product_category_name
order by sum_of_payment desc

--report x5: review score with case statement and sorted by product category
SELECT product_category_name,
	CASE
        WHEN review_score = 1 THEN 'Very Poor'
        WHEN review_score = 2 THEN 'Poor'
		WHEN review_score = 3 THEN 'Average'
        WHEN review_score = 4 THEN 'Good'
		WHEN review_score = 5 THEN 'Excellent'
    END AS review_word,
	COUNT(orders.order_id) as order_count	
FROM orders
inner join order_reviews
on orders.order_id = order_reviews.order_id
inner join order_items
on order_items.order_id = orders.order_id
inner join products
on products.product_id = order_items.product_id
where products.product_category_name is not null
group by product_category_name, review_word
order by 1

-- regg look at juptyer notebook: i used average review score vs avg delivery days and made a scatter to see if there is a relationship
SELECT product_category_name,
	ROUND(AVG(order_reviews.review_score),2) as avg_rev_score,
	ROUND(AVG(order_delivered_customer_date::date - order_purchase_timestamp::date),2) AS avg_delivery_days
FROM orders
inner join order_reviews
on orders.order_id = order_reviews.order_id
inner join order_items
on order_items.order_id = orders.order_id
inner join products
on products.product_id = order_items.product_id
where product_category_name is not null
group by product_category_name
--COUNT(orders.order_id) as order_count,

--look at jupyter notebook: do chi square test (between two categorical variables) on payment method and product category 
-- i need to make sql query of payment method and category and convert sql result into a dataframe
-- decided to not use chi square test
select product_category_name, payment_type
from products
inner join order_items
on products.product_id = order_items.product_id
inner join orders
on orders.order_id = order_items.order_id
inner join payments
on payments.order_id = orders.order_id
where product_category_name is not null

-- look at jupyter notebook: do frequency table on frequency of Products Sold
select product_category_name, customers.customer_id
from products
inner join order_items
on products.product_id = order_items.product_id
inner join orders
on orders.order_id = order_items.order_id
inner join customers
on customers.customer_id = orders.customer_id

-- corr look at jupyter notebook: review scores correlation analysis vs. sales volume (# of people bought said product)
select COUNT(products.product_id) as sales_volume, review_score 
from products 
inner join order_items
on products.product_id = order_items.product_id 
inner join orders 
on orders.order_id = order_items.order_id 
inner join order_reviews 
on order_reviews.order_id = orders.order_id
group by review_score

-- report x6: top products average and total revenue 
SELECT 
    products.product_category_name,
    SUM(payment_value) AS total_sales,
    ROUND(AVG(payment_value),2) AS average_sales_per_product,
	COUNT(orders.order_id) as num_of_orders
FROM payments
INNER JOIN orders
ON orders.order_id = payments.order_id
INNER JOIN order_items
ON order_items.order_id = orders.order_id
INNER JOIN products
on products.product_id = order_items.product_id
where products.product_category_name is not null 
GROUP BY 
    products.product_category_name

-- confirming if average function makes sense
SELECT 
    products.product_category_name,
    SUM(payment_value) AS total_sales,
     ROUND(SUM(payment_value)/ COUNT(orders.order_id),2) AS average_sales_per_product,
	COUNT(orders.order_id) as num_of_orders
FROM payments
INNER JOIN orders
ON orders.order_id = payments.order_id
INNER JOIN order_items
ON order_items.order_id = orders.order_id
INNER JOIN products
on products.product_id = order_items.product_id
where products.product_category_name is not null 
GROUP BY 
    products.product_category_name
order by average_sales_per_product desc
--ROUND(AVG(payment_value),2)


-- t-test look at jupyter notebook: how product weight effects delivery times
select (order_delivered_customer_date::date - order_purchase_timestamp::date) as delivery_days,
	product_weight_g
from orders
INNER JOIN order_items
ON order_items.order_id = orders.order_id
INNER JOIN products
on products.product_id = order_items.product_id
