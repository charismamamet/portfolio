SELECT 
 		x.sku_name,
        x.seller_name,
		x.sku_price,
		CONCAT(
  			'www.renos.id/p/',
  			LOWER(
    			REGEXP_REPLACE(
      				REPLACE(REGEXP_REPLACE(x.seller_name, '[^a-zA-Z0-9 ]', ''), ' ', '-'),
          			'-+', '-'
    				)
  					),
  				'/',
  			LOWER(
    			REGEXP_REPLACE(
      				REPLACE(REGEXP_REPLACE(x.sku_name, '[^a-zA-Z0-9 ]', ''), ' ', '-'),
      				'-+', '-'
    				)
  				)
			) AS link,
	sum(x.sku_qty) as total_item_sold,
    count(distinct(x.order_id)) as total_trx
FROM mock_renos_db.mock_purchase AS x

    -- Cek suspicious seller list
    LEFT JOIN mock_renos_db.suspicious_seller AS xs ON xs.seller_name = x.seller_name

    -- Cek suspicious buyer list
    LEFT JOIN mock_renos_db.suspicious_buyer AS xb ON xb.user_id = x.user_id
      
    -- cek blacklist seller
    left join mock_renos_db.blacklist_seller as xc on xc.seller_id = x.seller_id

    WHERE 1
	    AND x.order_status NOT IN ('menunggu pembayaran', 'dibatalkan')
    	AND xs.seller_name IS NULL
    	AND xb.user_id is null
      	and xc.seller_id is null
      	and x.order_date >= date(now()) - interval 30 day
        and x.sku_price < (
            select 
				avg(a.sku_sell_price / a.sku_qty)
			from mock_renos_db.mock_purchase as a
			left join mock_renos_db.suspicious_seller as b ON b.seller_id = a.seller_id
			left join mock_renos_db.suspicious_buyer as c on c.user_id = a.user_id
			left join mock_renos_db.blacklist_seller as d on d.seller_id = a.seller_id
			where 1
				and a.order_date >= date(now()) - interval 30 day
    			and a.order_status not in ('dibatalkan','menunggu pembayaran')
    			and b.seller_id is null
    			and c.user_id is null
    			and d.seller_id is null
            )
        and x.seller_name not like '%tes%'
        and x.sku_name not like '%event%'
group by
	x.sku_name,
    x.seller_name,
	x.sku_price,
    link
order by total_trx desc, total_item_sold desc  
