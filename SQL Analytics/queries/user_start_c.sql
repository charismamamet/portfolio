select l.userid, l.sex, l.group_id, l.email
from new_rathena_db.login as l
where l.userid like "c%"
order by l.group_id desc
;
