SELECT 
  art.Name as "artist", 
  alb.Title as "album",
  trc.name as "song",
  gen.name as "aliran"
from 
  artists as art
left join 
  albums as alb on alb.Artistid = art.Artistid
left join
  tracks as trc on trc.Albumid = alb.Albumid
left join
  genres as gen on gen.Genreid = trc.Genreid
where
 Aliran = "Rock"
order by Artist asc
;