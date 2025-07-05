select al.albumid, al.title, count(tr.trackid) as num_of_tracks
from albums as al
left join tracks as tr on tr.albumid = al.albumid
group by al.albumid
order by num_of_tracks desc;