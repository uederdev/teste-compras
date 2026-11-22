create table if not exists products
(
    id          uuid           not null primary key,
    sku         varchar(20)    not null,
    name        varchar(255)   not null,
    description text,
    price       decimal(18, 4) not null,
    active      boolean        not null default true,
    created_at  timestamp      not null default now(),
    updated_at  timestamp      not null default now(),
    constraint uk_sku unique (sku)
);

create table if not exists clients
(
                                       id uuid not null primary key,
                                       name varchar(100) not null,
                                       email varchar(255) not null,
                                       active      boolean        not null default true,
                                       created_at  timestamp      not null default now(),
                                       updated_at  timestamp      not null default now(),
                                       constraint uk_email unique (email)
);

create table if not exists orders
(
                                      id uuid not null primary key,
                                      client_id uuid not null,
                                      nr_order varchar(20) not null,
                                      status varchar(20) not null check ( status in ('PENDING', 'PAID', 'CANCELED') ),
                                      total_order decimal(18, 4) not null check ( total_order >= 0 ),
                                      active      boolean        not null default true,
                                      created_at  timestamp      not null default now(),
                                      updated_at  timestamp      not null default now(),
                                      constraint uk_nr_order unique (nr_order),
                                      constraint fk_client foreign key (client_id) references clients (id)
);

create table if not exists orders_item
(
                                           id uuid not null primary key,
                                           order_id uuid not null,
                                           product_id uuid not null,
                                           quantity numeric(18, 3) not null check ( quantity > 0 ),
                                           price_unit numeric(18, 4) not null check ( price_unit > 0 ),
                                           active      boolean        not null default true,
                                           created_at  timestamp      not null default now(),
                                           updated_at  timestamp      not null default now(),
                                           constraint fk_product foreign key (product_id) references products (id)
);