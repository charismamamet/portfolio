WITH purchase_data AS (
  SELECT 
    pl.purchase_id,
    pl.userid,
    pl.date AS purchase_date
  FROM purchase_log pl
),
clicks_before_purchase AS (
  SELECT
    pd.purchase_id,
    pd.userid,
    pd.purchase_date,
    cl.campaignid,
    cl.date AS click_date,
    DATEDIFF(pd.purchase_date, cl.date) AS diff_days
  FROM purchase_data pd
  JOIN click_log cl ON cl.userid = pd.userid
  WHERE cl.date <= pd.purchase_date
    AND DATEDIFF(pd.purchase_date, cl.date) <= 30
),
latest_valid_click AS (
  SELECT 
    purchase_id,
    campaignid
  FROM (
    SELECT 
      *,
      ROW_NUMBER() OVER (PARTITION BY purchase_id ORDER BY click_date DESC) AS rn
    FROM clicks_before_purchase
  ) ranked_clicks
  WHERE rn = 1
)

SELECT 
  pd.purchase_id,
  pd.userid,
  pd.purchase_date,
  lvc.campaignid
FROM purchase_data pd
LEFT JOIN latest_valid_click lvc ON pd.purchase_id = lvc.purchase_id;
