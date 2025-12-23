WITH
source_data AS (
    SELECT 
        s.external_user_id,
        CAST(TO_TIMESTAMP(s.time) AS DATE) AS event_date,
        s.platform,
        s.os_version
    FROM USERS_BEHAVIORS_APP_SESSIONSTART_SHARED AS s
),

daily_daily_unique_visitor AS (
    SELECT 
        sd.event_date,
        COUNT(DISTINCT sd.external_user_id) AS num_daily_unique_visitor,
        sd.platform
    FROM source_data AS sd 
    GROUP BY sd.event_date, sd.platform
),

daily_30d_unique_visitor AS (
    -- For each event_date/platform, count distinct users seen in the past 30 days (inclusive)
    SELECT
        sd.event_date,
        COUNT(DISTINCT sd2.external_user_id) AS num_daily_30d_unique_visitor,
        sd.platform
    FROM source_data AS sd 
    LEFT JOIN source_data AS sd2
      ON sd2.event_date BETWEEN DATEADD(day, -30, sd.event_date) AND sd.event_date
     AND sd2.platform = sd.platform
    GROUP BY sd.event_date, sd.platform
)

SELECT 
    du.event_date,
    max(du.num_daily_unique_visitor) as daily_visitor,
    max(dx.num_daily_30d_unique_visitor) as l30d_visitor,
    du.platform as platform
FROM daily_daily_unique_visitor as du
left join daily_30d_unique_visitor as dx on dx.event_date = du.event_date and dx.platform = du.platform
where 1
    and du.event_date >= DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '7 day'
    and du.event_date < DATE_TRUNC('week', CURRENT_DATE)
group by du.event_date, du.platform
