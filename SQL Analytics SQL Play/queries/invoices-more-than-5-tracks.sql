select ii.InvoiceId, count(ii.Trackid) as num_of_tracks, i.CustomerId as cu_id, cu.FirstName, cu.LastName, cu.Email, cu.Phone
from invoice_items as ii
left join Invoices as i on i.InvoiceId = ii.invoiceid
left join customers as cu on cu.CustomerId = i.CustomerId 
group by ii.InvoiceId
having num_of_tracks > 5
order by cu_id desc;