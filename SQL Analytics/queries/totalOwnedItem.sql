WITH item_stats as (
	select 
		c.char_id,
    	c.name,
    	c.account_id, 
    	count(distinct i.nameid) as distinctOwnedItem, 
    	sum(i.amount) as totalOwnedItem
	from new_rathena_db.char as c
	left join new_rathena_db.inventory as i on i.char_id = c.char_id
	group by c.char_id
),
avg_stats as (
    SELECT
    	AVG(distinctOwnedItem) as avgItem
    from item_stats
),
avg_stats2 as (
    SELECT
    	avg(totalOwnedItem) as avgItem2
    from item_stats
)

select
	alif.char_id,
    alif.name,
    alif.account_id,
    alif.distinctOwnedItem,
    alif.totalOwnedItem,
    CASE
    	when alif.distinctOwnedItem > ba.avgItem then 'item collector'
        else 'casual player'
    end as playerItemStatus1,
    CASE
    	when alif.totalOwnedItem > ta.avgItem2 then 'item hoarder'
        else 'casual player'
    end as playerItemStatus2
from item_stats as alif
cross join avg_stats as ba
cross join avg_stats2 as ta
order by distinctOwnedItem DESC
;
