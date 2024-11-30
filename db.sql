--ПРОСТЫЕ

--1. Найти пользователей, которые не сделали ни одного заказа

select * from users 
left join orders on users.user_id = orders.user_id
where orders.user_id is null

--2. Рассчитать средний рейтинг продуктов в каждой категории

select category.category_id, category.name, avg(product.rating) as average_rating from category
join product_has_category on category.category_id = product_has_category.category_id
join product on product_has_category.product_id = product.product_id
group by category.category_id, category.name
order by category.category_id


--3. Вычисление времени с момента последнего заказа пользователя

select users.user_id, now()-max(to_timestamp(orders.date::text || ' ' || orders.time::text, 'YYYY-MM-DD HH24:MI:SS')) as time_since_last_order
from users left join orders on users.user_id = orders.user_id
group by users.user_id
order by users.user_id


--4. Заказы, превышающих среднюю сумму заказов пользователя

with user_average_orders as (
  select user_id, avg(total_price) as average_order_amount from orders
  group by user_id
)
select orders.order_id, orders.user_id, orders.total_price from orders
join user_average_orders on orders.user_id = user_average_orders.user_id
where orders.total_price > user_average_orders.average_order_amount


--5. Найти топ 10 продуктов по количеству заказов

select product.product_id, count(ocp.order_id) as times_ordered from product
join order_contains_product ocp on product.product_id = ocp.product_id
group by product.product_id
order by times_ordered desc
limit 10;


--6. Найти пользователей с наибольшими общими расходами на заказы

select users.user_id, sum(orders.total_price) as total_spent from users
join orders on users.user_id = orders.user_id
group by users.user_id
order by total_spent desc
limit 10;



-----------------------------------------------------------------------------------------------------------------------------------------------------

--СРЕДНИЕ

--1. Определить пользователей, которые оставили отзывы на все продукты, которые они заказывали

with ordered_products as (
    select orders.user_id, count(distinct ocp.product_id) as num_ordered_products
    from orders
    join order_contains_product ocp on orders.order_id = ocp.order_id
    group by orders.user_id
),
reviewed_products as (
    select user_id, count(distinct product_id) as num_reviewed_products
    from review
    group by user_id
),
users_with_full_reviews as (
    select op.user_id
    from ordered_products op
    join reviewed_products rp on op.user_id = rp.user_id
    where op.num_ordered_products = rp.num_reviewed_products
)
select uwfr.user_id
from users_with_full_reviews uwfr
where not exists (
    select 1
    from (
        select distinct ocp.product_id
        from orders
        join order_contains_product ocp on orders.order_id = ocp.order_id
        where orders.user_id = uwfr.user_id
    ) ordered_p
    left join (
        select distinct product_id
        from review
        where user_id = uwfr.user_id
    ) reviewed_p on ordered_p.product_id = reviewed_p.product_id
    where reviewed_p.product_id is null
);


--2. Ранжировать пользователей по общим расходам, включая совпадения

with user_total_spending as (
    select users.user_id, sum(orders.total_price) as total_spent
    from users
    join orders on users.user_id = orders.user_id
    group by users.user_id
)
select user_id, total_spent,
    dense_rank() over (
        order by total_spent desc
    ) as spending_rank
from user_total_spending
order by spending_rank


--3. Для каждого продукта вычислить разницу между его рейтингом и средним рейтингом его категории

with category_average_ratings as (
    select category.category_id, avg(product.rating) as category_avg_rating
    from category 
    join product_has_category phc on category.category_id = phc.category_id
    join product on phc.product_id = product.product_id
    group by category.category_id
),
product_category_ratings as (
    select product.product_id, product.rating as product_rating,
          category.category_id, car.category_avg_rating
    from product
    join product_has_category phc on product.product_id = phc.product_id
    join category ON phc.category_id = category.category_id
    join category_average_ratings car on category.category_id = car.category_id
)

select category_id, product_id, product_rating,
          round(product_rating - category_avg_rating, 2) as rating_difference
from product_category_ratings
order by category_id, product_id
  

--4. Найти среднее количество товаров в заказе и определить заказы, в которых количество товаров выше среднего

with order_product_counts as (
  select orders.order_id, count(order_contains_product.product_id) as product_count
  from orders join order_contains_product on orders.order_id = order_contains_product.order_id
  group by orders.order_id
),
average_product_count as (
  select avg(product_count) as avg_product_count
  from order_product_counts
)
select order_product_counts.order_id, order_product_counts.product_count
from order_product_counts, average_product_count
where order_product_counts.product_count  > average_product_count.avg_product_count


--5. Определить пользователей, у которых текущий заказ самый большой по сумме
	
