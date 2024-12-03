CREATE TABLE IF NOT EXISTS users (
    user_id serial PRIMARY KEY,
    phone varchar(20) NOT NULL UNIQUE,
    mail varchar(256) NOT NULL UNIQUE,
    login varchar(20) NOT NULL UNIQUE,
    pass varchar(50) NOT NULL,
    address text NOT NULL,
    balance decimal DEFAULT 0 NOT NULL CHECK (balance >= 0)
);

CREATE TABLE IF NOT EXISTS category (
    category_id serial PRIMARY KEY,
    name varchar(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS shop (
    shop_id serial PRIMARY KEY,
    min_price integer NOT NULL CHECK (min_price >= 0),
    work_time varchar(11) NOT NULL, 
    delivery_time varchar(15) NOT NULL 
);

CREATE TABLE IF NOT EXISTS product (
    product_id serial PRIMARY KEY,
    name varchar(200) NOT NULL,
    photo varchar(255),
    composition text,
    weight decimal NOT NULL CHECK (weight > 0),
    rating decimal DEFAULT 0 CHECK (rating BETWEEN 0 AND 5),
    price decimal NOT NULL CHECK (price >= 0),
    nut_value text
);

CREATE TABLE IF NOT EXISTS payment_method (
    pay_method_id serial PRIMARY KEY,
    user_id integer REFERENCES users(user_id) ON DELETE CASCADE,
    cvv char(3) NOT NULL CHECK (length(cvv) = 3),  
    name varchar(100) NOT NULL,
    bank_name varchar(100) NOT NULL,
    card_num varchar(16) NOT NULL,
    exp_date date NOT NULL
);

CREATE TABLE IF NOT EXISTS favourites (
    favourites_id serial PRIMARY KEY,
    user_id integer REFERENCES users(user_id) ON DELETE CASCADE,
    product_id integer REFERENCES product(product_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS orders (
    order_id serial PRIMARY KEY,
    user_id integer REFERENCES users(user_id) ON DELETE CASCADE,
    pay_method_id integer REFERENCES payment_method(pay_method_id) ON DELETE CASCADE,
    date date NOT NULL,
    time time NOT NULL,
    total_price decimal NOT NULL,
    discount_applied boolean NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS cart (
    cart_id serial PRIMARY KEY,
    user_id integer REFERENCES users(user_id) ON DELETE CASCADE,
    price decimal NOT NULL
);

CREATE TABLE IF NOT EXISTS review (
    review_id serial PRIMARY KEY,
    user_id integer REFERENCES users(user_id) ON DELETE CASCADE,
    shop_id integer REFERENCES shop(shop_id) ON DELETE CASCADE,
    product_id integer REFERENCES product(product_id) ON DELETE CASCADE,
    text text NOT NULL,
    date date NOT NULL,
    time time NOT NULL,
    grade smallint CHECK (grade >= 1 AND grade <= 5) NOT NULL
);

CREATE TABLE IF NOT EXISTS discount (
    discount_id serial PRIMARY KEY,
    user_id integer REFERENCES users(user_id) ON DELETE CASCADE,
    discount_percentage decimal CHECK (discount_percentage > 0 AND discount_percentage <= 100),
    exp_time timestamp NOT NULL
);

CREATE TABLE IF NOT EXISTS coupon (
    coupon_id serial PRIMARY KEY,
    user_id integer REFERENCES users(user_id) ON DELETE CASCADE,
    category_id integer REFERENCES category(category_id) ON DELETE CASCADE,
    shop_id integer REFERENCES shop(shop_id) ON DELETE CASCADE,
    product_id integer REFERENCES product(product_id) ON DELETE CASCADE,
    discount_amount decimal NOT NULL
);

CREATE TABLE IF NOT EXISTS product_has_category (
    product_category_id serial PRIMARY KEY,
    product_id int REFERENCES product(product_id) ON DELETE CASCADE,
    category_id int REFERENCES category(category_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS product_in_shops (
    shop_product_id serial PRIMARY KEY,
    product_id int REFERENCES product(product_id) ON DELETE CASCADE,
    shop_id int REFERENCES shop(shop_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS order_contains_product (
    order_product_id serial PRIMARY KEY,
    order_id int REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id int REFERENCES product(product_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS cart_contains_product (
    cart_product_id serial PRIMARY KEY,
    cart_id int REFERENCES cart(cart_id) ON DELETE CASCADE,
    product_id int REFERENCES product(product_id) ON DELETE CASCADE
);
