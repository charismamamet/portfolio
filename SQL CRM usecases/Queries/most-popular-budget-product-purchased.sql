SELECT 
  mp.cat_name,
  mp.seller_name,
  mp.sku_name,
  count(distinct(mp.order_id)),
  LOWER(CONCAT(
    'https://www.renos.id/p/',
    REGEXP_REPLACE(
      REGEXP_REPLACE(
        REGEXP_REPLACE(mp.seller_name, '[ _@.!#$%&*+/=?^`{}|~]', '-'),
        '[,()]', ''
      ),
      '-{2,}', '-'
    ),
    '/',
    REGEXP_REPLACE(
      REGEXP_REPLACE(
        REGEXP_REPLACE(mp.sku_name, '[ _@.!#$%&*+/=?^`{}|~]', '-'),
        '[,()]', ''
      ),
      '-{2,}', '-'
    )
  )) AS product_url
FROM mock_renos_db.mock_purchase as mp
left join suspicious_seller as ss on ss.seller_name = mp.seller_name
WHERE mp.order_date BETWEEN '2025-07-01' AND '2025-07-23'
  AND mp.order_status IN ('menunggu pembayaran', 'selesai')
  AND mp.renos_code NOT LIKE '%prj%'
  AND mp.renos_code NOT LIKE '%renosfair%'
  AND mp.seller_name not like '%tes%'
  AND mp.sku_sell_price / mp.sku_qty <= 500000
  AND mp.seller_name not in (select seller_name from suspicious_seller)
group by cat_name, seller_name, sku_name
order by count(distinct(order_id)) desc;