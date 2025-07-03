select
	c.char_id,
	c.account_id,
    c.name,
    l.userid,
    c.zeny
FROM
	new_rathena_db.char as c
JOIN
	new_rathena_db.login as l
    ON
    l.account_id = c.account_id
order BY
	c.zeny DESC
;
