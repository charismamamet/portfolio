-- step 3 create pivot that is ready to be uploaded to prod catalog
select 
	f2.pair_a as initial_cat,
    f2.total_a as initial_orders,
    max(case when f2.rn = 1 then f2.pair_b else null end) as pair_1,
    max(case when f2.rn = 1 then f2.lift else null end) as lift_1,
    max(case when f2.rn = 2 then f2.pair_b else null end) as pair_2,
    max(case when f2.rn = 2 then f2.lift else null end) as lift_2,
    max(case when f2.rn = 3 then f2.pair_b else null end) as pair_3,
    max(case when f2.rn = 3 then f2.lift else null end) as lift_3
from (
    -- step 2 create dataset that show the rn
    select 
		f1.*,
    	row_number() over (partition by f1.pair_a order by f1.lift desc) as rn
	from (
    	-- step 1 create dataset that show pair_a and pair_b with lift number as a column
    	SELECT 
			a.cat_name AS pair_a,
			ta.total_a,

			b.cat_name AS pair_b,
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
            -- total_a: how many times pair_a appears
  			SELECT cat_name, COUNT(*) AS total_a
  			FROM mock_renos_db.mock_purchase
  			WHERE 1
        	and order_status IN ('menunggu pembayaran', 'selesai')
    		AND order_date BETWEEN '2025-07-01' AND '2025-07-23'
  			GROUP BY cat_name
		) AS ta ON a.cat_name = ta.cat_name

		inner JOIN (
            -- total_b: how many times pair_b appears
  			SELECT cat_name, COUNT(*) AS total_b
  			FROM mock_renos_db.mock_purchase
  			WHERE 1
        	and order_status IN ('menunggu pembayaran', 'selesai')
    		AND order_date BETWEEN '2025-07-01' AND '2025-07-23'
  			GROUP BY cat_name
		) AS tb ON b.cat_name = tb.cat_name

		CROSS JOIN (
            -- total orders
  			SELECT COUNT(DISTINCT order_id) AS total_order_count
  			FROM mock_renos_db.mock_purchase
  			WHERE 1
        	and order_status IN ('menunggu pembayaran', 'selesai')
    		AND order_date BETWEEN '2025-07-01' AND '2025-07-23'
		) AS tod

		WHERE 1
    	and a.order_status IN ('menunggu pembayaran', 'selesai')
  		AND a.order_date BETWEEN '2025-07-01' AND '2025-07-23'

		GROUP BY pair_a, pair_b
		ORDER BY total_a desc, lift DESC
	) as f1
) as f2
group by initial_cat
order by initial_orders desc
;