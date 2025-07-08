select sum(i.total) as "rev", strftime("%Y-%m", i.invoicedate) as "month"

from invoices as i

group by month