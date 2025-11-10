-- STEP 6: Create overall table with CRM-attributed and organic purchases
SELECT 
  pl.id AS purchase_id,
  pl.external_user_id AS user_id,
  FROM_UNIXTIME(pl.time) AS purchase_date,
  
  CASE 
    WHEN ltnd.campaign_id IS NULL OR ltnd.campaign_id = '' THEN 'organic'
    ELSE ltnd.campaign_id
  END AS campaign_id,
  
  CASE 
    WHEN ltnd.medium IS NULL OR ltnd.medium = '' THEN 'direct'
    ELSE ltnd.medium
  END AS campaign_medium,
  
  ltnd.view_date,
  ltnd.date_diff

FROM USERS_BEHAVIORS_PURCHASE_SHARED AS pl -- step 5 is this line if we need to create our own purchase_id but we don't have to
LEFT JOIN (
  -- STEP 4: TRUE LTND Attribution Logic
  SELECT 
    purchase_id,
    external_user_id,
    campaign_id,
    medium,
    view_date,
    date_diff
  FROM (
    -- STEP 3: add row number as rn
    SELECT 
      joined.purchase_id,
      joined.external_user_id,
      joined.campaign_id,
      joined.medium,
      joined.view_date,
      joined.date_diff,
      ROW_NUMBER() OVER (
        PARTITION BY joined.purchase_id 
        ORDER BY joined.view_date DESC, joined.campaign_id ASC
      ) AS rn
    FROM (
      -- STEP 2: Only include views BEFORE purchase, within 30 days
      SELECT
        pl.id AS purchase_id,
        pl.external_user_id,
        FROM_UNIXTIME(pl.time) AS purchase_date,
        vl.campaign_id,
        vl.view_date,
        vl.medium,
        DATEDIFF(FROM_UNIXTIME(pl.time), vl.view_date) AS date_diff
      FROM USERS_BEHAVIORS_PURCHASE_SHARED AS pl
      INNER JOIN (
        -- STEP 1: Combine all message impressions
        SELECT campaign_id, external_user_id, FROM_UNIXTIME(time) AS view_date, 'banner'   AS medium FROM USERS_MESSAGES_BANNER_IMPRESSION_SHARED
        UNION ALL
        SELECT campaign_id, external_user_id, FROM_UNIXTIME(time) AS view_date, 'pop-up'   AS medium FROM USERS_MESSAGES_INAPPMESSAGE_IMPRESSION_SHARED
        UNION ALL
        SELECT campaign_id, external_user_id, FROM_UNIXTIME(time) AS view_date, 'push'     AS medium FROM USERS_MESSAGES_PUSHNOTIFICATION_SEND_SHARED
        UNION ALL
        SELECT campaign_id, external_user_id, FROM_UNIXTIME(time) AS view_date, 'email'    AS medium FROM USERS_MESSAGES_EMAIL_DELIVERY_SHARED
        UNION ALL
        SELECT campaign_id, external_user_id, FROM_UNIXTIME(time) AS view_date, 'whatsapp' AS medium FROM USERS_MESSAGES_WHATSAPP_DELIVERY_SHARED
		-- end of -- STEP 1	
	  ) AS vl 
        ON vl.external_user_id = pl.external_user_id
      WHERE 
        vl.view_date <= FROM_UNIXTIME(pl.time)                   -- view must be BEFORE purchase
        AND DATEDIFF(FROM_UNIXTIME(pl.time), vl.view_date) <= 30 -- within 30 days
        AND DATEDIFF(FROM_UNIXTIME(pl.time), vl.view_date) >= 0  -- non-negative diff
	  -- end of STEP 2	
	) AS joined
    -- end of STEP 3
  ) AS ranked
  WHERE rn = 1  -- ✅ pick latest view per purchase
  -- end of STEP 4
) AS ltnd 
  ON ltnd.purchase_id = pl.id
ORDER BY purchase_date DESC;
