with 
-- combine the click into one dataset
click_log as (

select
	cc.campaign_id,
	cc.user_id,
	cast(to_timestamp(cc.time) as date) as click_date,
	'content_card' as medium
from USERS_MESSAGES_CONTENTCARD_CLICK_SHARED as cc

union all

select
	em.campaign_id
	em.user_id
	cast(to_timestamp(em.time) as date) as click_date,
	'email' as medium
from USERS_MESSAGES_EMAIL_CLICK_SHARED as em

union all

select
	iam.campaign_id
	iam.user_id
	cast(to_timestamp(iam.time) as date) as click_date,
	'pop-up' as medium
from USERS_MESSAGES_INAPPMESSAGE_CLICK_SHARED as iam

union all

select
	nfc.campaign_id,
	nfc.user_id,
	cast(to_timestamp(nfc.time) as date) as click_date,
	'news_feed_card' as medium
from USERS_MESSAGES_NEWSFEEDCARD_CLICK_SHARED as nfc

union all

select
	sms.campaign_id,
	sms.user_id,
	cast(to_timestamp(sms.time) as date) as click_date,
	'sms' as medium
from USERS_MESSAGES_SMS_SHORTLINKCLICK_SHARED as sms

union all

select
	pn.campaign_id,
	pn.user_id,
	cast(to_timestamp(pn.time) as date) as click_date,
	'push' as medium
from USERS_MESSAGES_PUSHNOTIFICATION_OPEN_SHARED as pn
),

-- creating dataset that has dummy column that work as a unique identifier per user id and sort it by time
raw_purchase_log as (
  select
	row_number() over (partition by pl.user_id order by pl.time) as purchase_row,
	pl.user_id,
	cast(to_timestamp(pl.time) as date) as purchase_date
  FROM USERS_BEHAVIORS_PURCHASE_SHARED as pl
),

-- creating purchase_log dataset with dummy column that work as unique purchase_id
purchase_log AS (
  SELECT 
    concat(rpl.user_id, '_', rpl.purchase_row) as purchase_id,
    rpl.user_id,
    rpl.purchase_date AS purchase_date
  FROM raw_purchase_log as rpl
),

-- combine purchase_log and click_log datasets but only get click that has purchase within +30d after click
clicks_before_purchase AS (
  SELECT
    pl.purchase_id,
    pl.user_id,
    pl.purchase_date,
    cl.campaign_id,
	cl.medium,
    cl.click_date AS click_date,
    DATEDIFF(pl.purchase_date, cl.click_date) AS diff_days
  FROM purchase_log as pl
  Inner JOIN click_log as cl ON cl.user_id = pl.user_id
  WHERE cl.click_date <= pl.purchase_date
    AND DATEDIFF(pl.purchase_date, cl.click_date) <= 30
),

-- create a dataset that list click and purchase in descending order , but also create a column that give number to the row
arranged_click AS (
  SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY purchase_id ORDER BY click_date DESC) AS rn
  FROM clicks_before_purchase
),

-- create a dataset that shows only rn = 1, meaning the one that is the latest
latest_valid_click AS (
  SELECT 
    purchase_id,
    campaign_id,
	medium,
	click_date,
	diff_days
  FROM arranged_click
  WHERE rn = 1
)

-- put the data from latest_valid_click dataset into corresponding row in purchase_log
SELECT 
  pl.purchase_id,
  pl.user_id,
  pl.purchase_date,
  CASE WHEN lvc.campaign_id IS NULL OR lvc.campaign_id = '' THEN 'organic' ELSE lvc.campaign_id END AS campaign_id,
  case when lvc.medium is null or lvc.medium ='' then 'other' else lvc.medium end as medium,
  lvc.click_date,
  lvc.diff_days
FROM purchase_log as pl
LEFT JOIN latest_valid_click as lvc ON pl.purchase_id = lvc.purchase_id;
