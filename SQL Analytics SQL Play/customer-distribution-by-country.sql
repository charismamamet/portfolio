select Country, count(CustomerId) as "num_of_cu"
from customers
group by Country
order by Country
;