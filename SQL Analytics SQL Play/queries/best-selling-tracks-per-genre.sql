SELECT 
  tr.name AS judul, 
  tr.trackid, 
  g.name AS aliran, 
  g.genreid,
  SUM(ii.unitprice * ii.quantity) AS rev,
  SUM(ii.quantity) AS orders
FROM genres AS g
LEFT JOIN tracks AS tr ON tr.genreid = g.genreid
LEFT JOIN invoice_items AS ii ON ii.trackid = tr.trackid
GROUP BY 
  tr.trackid,
  tr.name, 
  g.name, 
  g.genreid
ORDER BY rev DESC;
