with exclusion_list as (
select user_id
from mock_renos_db.mock_purchase
where 1
and user_id in (
    SELECT user_id
	FROM mock_renos_db.mock_purchase 
	WHERE 1
	and renos_code in ('RENOSPRJAIRLAND', 'RENOSPRJSIMMONS', 'RENOSPRJIMPORTA', 'RENOSPRJBELMONT', 'RENOSPRJTCL', 'RENOSPRJSHARP', 'RENOSPRJBOSCH', 'RENOSPRJBEKO', 'RENOSPRJHITACHI', 'RENOSPRJSNINJA', 'RENOSPRJGAMER', 'RENOSPRJAGRES', 'RENOSPRJRJWL', 'RENOSPRJNIKO')
	and order_status in ('menunggu pembayaran', 'selesai')
    and cat_name in ('PC Gaming')
    and cat_name not in ('Notebook', 'Laptop Gaming', 'Kulkas', 'Android OS', 'Mesin Cuci')
    )
and user_id not in (
    select user_id
    from mock_renos_db.mock_purchase
    where 1
    and order_date >= '2025-06-30'
    and order_status in ('menunggu pembayaran', 'selesai')
    order by order_date desc
    )
	
union all

select user_id
from mock_renos_db.mock_purchase
where 1
and user_id in (
    SELECT user_id
	FROM mock_renos_db.mock_purchase 
	WHERE 1
	and renos_code in ('RENOSPRJAIRLAND', 'RENOSPRJSIMMONS', 'RENOSPRJIMPORTA', 'RENOSPRJBELMONT', 'RENOSPRJTCL', 'RENOSPRJSHARP', 'RENOSPRJBOSCH', 'RENOSPRJBEKO', 'RENOSPRJHITACHI', 'RENOSPRJSNINJA', 'RENOSPRJGAMER', 'RENOSPRJAGRES', 'RENOSPRJRJWL', 'RENOSPRJNIKO')
	and order_status in ('menunggu pembayaran', 'selesai')
    and cat_name in ('Mesin Cuci')
    and cat_name not in ('Notebook', 'Laptop Gaming', 'Kulkas', 'Android OS', 'PC Gaming')
    )
and user_id not in (
    select user_id
    from mock_renos_db.mock_purchase
    where 1
    and order_date >= '2025-06-30'
    and order_status in ('menunggu pembayaran', 'selesai')
    order by order_date desc
    )
	
union all

select user_id
from mock_renos_db.mock_purchase
where 1
and user_id in (
    SELECT user_id
	FROM mock_renos_db.mock_purchase 
	WHERE 1
	and renos_code in ('RENOSPRJAIRLAND', 'RENOSPRJSIMMONS', 'RENOSPRJIMPORTA', 'RENOSPRJBELMONT', 'RENOSPRJTCL', 'RENOSPRJSHARP', 'RENOSPRJBOSCH', 'RENOSPRJBEKO', 'RENOSPRJHITACHI', 'RENOSPRJSNINJA', 'RENOSPRJGAMER', 'RENOSPRJAGRES', 'RENOSPRJRJWL', 'RENOSPRJNIKO')
	and order_status in ('menunggu pembayaran', 'selesai')
    and cat_name in ('Android OS')
    and cat_name not in ('Notebook', 'Laptop Gaming', 'Kulkas', 'Mesin Cuci', 'PC Gaming')
    )
and user_id not in (
    select user_id
    from mock_renos_db.mock_purchase
    where 1
    and order_date >= '2025-06-30'
    and order_status in ('menunggu pembayaran', 'selesai')
    order by order_date desc
    )

union all

select user_id
from mock_renos_db.mock_purchase
where 1
and user_id in (
    SELECT user_id
	FROM mock_renos_db.mock_purchase 
	WHERE 1
	and renos_code in ('RENOSPRJAIRLAND', 'RENOSPRJSIMMONS', 'RENOSPRJIMPORTA', 'RENOSPRJBELMONT', 'RENOSPRJTCL', 'RENOSPRJSHARP', 'RENOSPRJBOSCH', 'RENOSPRJBEKO', 'RENOSPRJHITACHI', 'RENOSPRJSNINJA', 'RENOSPRJGAMER', 'RENOSPRJAGRES', 'RENOSPRJRJWL', 'RENOSPRJNIKO')
	and order_status in ('menunggu pembayaran', 'selesai')
    and cat_name in ('Kulkas')
    and cat_name not in ('Notebook', 'Laptop Gaming', 'Android OS', 'Mesin Cuci', 'PC Gaming')
    )
and user_id not in (
    select user_id
    from mock_renos_db.mock_purchase
    where 1
    and order_date >= '2025-06-30'
    and order_status in ('menunggu pembayaran', 'selesai')
    order by order_date desc
    )

union all

select user_id
from mock_renos_db.mock_purchase
where 1
and user_id in (
    SELECT user_id
	FROM mock_renos_db.mock_purchase 
	WHERE 1
	and renos_code in ('RENOSPRJAIRLAND', 'RENOSPRJSIMMONS', 'RENOSPRJIMPORTA', 'RENOSPRJBELMONT', 'RENOSPRJTCL', 'RENOSPRJSHARP', 'RENOSPRJBOSCH', 'RENOSPRJBEKO', 'RENOSPRJHITACHI', 'RENOSPRJSNINJA', 'RENOSPRJGAMER', 'RENOSPRJAGRES', 'RENOSPRJRJWL', 'RENOSPRJNIKO')
	and order_status in ('menunggu pembayaran', 'selesai')
    and cat_name in ('Laptop Gaming', 'Notebook')
    and cat_name not in ('Kulkas', 'Android OS', 'Mesin Cuci', 'PC Gaming')
    )
and user_id not in (
    select user_id
    from mock_renos_db.mock_purchase
    where 1
    and order_date >= '2025-06-30'
    and order_status in ('menunggu pembayaran', 'selesai')
    order by order_date desc
    )
)

select user_id
from mock_renos_db.mock_purchase
where 1
and user_id in (
    SELECT user_id
	FROM mock_renos_db.mock_purchase 
	WHERE 1
	and renos_code in ('RENOSPRJAIRLAND', 'RENOSPRJSIMMONS', 'RENOSPRJIMPORTA', 'RENOSPRJBELMONT', 'RENOSPRJTCL', 'RENOSPRJSHARP', 'RENOSPRJBOSCH', 'RENOSPRJBEKO', 'RENOSPRJHITACHI', 'RENOSPRJSNINJA', 'RENOSPRJGAMER', 'RENOSPRJAGRES', 'RENOSPRJRJWL', 'RENOSPRJNIKO')
	and order_status in ('menunggu pembayaran', 'selesai')
    and cat_name not in (
	select user_id from exclusion_list
	)
    )
and user_id not in (
    select user_id
    from mock_renos_db.mock_purchase
    where 1
    and order_date >= '2025-06-30'
    and order_status in ('menunggu pembayaran', 'selesai')
    order by order_date desc
    )