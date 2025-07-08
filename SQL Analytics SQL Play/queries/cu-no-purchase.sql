select distinct(cu.customerid), cu.lastname, cu.firstname
from customers as cu
left join invoices as i on i.customerid = cu.customerid
where i.customerid is null
order by cu.customerid desc