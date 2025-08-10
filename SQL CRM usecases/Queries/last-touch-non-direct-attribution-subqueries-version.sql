-- step 6: create overall table that has crm attributed purchase and organic purchase
select 
	ori_purchase_log.*,
    case 
    	when ltnd.campaign_id is null
        	or ltnd.campaign_id = ''
		then 'organic'
        else ltnd.campaign_id
	end as campaign_id,
    case 
    	when ltnd.medium is null
        	or ltnd.medium = ''
		then 'direct'
        else ltnd.medium
	end as campaign_medium,
    ltnd.click_date,
    ltnd.date_diff
from (
    -- step 5: recreate the purchase_log that has purchase_id
    select
		concat(rpl2.user_id, '_', row_number() over (partition by rpl2.user_id order by rpl2.time asc)) as purchase_id, 
		cast(rpl2.time as DATE) as purchase_date,
		rpl2.user_id,
		rpl2.quantity,
		rpl2.total_paid
	from mock_braze.raw_purchase_log as rpl2
    -- end of step 5
    ) as ori_purchase_log
left join (
	-- step 4: pick only rn = 1
	select 
		arranged_click.*
	from (
		-- step 3: add rn as identifier
		select 
			clicks_before_purchase.*,
    		row_number() over (partition by clicks_before_purchase.purchase_id order by clicks_before_purchase.click_date desc) as rn
		from (
    		-- step 2: combine click log and purchase log, but only get click log within 30 days
			select
				pl.*,
    			cl.campaign_id,
    			cast(cl.time as date) as click_date,
    			cl.medium,
            	datediff(pl.purchase_date, cast(cl.time as date)) as date_diff
			from (
    			-- step 1: create dummy purchaselog that has purchase_id
    			select
					concat(rpl.user_id, '_', row_number() over (partition by rpl.user_id order by rpl.time asc)) as purchase_id, 
					cast(rpl.time as DATE) as purchase_date,
					rpl.user_id,
					rpl.quantity,
					rpl.total_paid
				from mock_braze.raw_purchase_log as rpl
            	-- end of step 1
    			) as pl
			join mock_braze.click_log as cl on cl.user_id = pl.user_id
			where 1
				and pl.purchase_date >= cl.time 
    			and datediff(pl.purchase_date, cl.time) <= 30
        	-- end of step 2
    		) as clicks_before_purchase
    	-- end of step 3
    	) as arranged_click
	where 1
		and rn = 1
	-- end of step 4
    ) as ltnd on ltnd.purchase_id = ori_purchase_log.purchase_id
where 1
order by ori_purchase_log.purchase_date asc
;