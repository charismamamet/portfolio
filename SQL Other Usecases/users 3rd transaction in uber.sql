SELECT
  x.user_id,
  x.spend,
  x.transaction_date
from(select
  t.user_id,
  t.spend,
  t.transaction_date,
  row_number() over (partition by t.user_id order by t.transaction_date) as rn
from transactions as t) x
where rn = 3
