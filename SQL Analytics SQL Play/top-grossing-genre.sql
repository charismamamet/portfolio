select gn.Name as genre_name, sum(ii.Unitprice) as total_rev
from genres as gn
left join tracks as tr on tr.GenreId = gn.GenreId
left join invoice_items as ii on ii.TrackId = tr.TrackId
group by genre_name
order by total_rev desc;