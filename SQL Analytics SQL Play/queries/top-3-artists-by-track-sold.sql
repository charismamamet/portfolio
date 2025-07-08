SELECT 
  SUM(ii.quantity) AS total_tracks_sold,
  al.artistid,
  ar.name AS artist_name,
  count(distinct(ii.trackid)) as artist_tracks
FROM invoice_items AS ii
LEFT JOIN tracks AS tr ON tr.trackid = ii.trackid
LEFT JOIN albums AS al ON al.albumid = tr.albumid
LEFT JOIN artists AS ar ON ar.artistid = al.artistid
GROUP BY al.artistid, ar.name
ORDER BY total_tracks_sold DESC
LIMIT 3;