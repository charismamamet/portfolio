-- CRM Contribution - LTND 30 day click through attribution
-- how to use: put this code into braze's snowflake sql editor. Then, click `Run`
-- what data will be issued after we run this? Answer: It will be a list of purchase and how do that purchase happen, whether it's organic or via crm campaign 
-- this code is made with the Last Touch Non Direct with 30 day window attribution model from click to purchase, like what Braze defaultly attributing the purchase
-- made by Mamet for the Renos gang
-- with love 💖

WITH 
-- combine the clicks into one dataset
click_log AS (

SELECT
	ban.campaign_id,
	ban.external_user_id,
	CAST(TO_TIMESTAMP(ban.time) AS DATE) AS click_date,
	'banner' AS medium
FROM USERS_MESSAGES_BANNER_CLICK_SHARED AS ban

UNION ALL

SELECT
	iam.campaign_id,
	iam.external_user_id,
	CAST(TO_TIMESTAMP(iam.time) AS DATE) AS click_date,
	'pop-up' AS medium
FROM USERS_MESSAGES_INAPPMESSAGE_CLICK_SHARED AS iam

UNION ALL

SELECT
	pn.campaign_id,
	pn.external_user_id,
	CAST(TO_TIMESTAMP(pn.time) AS DATE) AS click_date,
	'push' AS medium
FROM USERS_MESSAGES_PUSHNOTIFICATION_OPEN_SHARED AS pn

UNION ALL

SELECT
	em.campaign_id,
	em.external_user_id,
	CAST(TO_TIMESTAMP(em.time) AS DATE) AS click_date,
	'email' AS medium
FROM USERS_MESSAGES_EMAIL_CLICK_SHARED AS em

UNION ALL

SELECT
	wa.campaign_id,
	wa.external_user_id,
	CAST(TO_TIMESTAMP(wa.time) AS DATE) AS click_date,
	'whatsapp' AS medium
FROM USERS_MESSAGES_WHATSAPP_CLICK_SHARED AS wa

UNION ALL

SELECT
	cc.campaign_id,
	cc.external_user_id,
	CAST(TO_TIMESTAMP(cc.time) AS DATE) AS click_date,
	'content_card' AS medium
FROM USERS_MESSAGES_CONTENTCARD_CLICK_SHARED AS cc

-- UNION ALL

-- SELECT
 	-- nfc.campaign_id,
    -- nfc.external_user_id,
    -- CAST(TO_TIMESTAMP(nfc.time) AS DATE) AS click_date,
    -- 'news_feed_card' AS medium
-- FROM USERS_MESSAGES_NEWSFEEDCARD_CLICK_SHARED AS nfc

-- UNION ALL

-- SELECT
    -- sms.campaign_id,
    -- sms.external_user_id,
    -- CAST(TO_TIMESTAMP(sms.time) AS DATE) AS click_date,
    -- 'sms' AS medium
-- FROM USERS_MESSAGES_SMS_SHORTLINKCLICK_SHARED AS sms

),

-- creating dataset that has dummy column that work as a unique identifier per user id and sort it by time
purchase_log AS (
  SELECT
	bpl.id AS purchase_id,
	bpl.external_user_id,
	PARSE_JSON(bpl.properties):value::number AS price,
	CAST(TO_TIMESTAMP(bpl.time) AS DATE) AS purchase_date,
  platform,
  os_version 
  FROM USERS_BEHAVIORS_CUSTOMEVENT_SHARED AS bpl
  where 1
	and name = 'purchase'
),

-- creating purchase_log dataset with dummy column that work as unique purchase_id
-- purchase_log AS (
--  SELECT 
--    concat(rpl.external_user_id, '_', rpl.purchase_row) as purchase_id,
--    rpl.external_user_id,
--    rpl.purchase_date AS purchase_date
--  FROM raw_purchase_log as rpl
--),

-- combine purchase_log and click_log datasets but only get clicks that has purchase within +30d after clicks
clicks_before_purchase AS (
  SELECT
    pl.purchase_id,
    pl.external_user_id,
    pl.purchase_date,
	pl.price,
    cl.campaign_id,
	cl.medium,
    cl.click_date AS click_date,
    DATEDIFF('day', cl.click_date, pl.purchase_date) AS diff_days  --  no ABS() to prevent future clicks
  FROM purchase_log AS pl
  INNER JOIN click_log AS cl ON cl.external_user_id = pl.external_user_id
  WHERE 
    cl.click_date <= pl.purchase_date  --  ensure click happened BEFORE purchase
    AND DATEDIFF('day', cl.click_date, pl.purchase_date) BETWEEN 0 AND 30  --  only include click up to 30 days before purchase
),

-- create a dataset that list click and purchase in descending order , but also create a column that give number to the row
arranged_click AS (
  SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY purchase_id ORDER BY click_date DESC) AS rn  -- this is for CRM purpose. Every purchase got attributed to last click
	-- ROW_NUMBER() over (partition by campaign_id order by purchase_date asc) as rn  -- this is for ads or finding the first purchase after each click. 
  FROM clicks_before_purchase
),

-- create a dataset that shows only rn = 1, meaning the one that is the latest
latest_valid_click AS (
  SELECT 
    purchase_id,
    campaign_id,
	medium,
	click_date,
	price,
	diff_days
  FROM arranged_click
  WHERE rn = 1
)

-- put the data from latest_valid_click dataset into corresponding row in purchase_log
SELECT 
  pl.purchase_id,
  pl.external_user_id,
  pl.purchase_date,
  pl.price as value,
  CASE WHEN lvc.campaign_id IS NULL OR lvc.campaign_id = '' THEN 'organic' ELSE lvc.campaign_id END AS campaign_id,
  CASE WHEN lvc.medium IS NULL OR lvc.medium = '' THEN 'organic' ELSE lvc.medium END AS medium,
  lvc.click_date,
  lvc.diff_days,
  pl.platform,
  pl.os_version
FROM purchase_log AS pl
LEFT JOIN latest_valid_click AS lvc ON pl.purchase_id = lvc.purchase_id
WHERE pl.purchase_date >= DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '7 day'
  AND pl.purchase_date < DATE_TRUNC('week', CURRENT_DATE)
;