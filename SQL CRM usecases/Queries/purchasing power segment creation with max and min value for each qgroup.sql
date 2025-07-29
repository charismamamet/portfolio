-- start step 4: whole table
select 
	z.*,
    z2.min_avg_item_price,
    z2.max_avg_item_price
from (
    -- start of step 2a: add quantile group identification
	select 
		y.*,
    	concat('q', ntile(4) over (order by y.avg_item_price)) as qgroup
	from (
        -- start of step 1a: user purchasing power as dataset to create quantile identification
		select
        	x.user_id,
        	count(distinct(x.order_id)) as total_order,
        	sum(x.sku_qty) as total_item,
        	sum(x.sku_sell_price) as gmv,
        	round((sum(x.sku_sell_price) / count(distinct(x.order_id))), 0) as AOV,
        	round((sum(x.sku_sell_price) / sum(x.sku_qty)), 0) as avg_item_price
    	from mock_renos_db.mock_purchase as x
    	left join mock_renos_db.suspicious_buyer as x1 on x1.user_id = x.user_id
    	left join mock_renos_db.suspicious_seller as x2 on x2.seller_name = x.seller_name
    	where 1
    	and x.user_id in (
    		select
            	xa.user_id
        	from mock_renos_db.mock_purchase as xa
        	where 1
        	and xa.order_date < '2025-07-21'
        	and xa.order_status in ('menunggu pembayaran', 'selesai')
        	)
    	and x.user_id not in (
        	select
            	xb.user_id
        	from mock_renos_db.mock_purchase as xb
        	where 1
        	and xb.order_date >= '2025-07-21'
        	and xb.order_status in ('menunggu pembayaran', 'selesai')
        	)
    	and x1.user_id is null
    	and x2.seller_name is null
    	group by x.user_id
		-- end of step 1a
    	) as y
	-- end of step 2a
	) as z

join (
	-- start step 3: max and min tab for each quantile 
    SELECT 
  		z1.qgroup,
  		MIN(z1.avg_item_price) AS min_avg_item_price,
  		MAX(z1.avg_item_price) AS max_avg_item_price
	FROM (
        -- start step 2b: add quantile group identification to create max and min tab for each quantile
  		SELECT 
    		y.*,
    		CONCAT('q', NTILE(4) OVER (ORDER BY y.avg_item_price)) AS qgroup
  		FROM (
    		-- Start step 1b: user purchasing power as dataset to create max and min tab for each quantile
    		SELECT
      			x.user_id,
      			COUNT(DISTINCT x.order_id) AS total_order,
      			SUM(x.sku_qty) AS total_item,
      			SUM(x.sku_sell_price) AS gmv,
      			ROUND(SUM(x.sku_sell_price) / COUNT(DISTINCT x.order_id), 0) AS AOV,
      			ROUND(SUM(x.sku_sell_price) / SUM(x.sku_qty), 0) AS avg_item_price
    		FROM mock_renos_db.mock_purchase AS x
    		LEFT JOIN mock_renos_db.suspicious_buyer AS x1 ON x1.user_id = x.user_id
    		LEFT JOIN mock_renos_db.suspicious_seller AS x2 ON x2.seller_name = x.seller_name
    		WHERE 1
      		AND x.user_id IN (
        		SELECT xa.user_id
        		FROM mock_renos_db.mock_purchase AS xa
       			WHERE xa.order_date < '2025-07-21'
          		AND xa.order_status IN ('menunggu pembayaran', 'selesai')
      			)
      		AND x.user_id NOT IN (
        		SELECT xb.user_id
        		FROM mock_renos_db.mock_purchase AS xb
        		WHERE xb.order_date >= '2025-07-21'
          		AND xb.order_status IN ('menunggu pembayaran', 'selesai')
      			)
      		AND x1.user_id IS NULL
      		AND x2.seller_name IS NULL
    		GROUP BY x.user_id
			-- end of step 1b
  			) AS y
		-- end step 2b
		) AS z1
	GROUP BY z1.qgroup
	-- end of step 3
    ) as z2 on z2.qgroup=z.qgroup

group by z.user_id, z.total_order, z.total_item, z.gmv, z.aov, z.avg_item_price, z.qgroup
-- end of step 4;