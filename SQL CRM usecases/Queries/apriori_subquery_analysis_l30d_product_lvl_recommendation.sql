-- this is a logic to come up with l30days recommendation
-- we use the sku_bank and most popular products that got purchased within l30d as the pool of product
-- we will find the category of the product that got purchased within l30d and find the corresponding category that purchased within the same basket (same basket analysis)
-- we will use the same basket analysis category to find the product from the pool
-- made with love by Mamet for Renos peeps
-- enjoy 💖
SELECT
	mainpair.item_a,
    mainpair.total_a,
    mainpair.item_b,
    mainpair.total_b,
    mainpair.pair_count,
    mainpair.total_order_count,
    mainpair.support,
    mainpair.confidence_A_to_B,
    mainpair.confidence_B_to_A,
    mainpair.lift,
    mainpair.rn,
    COALESCE(mainpair.raw_item_1, secondpair.offer_a_copy) AS item_1,
    COALESCE(mainpair.raw_item_2, secondpair.offer_b_copy) AS item_2,
    COALESCE(mainpair.raw_item_3, secondpair.offer_c_copy) AS item_3,
    COALESCE(mainpair.raw_item_4, secondpair.offer_d_copy) AS item_4,
    COALESCE(mainpair.raw_item_5, secondpair.offer_g_copy) AS item_5,
    COALESCE(mainpair.raw_item_6, secondpair.offer_h_copy) AS item_6
