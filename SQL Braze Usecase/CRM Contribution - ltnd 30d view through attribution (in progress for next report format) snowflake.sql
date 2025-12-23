-- how to use: put this code into braze's snowflake sql editor. Then, click `Run`
-- what data will be issued after we run this? Answer: It will be a list of purchase and how do that purchase happen, whether it's organic or via crm campaign 
-- this code is made with the Last Touch Non Direct with 30 day window attribution model from view to purchase, like what Braze defaultly attributing the purchase
-- made by Mamet for the Renos gang
-- with love 💖

WITH 
-- -- cte grouping 1
-- Combine all view events
view_log AS (
  SELECT campaign_id, external_user_id, CAST(TO_TIMESTAMP(time) AS DATE) AS event_date, 'banner' AS medium
  FROM USERS_MESSAGES_BANNER_IMPRESSION_SHARED
  UNION ALL
  SELECT campaign_id, external_user_id, CAST(TO_TIMESTAMP(time) AS DATE), 'pop-up'
  FROM USERS_MESSAGES_INAPPMESSAGE_IMPRESSION_SHARED
  UNION ALL
  SELECT campaign_id, external_user_id, CAST(TO_TIMESTAMP(time) AS DATE), 'push'
  FROM USERS_MESSAGES_PUSHNOTIFICATION_SEND_SHARED
  UNION ALL
  SELECT campaign_id, external_user_id, CAST(TO_TIMESTAMP(time) AS DATE), 'email'
  FROM USERS_MESSAGES_EMAIL_DELIVERY_SHARED
  UNION ALL
  SELECT campaign_id, external_user_id, CAST(TO_TIMESTAMP(time) AS DATE), 'whatsapp'
  FROM USERS_MESSAGES_WHATSAPP_DELIVERY_SHARED
  UNION ALL
  SELECT campaign_id, external_user_id, CAST(TO_TIMESTAMP(time) AS DATE), 'content_card'
  FROM USERS_MESSAGES_CONTENTCARD_IMPRESSION_SHARED
-- UNION ALL

-- SELECT
 	-- nfc.campaign_id,
    -- nfc.external_user_id,
    -- CAST(TO_TIMESTAMP(nfc.time) AS DATE),
    -- 'news_feed_card' AS medium
-- FROM USERS_MESSAGES_NEWSFEEDCARD_IMPRESSION_SHARED AS nfc

-- UNION ALL

-- SELECT
    -- sms.campaign_id,
    -- sms.external_user_id,
    -- CAST(TO_TIMESTAMP(sms.time) AS DATE),
    -- 'sms' AS medium
-- FROM USERS_MESSAGES_SMS_DELIVERY_SHARED AS sms

),

open_log AS (
  SELECT campaign_id, external_user_id, CAST(TO_TIMESTAMP(time) AS DATE) as event_date, 'email' as medium
  FROM USERS_MESSAGES_EMAIL_OPEN_SHARED
  UNION ALL
  SELECT campaign_id, external_user_id, CAST(TO_TIMESTAMP(time) AS DATE), 'whatsapp'
  FROM USERS_MESSAGES_WHATSAPP_READ_SHARED
),

-- Combine all click events
click_log AS (
  SELECT campaign_id, external_user_id, CAST(TO_TIMESTAMP(time) AS DATE) AS event_date, 'banner' AS medium
  FROM USERS_MESSAGES_BANNER_CLICK_SHARED
  UNION ALL
  SELECT campaign_id, external_user_id, CAST(TO_TIMESTAMP(time) AS DATE), 'pop-up'
  FROM USERS_MESSAGES_INAPPMESSAGE_CLICK_SHARED
  UNION ALL
  SELECT campaign_id, external_user_id, CAST(TO_TIMESTAMP(time) AS DATE), 'push'
  FROM USERS_MESSAGES_PUSHNOTIFICATION_OPEN_SHARED
  UNION ALL
  SELECT campaign_id, external_user_id, CAST(TO_TIMESTAMP(time) AS DATE), 'email'
  FROM USERS_MESSAGES_EMAIL_CLICK_SHARED
  UNION ALL
  SELECT campaign_id, external_user_id, CAST(TO_TIMESTAMP(time) AS DATE), 'whatsapp'
  FROM USERS_MESSAGES_WHATSAPP_CLICK_SHARED
  UNION ALL
  SELECT campaign_id, external_user_id, CAST(TO_TIMESTAMP(time) AS DATE), 'content_card'
  FROM USERS_MESSAGES_CONTENTCARD_CLICK_SHARED
-- UNION ALL

-- SELECT
 	-- nfc.campaign_id,
    -- nfc.external_user_id,
    -- CAST(TO_TIMESTAMP(nfc.time) AS DATE),
    -- 'news_feed_card' AS medium
-- FROM USERS_MESSAGES_NEWSFEEDCARD_CLICK_SHARED AS nfc

-- UNION ALL

-- SELECT
    -- sms.campaign_id,
    -- sms.external_user_id,
    -- CAST(TO_TIMESTAMP(sms.time) AS DATE),
    -- 'sms' AS medium
-- FROM USERS_MESSAGES_SMS_SHORTLINKCLICK_SHARED AS sms
),

