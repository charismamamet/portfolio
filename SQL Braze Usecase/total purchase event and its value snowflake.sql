-- Welcome to Query Builder!
-- This is a custom SQL editor that lets you run queries against Braze data in Snowflake using Snowflake SQL.
-- Documentation on the Snowflake syntax can be found here:
-- https://docs.snowflake.com/reference
SELECT
    CAST(TO_TIMESTAMP(bpl.time) AS DATE) AS purchase_date,
    COUNT(DISTINCT (bpl.id)) AS orders,
    SUM(PARSE_JSON(bpl.properties):value::number) AS price,
    bpl.platform 
FROM USERS_BEHAVIORS_CUSTOMEVENT_SHARED AS bpl
WHERE 1=1
    AND name = 'purchase'
    AND TO_TIMESTAMP(bpl.time) >= DATEADD('day', -7, DATE_TRUNC('week', CURRENT_DATE))
    AND TO_TIMESTAMP(bpl.time) < DATE_TRUNC('week', CURRENT_DATE)
GROUP BY purchase_date, bpl.platform
;
