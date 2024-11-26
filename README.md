# sql-db

## ПРОСТЫЕ

### 1. Найти пользователей, которые не сделали ни одного заказа

```select * from users 
left join orders on users.user_id = orders.user_id
where orders.user_id is null
```

### 2. Рассчитать средний рейтинг продуктов в каждой категории

```select category.category_id, category.name, avg(product.rating) as average_rating from category
join product_has_category on category.category_id = product_has_category.category_id
join product on product_has_category.product_id = product.product_id
group by category.category_id
order by category.category_id
```

### 3. Вычисление времени с момента последнего заказа пользователя

```select users.user_id, now()-max(to_timestamp(orders.date::text || ' ' || orders.time::text, 'YYYY-MM-DD HH24:MI:SS')) as time_since_last_order
from users left join orders on users.user_id = orders.user_id
group by users.user_id
order by users.user_id
```
