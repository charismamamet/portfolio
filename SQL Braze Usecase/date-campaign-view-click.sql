-- Get views + clicks per campaign per date
SELECT 
  COALESCE(v.view_date, c.click_date) AS event_date,
  COALESCE(v.campaign_id, c.campaign_id) AS campaign_id,
  COALESCE(v.num_of_view, 0) AS num_of_view,
  COALESCE(c.num_of_click, 0) AS num_of_click
FROM (
  -- Subquery for views
  SELECT 
    date(from_unixtime(time)) AS view_date,
    campaign_id,
    COUNT(*) AS num_of_view
  FROM (
    SELECT campaign_id, external_user_id, time FROM USERS_MESSAGES_BANNER_IMPRESSION_SHARED
    UNION ALL
    SELECT campaign_id, external_user_id, time FROM USERS_MESSAGES_INAPPMESSAGE_IMPRESSION_SHARED
    UNION ALL
    SELECT campaign_id, external_user_id, time FROM USERS_MESSAGES_PUSHNOTIFICATION_SEND_SHARED
    UNION ALL
    SELECT campaign_id, external_user_id, time FROM USERS_MESSAGES_EMAIL_DELIVERY_SHARED
    UNION ALL
    SELECT campaign_id, external_user_id, time FROM USERS_MESSAGES_WHATSAPP_DELIVERY_SHARED
  ) AS v
  GROUP BY view_date, campaign_id
) AS v
LEFT JOIN (
  -- Subquery for clicks
  SELECT 
    date(from_unixtime(time)) AS click_date,
    campaign_id,
    COUNT(*) AS num_of_click
  FROM (
    SELECT campaign_id, external_user_id, time FROM USERS_MESSAGES_BANNER_CLICK_SHARED
    UNION ALL
    SELECT campaign_id, external_user_id, time FROM USERS_MESSAGES_INAPPMESSAGE_CLICK_SHARED
    UNION ALL
    SELECT campaign_id, external_user_id, time FROM USERS_MESSAGES_PUSHNOTIFICATION_OPEN_SHARED
    UNION ALL
    SELECT campaign_id, external_user_id, time FROM USERS_MESSAGES_EMAIL_CLICK_SHARED
    UNION ALL
    SELECT campaign_id, external_user_id, time FROM USERS_MESSAGES_WHATSAPP_CLICK_SHARED
  ) AS c
  GROUP BY click_date, campaign_id
) AS c
  ON v.campaign_id = c.campaign_id
  AND v.view_date = c.click_date

UNION ALL

-- Add the reverse side for "clicks only" campaigns
SELECT 
  c.click_date AS event_date,
  c.campaign_id,
  0 AS num_of_view,
  c.num_of_click
FROM (
  SELECT 
    date(from_unixtime(time)) AS click_date,
    campaign_id,
    COUNT(*) AS num_of_click
  FROM (
    SELECT campaign_id, external_user_id, time FROM USERS_MESSAGES_BANNER_CLICK_SHARED
    UNION ALL
    SELECT campaign_id, external_user_id, time FROM USERS_MESSAGES_INAPPMESSAGE_CLICK_SHARED
    UNION ALL
    SELECT campaign_id, external_user_id, time FROM USERS_MESSAGES_PUSHNOTIFICATION_OPEN_SHARED
    UNION ALL
    SELECT campaign_id, external_user_id, time FROM USERS_MESSAGES_EMAIL_CLICK_SHARED
    UNION ALL
    SELECT campaign_id, external_user_id, time FROM USERS_MESSAGES_WHATSAPP_CLICK_SHARED
  ) AS c2
  GROUP BY click_date, campaign_id
) AS c
LEFT JOIN (
  SELECT 
    date(from_unixtime(time)) AS view_date,
    campaign_id
  FROM (
    SELECT campaign_id, external_user_id, time FROM USERS_MESSAGES_BANNER_IMPRESSION_SHARED
    UNION ALL
    SELECT campaign_id, external_user_id, time FROM USERS_MESSAGES_INAPPMESSAGE_IMPRESSION_SHARED
    UNION ALL
    SELECT campaign_id, external_user_id, time FROM USERS_MESSAGES_PUSHNOTIFICATION_SEND_SHARED
    UNION ALL
    SELECT campaign_id, external_user_id, time FROM USERS_MESSAGES_EMAIL_DELIVERY_SHARED
    UNION ALL
    SELECT campaign_id, external_user_id, time FROM USERS_MESSAGES_WHATSAPP_DELIVERY_SHARED
  ) AS v2
  GROUP BY view_date, campaign_id
) AS v
  ON c.campaign_id = v.campaign_id
  AND c.click_date = v.view_date
WHERE v.campaign_id IS NULL

ORDER BY event_date ASC, campaign_id;