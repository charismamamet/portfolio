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
category_followup_pairs AS (
  SELECT 
    a.user_id,
    a.cat_name AS initial_category,
    b.cat_name AS followup_category
  FROM filtered_purchase a
  JOIN filtered_purchase b 
    ON a.user_id = b.user_id
   AND a.order_date < b.order_date
   AND a.order_id != b.order_id
),

-- dataset category_followup_pairs dibikin urutan berdasarkan initial category
ranked_followups AS (
  SELECT 
    initial_category,
    followup_category,
    COUNT(*) AS followup_count,
    ROW_NUMBER() OVER (
      PARTITION BY initial_category 
      ORDER BY COUNT(*) DESC
    ) AS rn
  FROM category_followup_pairs
  GROUP BY initial_category, followup_category
),

-- dataset filtered_purchase dibikin pivot berdasarkan total order
purchase_counts AS (
  SELECT 
    cat_name,
    COUNT(*) AS total_orders
  FROM filtered_purchase
  GROUP BY cat_name
),

-- bikin dataset yang berisi list dua produk teratas tiap initial category di tabel ranked_followups
top_followups AS (
  SELECT 
    rf.initial_category,
    rf.rn,
    rf.followup_category,
    rf.followup_count,
    pc.total_orders AS followup_total_orders
  FROM ranked_followups rf
  LEFT JOIN purchase_counts pc
    ON rf.followup_category = pc.cat_name
  WHERE rf.rn <= 2
),

-- ngilangin kolom rn dari dataset top_followups
pivoted_followups AS (
  SELECT 
    initial_category,
    MAX(CASE WHEN rn = 1 THEN followup_category END) AS cat_name_2,
    MAX(CASE WHEN rn = 1 THEN followup_total_orders END) AS cat_name_2_total_order,
    MAX(CASE WHEN rn = 2 THEN followup_category END) AS cat_name_3,
    MAX(CASE WHEN rn = 2 THEN followup_total_orders END) AS cat_name_3_total_order
  FROM top_followups
  GROUP BY initial_category
)

SELECT 
  pc.cat_name AS cat_name,
  pc.total_orders,
  pf.cat_name_2,
  pf.cat_name_2_total_order,
  pf.cat_name_3,
  pf.cat_name_3_total_order
FROM purchase_counts pc
LEFT JOIN pivoted_followups pf
  ON pc.cat_name = pf.initial_category
ORDER BY pc.total_orders DESC;