WITH 
-- bikin dataset yang bersih berisi purchase yang dipakai doang
filtered_purchase AS (
  SELECT 
    user_id,
    order_id,
    order_date,
    cat_name
  FROM mock_renos_db.mock_purchase
  WHERE order_date BETWEEN '2025-07-01' AND '2025-07-23'
    AND order_status IN ('menunggu pembayaran', 'selesai')
),

-- join dataset filtered_purchse dengan dirinya sendiri yang mengoutput row pasangan
pair_within_order AS (
  SELECT 
    a.cat_name AS initial_category,
    b.cat_name AS copurchased_category
  FROM filtered_purchase as a
  JOIN filtered_purchase as b 
    ON a.order_id = b.order_id
   AND a.cat_name <> b.cat_name
),

-- dataset pair_within_order dibikin urutan berdasarkan initial category
ranked_copurchases AS (
  SELECT 
    initial_category,
    copurchased_category,
    COUNT(copurchased_category) AS copurchase_count,
    ROW_NUMBER() OVER (
      PARTITION BY initial_category 
      ORDER BY COUNT(*) DESC
    ) AS rn
  FROM pair_within_order
  GROUP BY initial_category, copurchased_category
),

-- dataset filtered_purchase dibikin pivot berdasarkan total order
purchase_counts AS (
  SELECT 
    cat_name,
    COUNT(*) AS total_orders
  FROM filtered_purchase
  GROUP BY cat_name
),

-- bikin dataset yang berisi list dua produk teratas tiap initial category di tabel ranked_copurchases
top_copurchases AS (
  SELECT 
    rc.initial_category,
    rc.rn,
    rc.copurchased_category,
    rc.copurchase_count,
    pc.total_orders AS copurchased_total_orders
  FROM ranked_copurchases as rc
  LEFT JOIN purchase_counts as pc
    ON rc.copurchased_category = pc.cat_name
  WHERE rc.rn <= 2
),

-- ngilangin kolom rn dari dataset ranked_copurchases
pivoted_copurchases AS (
  SELECT 
    initial_category,
    MAX(CASE WHEN rn = 1 THEN copurchased_category END) AS cat_name_2,
    MAX(CASE WHEN rn = 1 THEN copurchased_total_orders END) AS cat_name_2_total_order,
    MAX(CASE WHEN rn = 2 THEN copurchased_category END) AS cat_name_3,
    MAX(CASE WHEN rn = 2 THEN copurchased_total_orders END) AS cat_name_3_total_order
  FROM top_copurchases
  GROUP BY initial_category
)

-- nambahin jumlah order dari initial_category
SELECT 
  pc.cat_name AS cat_name,
  pc.total_orders,
  pcp.cat_name_2,
  pcp.cat_name_2_total_order,
  pcp.cat_name_3,
  pcp.cat_name_3_total_order
FROM purchase_counts as pc
LEFT JOIN pivoted_copurchases as pcp
  ON pc.cat_name = pcp.initial_category
ORDER BY pc.total_orders DESC;
