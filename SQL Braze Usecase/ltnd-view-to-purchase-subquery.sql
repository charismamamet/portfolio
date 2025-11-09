-- step 6: create overall table that has crm attributed purchase and organic purchase
select 
	ori_purchase_log.id as purchase_id,
	ori_purchase_log.external_user_id as user_id,
	from_unixtime(ori_purchase_log.time) as purchase_date,
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
    ltnd.view_date,
    ltnd.date_diff
from USERS_BEHAVIORS_PURCHASE_SHARED as ori_purchase_log
left join (
	-- step 4: pick only rn = 1
	select 
		arranged_click.*
	from (
		-- step 3: add rn as identifier
		select 
			clicks_before_purchase.*,
    		row_number() over (partition by clicks_before_purchase.purchase_id order by clicks_before_purchase.view_date desc) as rn
		from (
    		-- step 2: combine click log and purchase log, but only get click log within 30 days
			select
				pl.id as purchase_id,
				pl.external_user_id,
				from_unixtime(pl.time) as purchase_date,
    			cl.campaign_id,
    			cl.view_date,
    			cl.medium,
            	datediff(from_unixtime(pl.time), cl.view_date) as date_diff
			from USERS_BEHAVIORS_PURCHASE_SHARED as pl				
			inner join (
				-- step 1.2: put all the click into one to make click_log as cl
				SELECT
					ban.campaign_id,
					ban.external_user_id,
					from_unixtime(ban.time) AS view_date,
					'banner' AS medium
				FROM USERS_MESSAGES_BANNER_IMPRESSION_SHARED AS ban

					UNION ALL

				SELECT
					iam.campaign_id,
					iam.external_user_id,
					from_unixtime(iam.time) AS view_date,
					'pop-up' AS medium
				FROM USERS_MESSAGES_INAPPMESSAGE_IMPRESSION_SHARED AS iam

				UNION ALL

				SELECT
					pn.campaign_id,
					pn.external_user_id,
					from_unixtime(pn.time) AS view_date,
					'push' AS medium
				FROM USERS_MESSAGES_PUSHNOTIFICATION_SEND_SHARED AS pn

				UNION ALL

				SELECT
					em.campaign_id,
					em.external_user_id,
					from_unixtime(em.time) AS view_date,
					'email' AS medium
				FROM USERS_MESSAGES_EMAIL_DELIVERY_SHARED AS em

				UNION ALL

				SELECT
					wa.campaign_id,
					wa.external_user_id,
					from_unixtime(wa.time) AS view_date,
					'whatsapp' AS medium
				FROM USERS_MESSAGES_WHATSAPP_DELIVERY_SHARED AS wa
				-- end of step 1.2
				) as cl on cl.external_user_id = pl.external_user_id				
			where 1
				and from_unixtime(pl.time) >= cl.view_date 
    			and abs(datediff(from_unixtime(pl.time), cl.view_date)) <= 30
        	-- end of step 2
    		) as clicks_before_purchase
    	-- end of step 3
    	) as arranged_click
	where 1
		and rn = 1
	-- end of step 4
    ) as ltnd on ltnd.purchase_id = ori_purchase_log.id
where 1
order by view_date desc
;