-- Aggregate per campaign per date for both views & clicks
view_summary AS (
  SELECT 
    event_date,
    campaign_id,
    COUNT(*) AS num_of_view
  FROM view_log
  where campaign_id <> '693bc3bcb531780063a24c87'
  GROUP BY event_date, campaign_id
),
open_summary as (
  select 
    event_date,
	campaign_id,
	count(*) as num_of_open 
  from open_log
  where campaign_id <> '693bc3bcb531780063a24c87'
  group by event_date, campaign_id 
),
click_summary AS (
  SELECT 
    event_date,
    campaign_id,
    COUNT(*) AS num_of_click
  FROM click_log
  where campaign_id <> '693bc3bcb531780063a24c87'
  GROUP BY event_date, campaign_id
),

-- -- cte grouping 2
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
	and name = 'payment'
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
    cl.event_date AS event_date,
    DATEDIFF('day', cl.event_date, pl.purchase_date) AS diff_days  --  no ABS() to prevent future clicks
  FROM purchase_log AS pl
  INNER JOIN click_log AS cl ON cl.external_user_id = pl.external_user_id
  WHERE 
    cl.event_date <= pl.purchase_date  --  ensure click happened BEFORE purchase
    AND DATEDIFF('day', cl.event_date, pl.purchase_date) BETWEEN 0 AND 30  --  only include click up to 30 days before purchase
    AND cl.campaign_id <> '693bc3bcb531780063a24c87'
),

-- create a dataset that list click and purchase in descending order , but also create a column that give number to the row
arranged_click AS (
  SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY purchase_id ORDER BY event_date DESC) AS rn  -- this is for CRM purpose. Every purchase got attributed to last click
	-- ROW_NUMBER() over (partition by campaign_id order by purchase_date asc) as rn  -- this is for ads or finding the first purchase after each click. 
  FROM clicks_before_purchase
),

-- create a dataset that shows only rn = 1, meaning the one that is the latest
latest_valid_click AS (
  SELECT 
    purchase_id as id,
    campaign_id,
  	medium,
  	event_date,
  	price,
  	diff_days,
	'purchase' as custom_event
  FROM arranged_click
  WHERE rn = 1
),

-- -- cte grouping 3
-- creating dataset that has dummy column that work as a unique identifier per user id and sort it by time
checkout_log AS (
  SELECT
	bpl.id AS checkout_id,
  	bpl.external_user_id,
  	PARSE_JSON(bpl.properties):value::number AS price,
  	CAST(TO_TIMESTAMP(bpl.time) AS DATE) AS checkout_date,
    platform,
    os_version 
  FROM USERS_BEHAVIORS_CUSTOMEVENT_SHARED AS bpl
  where 1
	and name = 'begin_checkout'
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
clicks_before_checkout AS (
  SELECT
    col.checkout_id,
    col.external_user_id,
    col.checkout_date,
	col.price,
    cl.campaign_id,
	cl.medium,
    cl.event_date AS event_date,
    DATEDIFF('day', cl.event_date, col.checkout_date) AS diff_days  --  no ABS() to prevent future clicks
  FROM checkout_log AS col
  INNER JOIN click_log AS cl ON cl.external_user_id = col.external_user_id
  WHERE 
    cl.event_date <= col.checkout_date  --  ensure click happened BEFORE purchase
    AND DATEDIFF('day', cl.event_date, col.checkout_date) BETWEEN 0 AND 30  --  only include click up to 30 days before purchase
),

-- create a dataset that list click and purchase in descending order , but also create a column that give number to the row
arranged_click2 AS (
  SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY checkout_id ORDER BY event_date DESC) AS rn  -- this is for CRM purpose. Every purchase got attributed to last click
	-- ROW_NUMBER() over (partition by campaign_id order by purchase_date asc) as rn  -- this is for ads or finding the first purchase after each click. 
  FROM clicks_before_checkout
),

