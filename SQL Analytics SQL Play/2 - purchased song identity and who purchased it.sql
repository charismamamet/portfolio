select  ii.invoiceid,
  ii.trackid,
  iv.Customerid as idpelanggan,
  tr.name as trackname,
  tr.genreid,
  gn.name as aliran,
  cu.Firstname,
  cu.Lastname
FROM
  invoice_items as ii

left join
  invoices as iv on iv.invoiceid = ii.invoiceid

left join tracks as tr on tr.trackid = ii.trackid

left join genres as gn on gn.genreid = tr.genreid

left join customers as cu on cu.Customerid = iv.Customerid

order by idpelanggan asc;