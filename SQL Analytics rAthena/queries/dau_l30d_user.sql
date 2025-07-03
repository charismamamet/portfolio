select
	date(ll.time) as login_date, 
    ll.user, 
    count(user) as numOfLogin
from 
	new_rathena_db.loginlog as ll
where
	ll.log = 'login ok'
    AND
    not ll.user = 's1'
    AND
    not ll.user like '%admin%'
group by 
	ll.user, 
    login_date
order by 
	login_date desc
;