-- create a dataset that shows only rn = 1, meaning the one that is the latest
latest_valid_checkout AS (
  SELECT 
    checkout_id as id,
    campaign_id,
	medium,
	event_date,
	price,
	diff_days,
	'begin_checkout' as custom_event
  FROM arranged_click2
  WHERE rn = 1
),

-- -- cte grouping 4
-- creating dataset that has dummy column that work as a unique identifier per user id and sort it by time
atc_log AS (
  SELECT
  	bpl.id AS atc_id,
  	bpl.external_user_id,
  	PARSE_JSON(bpl.properties):value::number AS price,
  	CAST(TO_TIMESTAMP(bpl.time) AS DATE) AS atc_date,
    platform,
    os_version 
  FROM USERS_BEHAVIORS_CUSTOMEVENT_SHARED AS bpl
  where 1
	and name = 'add_to_cart'
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
clicks_before_atc AS (
  SELECT
    atcl.atc_id,
    atcl.external_user_id,
    atcl.atc_date,
	atcl.price,
    cl.campaign_id,
	cl.medium,
    cl.event_date AS event_date,
    DATEDIFF('day', cl.event_date, atcl.atc_date) AS diff_days  --  no ABS() to prevent future clicks
  FROM atc_log AS atcl
  INNER JOIN click_log AS cl ON cl.external_user_id = atcl.external_user_id
  WHERE 
    cl.event_date <= atcl.atc_date  --  ensure click happened BEFORE purchase
    AND DATEDIFF('day', cl.event_date, atcl.atc_date) BETWEEN 0 AND 30  --  only include click up to 30 days before purchase
),

-- create a dataset that list click and purchase in descending order , but also create a column that give number to the row
arranged_click3 AS (
  SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY atc_id ORDER BY event_date DESC) AS rn  -- this is for CRM purpose. Every purchase got attributed to last click
	-- ROW_NUMBER() over (partition by campaign_id order by purchase_date asc) as rn  -- this is for ads or finding the first purchase after each click. 
  FROM clicks_before_atc
),

-- create a dataset that shows only rn = 1, meaning the one that is the latest
latest_valid_atc AS (
  SELECT 
    atc_id as id,
    campaign_id,
	medium,
	event_date,
	price,
	diff_days,
	'add_to_cart' as custom_event
  FROM arranged_click3
  WHERE rn = 1
),

-- -- cte grouping 5
-- creating dataset that has dummy column that work as a unique identifier per user id and sort it by time
pdp_log AS (
  SELECT
  	bpl.id AS pdp_id,
  	bpl.external_user_id,
  	PARSE_JSON(bpl.properties):value::number AS price,
  	CAST(TO_TIMESTAMP(bpl.time) AS DATE) AS pdp_date,
    platform,
    os_version 
  FROM USERS_BEHAVIORS_CUSTOMEVENT_SHARED AS bpl
  where 1
	and name = 'view_item'
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
clicks_before_pdp AS (
  SELECT
    pdpl.pdp_id,
    pdpl.external_user_id,
    pdpl.pdp_date,
	pdpl.price,
    cl.campaign_id,
	cl.medium,
    cl.event_date AS event_date,
    DATEDIFF('day', cl.event_date, pdpl.pdp_date) AS diff_days  --  no ABS() to prevent future clicks
  FROM pdp_log AS pdpl
  INNER JOIN click_log AS cl ON cl.external_user_id = pdpl.external_user_id
  WHERE 
    cl.event_date <= pdpl.pdp_date  --  ensure click happened BEFORE purchase
    AND DATEDIFF('day', cl.event_date, pdpl.pdp_date) BETWEEN 0 AND 30  --  only include click up to 30 days before purchase
),

-- create a dataset that list click and purchase in descending order , but also create a column that give number to the row
arranged_click4 AS (
  SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY pdp_id ORDER BY event_date DESC) AS rn  -- this is for CRM purpose. Every purchase got attributed to last click
	-- ROW_NUMBER() over (partition by campaign_id order by purchase_date asc) as rn  -- this is for ads or finding the first purchase after each click. 
  FROM clicks_before_pdp
),

-- create a dataset that shows only rn = 1, meaning the one that is the latest
latest_valid_pdp AS (
  SELECT 
    pdp_id as id,
    campaign_id,
	medium,
	event_date,
	price,
	diff_days,
	'view_item' as custom_event
  FROM arranged_click4
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
  lvc.event_date,
  lvc.diff_days
FROM purchase_log AS pl
LEFT JOIN latest_valid_click AS lvc ON pl.purchase_id = lvc.id
WHERE 1
  AND pl.purchase_date >= DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '7 day'
  AND pl.purchase_date < DATE_TRUNC('week', CURRENT_DATE)
limit 6
;