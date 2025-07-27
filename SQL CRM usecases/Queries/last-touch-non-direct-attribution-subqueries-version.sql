SELECT 
  pd.purchase_id,
  pd.userid,
  pd.purchase_date,
  lvc.campaignid
FROM (
		SELECT 
			pl.purchase_id,
			pl.userid,
			pl.date AS purchase_date
		FROM purchase_log pl
) as pd
LEFT JOIN (
		SELECT
			purchase_id, 
			campaignid
		FROM (
			SELECT 
				cl.userid,
				pd.purchase_id,
				pd.purchase_date,
				cl.campaignid,
				cl.date AS click_date,
				ROW_NUMBER() OVER (PARTITION BY pd.purchase_id ORDER BY cl.date DESC) AS rn
			FROM (
					SELECT 
						pl.purchase_id,
						pl.userid,
						pl.date AS purchase_date
					FROM purchase_log pl
			) as pd
			JOIN click_log cl ON cl.userid = pd.userid
			WHERE cl.date <= pd.purchase_date
			AND DATEDIFF(pd.purchase_date, cl.date) <= 30
		) ranked_clicks
		WHERE rn = 1
) lvc ON pd.purchase_id = lvc.purchase_id;