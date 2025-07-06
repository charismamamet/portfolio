SELECT 
	g.genreid, 
	g.name,
	tr_long.name as "longest_track_name",
	tr_long.t_max as "longest_track_duration",
	tr_short.name as "shortest_track_name",
	tr_short.t_min as "shortest_track_duration"
from genres as g

LEFT JOIN (
	select 
		genreid,
		name,
		milliseconds as "t_max"
	from tracks
	where (genreid, milliseconds) in (
		select genreid, max(milliseconds)
		from tracks
		group by genreid
		)
) AS tr_long
  ON tr_long.genreid = g.genreid

LEFT JOIN (
	select 
		genreid,
		name,
		milliseconds as "t_min"
	from tracks
	where (genreid, milliseconds) in (
		select genreid, min(milliseconds)
		from tracks
		group by genreid
		)
) AS tr_short
  ON tr_short.genreid = g.genreid
;