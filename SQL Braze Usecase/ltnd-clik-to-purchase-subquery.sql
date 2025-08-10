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
		concat(rpl2.user_id, '_', row_number() over (partition by rpl2.user_id order by cast(to_timestamp(rpl2.time) as DATE) asc)) as purchase_id, 
		cast(to_timestamp(rpl2.time) as DATE) as purchase_date,
		rpl2.user_id,
		rpl2.quantity,
		rpl2.total_paid
	from USERS_BEHAVIORS_PURCHASE_SHARED as rpl2
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
    			cl.click_date,
    			cl.medium,
            	datediff(pl.purchase_date, cl.click_date) as date_diff
			from (
    			-- step 1: create dummy purchaselog that has purchase_id
    			select
					concat(rpl.user_id, '_', row_number() over (partition by rpl.user_id order by cast(to_timestamp(rpl.time) as DATE) asc)) as purchase_id, 
					cast(to_timestamp(rpl.time) as DATE) as purchase_date,
					rpl.user_id,
					rpl.quantity,
					rpl.total_paid
				from USERS_BEHAVIORS_PURCHASE_SHARED as rpl
            	-- end of step 1
    			) as pl
			join (
				-- step 1.2: put all the click into one to make click_log as cl
				select
					cc.campaign_id,
					cc.user_id,
					cast(to_timestamp(cc.time) as date) as click_date,
					'content_card' as medium
				from USERS_MESSAGES_CONTENTCARD_CLICK_SHARED as cc

				union all

				select
					em.campaign_id,
					em.user_id,
					cast(to_timestamp(em.time) as date) as click_date,
					'email' as medium
				from USERS_MESSAGES_EMAIL_CLICK_SHARED as em

				union all

				select
					iam.campaign_id,
					iam.user_id,
					cast(to_timestamp(iam.time) as date) as click_date,
					'pop-up' as medium
				from USERS_MESSAGES_INAPPMESSAGE_CLICK_SHARED as iam

				union all

				select
					nfc.campaign_id,
					nfc.user_id,
					cast(to_timestamp(nfc.time) as date) as click_date,
					'news_feed_card' as medium
				from USERS_MESSAGES_NEWSFEEDCARD_CLICK_SHARED as nfc

				union all

				select
					sms.campaign_id,
					sms.user_id,
					cast(to_timestamp(sms.time) as date) as click_date,
					'sms' as medium
				from USERS_MESSAGES_SMS_SHORTLINKCLICK_SHARED as sms

				union all

				select
					pn.campaign_id,
					pn.user_id,
					cast(to_timestamp(pn.time) as date) as click_date,
					'push' as medium
				from USERS_MESSAGES_PUSHNOTIFICATION_OPEN_SHARED as pn
				-- end of step 1.2
				) as cl on cl.user_id = pl.user_id
			where 1
				and pl.purchase_date >= cl.click_date 
    			and abs(datediff(pl.purchase_date, cl.click_date)) <= 30
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