select 
	x.user_id,
    count(x.order_id) as total_order,
    sum(x.sku_qty) as total_sku_purchased,
    sum(x.sku_sell_price) as total_gmv,
    round((sum(x.sku_sell_price)/sum(x.sku_qty)), 0) as avg_sku_price,
    round((sum(x.sku_sell_price) / count(x.order_id)), 0) as aov
from mock_renos_db.mock_purchase as x
left join mock_renos_db.suspicious_seller as xs on xs.seller_name = x.seller_name
left join mock_renos_db.suspicious_buyer as xb on xb.user_id = x.user_id
where 1
and x.user_id in (
    select o.user_id
    from mock_renos_db.mock_purchase as o
    where order_date < '2025-07-21'
    and order_status in ('menunggu pembayaran', 'selesai')
    )
and x.user_id not in (
    select q.user_id
    from mock_renos_db.mock_purchase as q
    where order_date >= '2025-07-21'
    and order_status in ('menunggu pembayaran', 'selesai')
    )
and order_status in ('menunggu pembayaran', 'selesai')
and xs.seller_name is null
and x.user_id not in (
    select distinct(p.user_id)
		from mock_renos_db.mock_purchase as p
		left join mock_renos_db.suspicious_seller as ss on ss.seller_name = p.seller_name
    	left join mock_renos_db.suspicious_buyer as sb on sb.user_id = p.user_id
		where p.user_id in (
    		select r.user_id
    		from mock_renos_db.mock_purchase as r
    		where 1
    		and order_date < '2025-07-21'
    		and order_status in ('menunggu pembayaran', 'selesai')
    		and sku_sell_price / sku_qty <= 500000
    		)
		and p.user_id not in (
    		select user_id
    		from mock_renos_db.mock_purchase
    		where 1
    		and order_date >= '2025-07-21'
    		and order_status in ('menunggu pembayaran', 'selesai')
    		)
		and ss.seller_name is null
    	and sb.user_id is null
    )
and xb.user_id is null
group by x.user_id
order by avg_sku_price desc
;