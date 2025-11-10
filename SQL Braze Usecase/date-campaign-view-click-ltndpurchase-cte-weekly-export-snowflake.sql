-- how to use: put this code into braze's snowflake sql editor. Then, click `Run`
-- what data will be issued after we run this? Answer: It will be a list of campaign engagement performance and the attributed purchase and value 
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
  GROUP BY event_date, campaign_id
),
click_summary AS (
  SELECT 
    event_date,
    campaign_id,
    COUNT(*) AS num_of_click
  FROM click_log
  GROUP BY event_date, campaign_id
),

-- -- cte grouping 2
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
    vl.event_date AS event_date,
    DATEDIFF('day', vl.event_date, pl.purchase_date) AS diff_days  --  no ABS() to prevent future views
  FROM purchase_log AS pl
  INNER JOIN view_log AS vl ON vl.external_user_id = pl.external_user_id
  WHERE 
    vl.event_date <= pl.purchase_date  --  ensure view happened BEFORE purchase
    AND DATEDIFF('day', vl.event_date, pl.purchase_date) BETWEEN 0 AND 30  --  only include views up to 30 days before purchase
),

-- create a dataset that list view and purchase in descending order , but also create a column that give number to the row
arranged_view AS (
  SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY purchase_id ORDER BY event_date DESC) AS rn  -- this is for CRM purpose. Every purchase got attributed to last view
	-- ROW_NUMBER() over (partition by campaign_id order by purchase_date asc) as rn  -- this is for ads or finding the first purchase after each view. 
  FROM views_before_purchase
),

-- create a dataset that shows only rn = 1, meaning the one that is the latest
latest_valid_view AS (
  SELECT 
    purchase_id,
    campaign_id,
	medium,
	event_date,
	price,
	diff_days
  FROM arranged_view
  WHERE rn = 1
),

-- -- final act of cte grouping 1
-- Combine both sides (include clicks-only campaigns)
combined AS (
  SELECT 
    COALESCE(v.event_date, c.event_date) AS event_date,
    COALESCE(v.campaign_id, c.campaign_id) AS campaign_id,
    COALESCE(v.num_of_view, 0) AS num_of_view,
    COALESCE(c.num_of_click, 0) AS num_of_click
  FROM view_summary v
  FULL OUTER JOIN click_summary c
    ON v.campaign_id = c.campaign_id
   AND v.event_date = c.event_date
),

-- -- final act of cte grouping 2
-- aggregate the ltnd
latest_valid_view_agg as (
  SELECT
	event_date,
	campaign_id,
	medium,
	count(distinct(purchase_id)) as orders,
	sum(price) as value
  from latest_valid_view
  group by event_date, campaign_id, medium
)
	
-- Final output
SELECT 
	c.*,
	d.orders,
	d.value
FROM combined as c
left join latest_valid_view_agg as d on d.campaign_id = c.campaign_id and d.event_date = c.event_date
WHERE 1
  AND c.event_date >= DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '7 day'
  AND c.event_date < DATE_TRUNC('week', CURRENT_DATE)
ORDER BY c.event_date ASC, c.campaign_id;
