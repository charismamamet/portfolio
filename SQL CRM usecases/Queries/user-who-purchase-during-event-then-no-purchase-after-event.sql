SELECT DISTINCT user_id
FROM mock_renos_db.mock_purchase
WHERE user_id IN (
    -- Users who bought during the event
    SELECT DISTINCT user_id
    FROM mock_renos_db.mock_purchase
    WHERE LOWER(renos_code) LIKE '%renosfair%'
      AND order_date BETWEEN '2025-06-27' AND '2025-06-29'
      AND order_status IN ('menunggu pembayaran', 'selesai')
)
AND user_id NOT IN (
    -- Users who bought after the event
    SELECT DISTINCT user_id
    FROM mock_renos_db.mock_purchase
    WHERE order_date > '2025-06-29'
      AND order_status IN ('menunggu pembayaran', 'selesai')
);
