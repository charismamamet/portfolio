-- how to use: put this code into braze's snowflake sql editor. Then, click `Run`
-- what data will be issued after we run this? Answer: It will be a list of purchase and how do that purchase happen, whether it's organic or via crm campaign 
-- this code is made with the Last Touch Non Direct with 30 day window attribution model from view to purchase, like what Braze defaultly attributing the purchase
-- made by Mamet for the Renos gang
-- with love 💖

WITH 
-- combine the views into one dataset
view_log AS (

SELECT
	ban.campaign_id,
	ban.external_user_id,
	CAST(TO_TIMESTAMP(ban.time) AS DATE) AS view_date,
	'banner' AS medium
FROM USERS_MESSAGES_BANNER_IMPRESSION_SHARED AS ban

UNION ALL

SELECT
	iam.campaign_id,
	iam.external_user_id,
	CAST(TO_TIMESTAMP(iam.time) AS DATE) AS view_date,
	'pop-up' AS medium
FROM USERS_MESSAGES_INAPPMESSAGE_IMPRESSION_SHARED AS iam

UNION ALL

SELECT
	pn.campaign_id,
	pn.external_user_id,
	CAST(TO_TIMESTAMP(pn.time) AS DATE) AS view_date,
	'push' AS medium
FROM USERS_MESSAGES_PUSHNOTIFICATION_SEND_SHARED AS pn

UNION ALL

SELECT
	em.campaign_id,
	em.external_user_id,
	CAST(TO_TIMESTAMP(em.time) AS DATE) AS view_date,
	'email' AS medium
FROM USERS_MESSAGES_EMAIL_DELIVERY_SHARED AS em

UNION ALL

SELECT
	wa.campaign_id,
	wa.external_user_id,
	CAST(TO_TIMESTAMP(wa.time) AS DATE) AS view_date,
	'whatsapp' AS medium
FROM USERS_MESSAGES_WHATSAPP_DELIVERY_SHARED AS wa

UNION ALL

SELECT
	cc.campaign_id,
	cc.external_user_id,
	CAST(TO_TIMESTAMP(cc.time) AS DATE) AS view_date,
	'content_card' AS medium
FROM USERS_MESSAGES_CONTENTCARD_IMPRESSION_SHARED AS cc

-- UNION ALL

-- SELECT
 	-- nfc.campaign_id,
    -- nfc.external_user_id,
    -- CAST(TO_TIMESTAMP(nfc.time) AS DATE) AS view_date,
    -- 'news_feed_card' AS medium
-- FROM USERS_MESSAGES_NEWSFEEDCARD_IMPRESSION_SHARED AS nfc

-- UNION ALL

-- SELECT
    -- sms.campaign_id,
    -- sms.external_user_id,
    -- CAST(TO_TIMESTAMP(sms.time) AS DATE) AS view_date,
    -- 'sms' AS medium
-- FROM USERS_MESSAGES_SMS_DELIVERY_SHARED AS sms

),

-- creating dataset that has dummy column that work as a unique identifier per user id and sort it by time
purchase_log AS (
  SELECT
	pl.id AS purchase_id,
	pl.external_user_id,
	pl.price,
	CAST(TO_TIMESTAMP(pl.time) AS DATE) AS purchase_date
  FROM USERS_BEHAVIORS_PURCHASE_SHARED AS pl
),

-- creating purchase_log dataset with dummy column that work as unique purchase_id
-- purchase_log AS (
--  SELECT 
--    concat(rpl.external_user_id, '_', rpl.purchase_row) as purchase_id,
--    rpl.external_user_id,
--    rpl.purchase_date AS purchase_date
--  FROM raw_purchase_log as rpl
--),

-- combine purchase_log and view_log datasets but only get views that has purchase within +30d after views
views_before_purchase AS (
  SELECT
    pl.purchase_id,
    pl.external_user_id,
    pl.purchase_date,
	pl.price,
    vl.campaign_id,
	vl.medium,
    vl.view_date AS view_date,
    DATEDIFF('day', vl.view_date, pl.purchase_date) AS diff_days  --  no ABS() to prevent future views
  FROM purchase_log AS pl
  INNER JOIN view_log AS vl ON vl.external_user_id = pl.external_user_id
  WHERE 
    vl.view_date <= pl.purchase_date  --  ensure view happened BEFORE purchase
    AND DATEDIFF('day', vl.view_date, pl.purchase_date) BETWEEN 0 AND 30  --  only include views up to 30 days before purchase
),

-- create a dataset that list view and purchase in descending order , but also create a column that give number to the row
arranged_view AS (
  SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY purchase_id ORDER BY view_date DESC) AS rn  -- this is for CRM purpose. Every purchase got attributed to last view
	-- ROW_NUMBER() over (partition by campaign_id order by purchase_date asc) as rn  -- this is for ads or finding the first purchase after each view. 
  FROM views_before_purchase
),

-- create a dataset that shows only rn = 1, meaning the one that is the latest
latest_valid_view AS (
  SELECT 
    purchase_id,
    campaign_id,
	medium,
	view_date,
	price,
	diff_days
  FROM arranged_view
  WHERE rn = 1
)

-- put the data from latest_valid_view dataset into corresponding row in purchase_log
SELECT 
  pl.purchase_id,
  pl.external_user_id,
  pl.purchase_date,
  pl.price as value,
  CASE WHEN lvv.campaign_id IS NULL OR lvv.campaign_id = '' THEN 'organic' ELSE lvv.campaign_id END AS campaign_id,
  CASE WHEN lvv.medium IS NULL OR lvv.medium = '' THEN 'organic' ELSE lvv.medium END AS medium,
  lvv.view_date,
  lvv.diff_days
FROM purchase_log AS pl
LEFT JOIN latest_valid_view AS lvv ON pl.purchase_id = lvv.purchase_id
WHERE 1
  AND pl.purchase_date >= DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '7 day'
  AND pl.purchase_date < DATE_TRUNC('week', CURRENT_DATE)
;