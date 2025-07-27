SELECT cl.userid, cl.campaignid
FROM click_log cl
WHERE cl.userid IN (
    SELECT DISTINCT userid
    FROM click_log
)
AND cl.userid IN (
    SELECT DISTINCT userid
    FROM purchase_log
)
AND cl.date = (
    SELECT MAX(date)
    FROM click_log sub
    WHERE sub.userid = cl.userid
)