-- first version
with user_orders as (
  select user_id, order_id, total_price, to_timestamp(date::text || ' ' || time::text, 'YYYY-MM-DD HH24:MI:SS') as order_datetime
  from orders
),
max_total_per_user as (
  select user_id, max(total_price) as max_total_price from user_orders
  group by user_id
),
latest_order_per_user as (
  select distinct on (user_id) user_id, order_id, total_price
  from user_orders
  order by user_id, order_datetime desc
)
select latest_order_per_user.user_id, latest_order_per_user.order_id as latest_order_id, latest_order_per_user.total_price as latest_order_total
from latest_order_per_user
join max_total_per_user on latest_order_per_user.user_id = max_total_per_user.user_id
where latest_order_per_user.total_price = max_total_per_user.max_total_price

-- second version
with ranked_orders as (
    select user_id, order_id, total_price,
           rank() over (partition by user_id order by to_timestamp(date::text || ' ' || time::text, 'YYYY-MM-DD HH24:MI:SS') desc) as rn,
           max(total_price) over (partition by user_id) as max_total_price
    from orders
)
select user_id, order_id as latest_order_id
from ranked_orders
where rn = 1 and total_price = max_total_price;
	
--------------------------------------------------------------------------------------------------------------------------------------

--СЛОЖНЫЕ

--1. Количество заказов и среднее время между заказами

with user_orders as (
    select user_id, TO_TIMESTAMP(date::text || ' ' || time::text, 'YYYY-MM-DD HH24:MI:SS') as order_datetime
    from orders
),
user_order_diffs as (
    select user_id, order_datetime, lag(order_datetime) over (partition by user_id order by order_datetime) as prev_order_datetime
    from user_orders
),
user_avg_time_between_orders as (
    select user_id, count(*) as num_orders,
           avg(extract(day from (order_datetime - prev_order_datetime))) as avg_time_between_orders_days
    from user_order_diffs
    where prev_order_datetime is not null
    group by user_id
)
select user_id, num_orders, avg_time_between_orders_days
from user_avg_time_between_orders;


--2. Определить пользователей, которые чаще всего используют определенный платежный метод, и рассчитать процент использования этого метода от общего числа их заказов.

with user_payment_method_counts as (
    select orders.user_id, orders.pay_method_id, count(*) as method_order_count
    from orders
    group by orders.user_id, orders.pay_method_id
),
user_total_orders as (
    select user_id, count(*) as total_orders
    from orders
    group by user_id
),
user_most_used_method as (
    select u.user_id, u.pay_method_id, u.method_order_count, uto.total_orders,
        round((u.method_order_count::decimal / uto.total_orders) * 100, 2) as percentage_usage,
        row_number() over (
            partition by u.user_id
            order by u.method_order_count desc, u.pay_method_id
        ) as rn
    from user_payment_method_counts u
    join user_total_orders uto on u.user_id = uto.user_id
)
select * from user_most_used_method
where rn = 1
order by user_id


--3. Определить заказы, в которых пользователь потратил больше, чем в предыдущем заказе

with user_orders as (
    select orders.user_id, orders.order_id, orders.total_price,
        TO_TIMESTAMP(orders.date::text || ' ' || orders.time::text, 'YYYY-MM-DD HH24:MI:SS') as order_datetime,
        lag(orders.total_price) over (
            partition by orders.user_id
            order by orders.date, orders.time
        ) as previous_total_price
    from orders
)

select user_id, order_id, total_price, previous_total_price
from user_orders
where previous_total_price is not null and total_price > previous_total_price
order by user_id, order_datetime


--4. Найти пользователей, средние расходы которых превышают средние расходы других пользователей

with user_average_spending as (
    select users.user_id, avg(orders.total_price) as user_avg_spending
    from users join orders on users.user_id = orders.user_id
    group by users.user_id
)
select user_id, user_avg_spending, overall_avg_spending
from (
    select user_id, user_avg_spending, avg(user_avg_spending) over () as overall_avg_spending
    from user_average_spending
) 
where user_avg_spending > overall_avg_spending
order by user_id


--5. Найти все продукты, на которые у пользователя есть купоны, и которые он еще не покупал 

with user_coupons as (
    select coupon.user_id, coupon.product_id, product.name
    from coupon join product on coupon.product_id = product.product_id
),
user_purchases as (
    select orders.user_id, ocp.product_id, 
			count(orders.order_id) over (partition by orders.user_id, ocp.product_id) as purchase_count
    from orders join order_contains_product ocp on orders.order_id = ocp.order_id
)
select uc.user_id, uc.product_id, uc.name
from user_coupons uc
left join user_purchases up on uc.user_id = up.user_id and uc.product_id = up.product_id
where coalesce(up.purchase_count) is null