from (
    select 
		f2.*,
		MAX(CASE WHEN f6.rn = 1 THEN f6.sku_name END) AS raw_item_1,
    	MAX(CASE WHEN f6.rn = 2 THEN f6.sku_name END) AS raw_item_2,
    	MAX(CASE WHEN f6.rn = 3 THEN f6.sku_name END) AS raw_item_3,
    	MAX(CASE WHEN f6.rn = 4 THEN f6.sku_name END) AS raw_item_4,
    	MAX(CASE WHEN f6.rn = 5 THEN f6.sku_name END) AS raw_item_5,
    	MAX(CASE WHEN f6.rn = 6 THEN f6.sku_name END) AS raw_item_6
	from (
		-- step 2 create dataset that show the rn
		select 
			f1.*,
			row_number() over (partition by f1.item_a order by f1.lift desc) as rn
		from (
			-- step 1 create dataset that show item_a and item_b with lift number as a column
			SELECT 
				a.cat_name AS item_a,
				ta.total_a,
	
				b.cat_name AS item_b,
				tb.total_b,  
		
				COUNT(*) AS pair_count,
				tod.total_order_count,
	
				ROUND(COUNT(*) * 1.0 / tod.total_order_count, 3) AS support,
				ROUND(COUNT(*) * 1.0 / ta.total_a, 3) AS confidence_A_to_B,
				ROUND(COUNT(*) * 1.0 / tb.total_b, 3) AS confidence_B_to_A,
				ROUND((COUNT(*) * 1.0 * tod.total_order_count) / (ta.total_a * tb.total_b), 3) AS lift
	
			FROM mock_renos_db.mock_purchase AS a
			JOIN mock_renos_db.mock_purchase AS b ON a.order_id = b.order_id AND a.cat_name <> b.cat_name
	
			inner JOIN (
				-- total_a: how many times item_a appears
				SELECT cat_name, COUNT(*) AS total_a
				FROM mock_renos_db.mock_purchase as a 
				left join blacklist_seller as bs on bs.seller_id = a.seller_id
				left join suspicious_seller as ss on ss.seller_id = a.seller_id
				left join suspicious_buyer as sb on sb.user_id = a.user_id
				WHERE 1
					and a.order_status not in ('dibatalkan')
					and a.order_date >= date(now()) - interval 30 day
					and bs.seller_id is null
					and ss.seller_id is null
					and sb.user_id is null
				GROUP BY cat_name
				-- end of total a
				) AS ta ON a.cat_name = ta.cat_name
	
			inner JOIN (
				-- total_b: how many times item_b appears
				SELECT cat_name, COUNT(*) AS total_b
				FROM mock_renos_db.mock_purchase as a 
				left join blacklist_seller as bs on bs.seller_id = a.seller_id
				left join suspicious_seller as ss on ss.seller_id = a.seller_id
				left join suspicious_buyer as sb on sb.user_id = a.user_id
				WHERE 1
					and a.order_status not in ('dibatalkan')
					and a.order_date >= date(now()) - interval 30 day
					and bs.seller_id is null
					and ss.seller_id is null
					and sb.user_id is null
				GROUP BY cat_name
				-- end of total_b
				) AS tb ON b.cat_name = tb.cat_name
	
			CROSS JOIN (
				-- total orders
				SELECT COUNT(DISTINCT order_id) AS total_order_count
				FROM mock_renos_db.mock_purchase as a 
				left join blacklist_seller as bs on bs.seller_id = a.seller_id
				left join suspicious_seller as ss on ss.seller_id = a.seller_id
				left join suspicious_buyer as sb on sb.user_id = a.user_id
				WHERE 1
					and a.order_status not in ('dibatalkan')
					and a.order_date >= date(now()) - interval 30 day
					and bs.seller_id is null
					and ss.seller_id is null
					and sb.user_id is null
				-- end of total orders
				) AS tod
			
			left join blacklist_seller as bs on bs.seller_id = a.seller_id
			left join suspicious_seller as ss on ss.seller_id = a.seller_id
			left join suspicious_buyer as sb on sb.user_id = a.user_id
	
			WHERE 1
				and a.order_status not in ('dibatalkan')
				and a.order_date >= date(now()) - interval 30 day 
				and bs.seller_id is null
				and ss.seller_id is null
				and sb.user_id is null
	
			GROUP BY item_a, item_b
			ORDER BY total_a desc, lift DESC
			-- end of step 1
			) as f1
		-- end of step 2
		) as f2

	left join (
    	-- step 6: put rn
		select
			f5.*,
			row_number() over (partition by f5.cat_3 order by f5.total_order desc) as rn
		from (
        	-- step 5: agregate the numbere of order
			select
				f4.sku_name,
				f4.cat_3,
        		f4.date_added,
				sum(f4.total_order) as 'total_order',
        		f4.source
			from (
            	-- step 4: combine all product data into one
				select
					b.sku_name,
					b.cat_3,
            		b.date_added,
					b.total_order as 'total_order',
            		'sku_bank' as source
				from mock_renos_db.sku_bank as b
		
				union all 
	
				select 
					a.sku_name,
					a.cat_name as 'cat_3',
            		'2025-12-30' as 'date_added',
					count(distinct(a.order_id)) as 'total_order',
            		'purchase_data' as source
				FROM mock_renos_db.mock_purchase as a 
				left join blacklist_seller as bs on bs.seller_id = a.seller_id
				left join suspicious_seller as ss on ss.seller_id = a.seller_id
				left join suspicious_buyer as sb on sb.user_id = a.user_id
				WHERE 1
					and a.order_status not in ('dibatalkan')
					and a.order_date >= date(now()) - interval 30 day
					and bs.seller_id is null
					and ss.seller_id is null
					and sb.user_id is null
				GROUP BY a.sku_name, cat_3
				order by total_order desc
            	-- end of step 4
				) as f4 
			group by f4.sku_name, f4.cat_3, f4.date_added
        	order by f4.total_order desc 
        	-- end of step 5
			) as f5
	
			where 1
    		order by f5.total_order desc 
    	-- end of step 6
    	) as f6 on f6.cat_3 = f2.item_b
	where 1
	    and f6.rn < 7
	group by
		f2.item_a
	order by 
		f2.pair_count desc
    ) as mainpair

cross join campaign_db as secondpair

group BY
	mainpair.item_a,
    mainpair.total_a,
    mainpair.item_b,
    mainpair.total_b,
    mainpair.pair_count,
    mainpair.total_order_count,
    mainpair.support,
    mainpair.confidence_A_to_B,
    mainpair.confidence_B_to_A,
    mainpair.lift,
    mainpair.rn
;