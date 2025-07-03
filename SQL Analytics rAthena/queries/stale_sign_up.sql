select l.userid, l.sex, l.group_id, l.email, l.lastlogin, l.logincount
from new_rathena_db.login as l
where
	l.lastlogin <= now() - interval 90 day
    OR
    l.lastlogin is null
group by
	l.userid
order by l.group_id desc
;
