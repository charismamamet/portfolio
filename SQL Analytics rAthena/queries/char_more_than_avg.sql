WITH
	kepemilikanChar as (
        select
			c.account_id,
   			l.userid,
    		count(c.char_id) as numOfChar
		FROM
			new_rathena_db.char as c
		JOIN
			new_rathena_db.login as l
    		ON
    		l.account_id = c.account_id
		group BY
			c.account_id,
    		l.userid
		order BY
			c.zeny DESC
	),
    avgOwnedChar as (
        SELECT	
        	avg(numOfChar) as averageCharInAllAccount
        FROM
        	kepemilikanChar
	)
        
select
kpc.account_id,
    kpc.userid,
    kpc.numOfChar,
    aoc.averageCharInAllAccount
FROM
	kepemilikanChar as kpc
CROSS JOIN
	avgOwnedChar as aoc
WHERE
	kpc.numOfChar >= aoc.averageCharInAllAccount
group BY
	kpc.account_id,
    kpc.userid
order BY
	kpc.numOfChar DESC
	;
