SELECT count(i.invoiceid) as "num_of_purchases", i.customerid, cu.firstname, cu.lastname
from invoices As i
left join customers as cu on cu.customerid = i.customerid
group by i.customerid, cu.firstname, cu.lastname
having num_of_purchases > 6