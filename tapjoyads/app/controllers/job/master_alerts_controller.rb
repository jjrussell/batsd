class Job::MasterAlertsController < Job::JobController
  def index
    alerts = [
      {
        :message => "Fill rate for display ads",
        :recipients => [ 'aaron@tapjoy.com', 'chris.compeau@tapjoy.com', 'phil.oneill@tapjoy.com', 'sf_devrel@tapjoy.com' ],
        :query => "select r.app_id, r.app_name, r.app_platform, r.acct_mgr, sum(q.display_ad_requested) as display_ad_requested, sum(q.display_ad_shown) as display_ad_shown, case when sum(q.display_ad_requested) > 0 then sum(q.display_ad_shown) / sum(q.display_ad_requested) else 0 end as fill_rate from ( select app_id, cast(sum(case when path like '%display_ad_requested%' then 1 else 0 end) as numeric) as display_ad_requested, cast(sum(case when path like '%display_ad_shown%' then 1 else 0 end) as numeric) as display_ad_shown from analytics.views where etl_day >= to_char(date(sysdate) - 1) and time between sysdate - interval '1 hour' and sysdate group by 1 ) q inner join ( select ap.app_id, ap.app_name, ap.app_platform, pam.acct_mgr from ( select app_id, app_name, app_platform, partner_id from analytics.apps_partners ) ap inner join ( select partner_id, acct_mgr from analytics.partner_acct_mgr ) pam on ap.partner_id = pam.partner_id ) r on q.app_id = r.app_id group by 1, 2, 3, 4 having case when sum(q.display_ad_requested) > 0 then sum(q.display_ad_shown) / sum(q.display_ad_requested) else 0 end < .5 and sum(q.display_ad_shown) > 0 and sum(q.display_ad_requested) > 100 order by 7",
        :fields => %w( app_id app_name app_platform acct_mgr display_ad_requested display_ad_shown fill_rate ),
        :recipients_field => :acct_mgr,
      },
      {
        :message => "Fill rate for featured ads",
        :recipients => [ 'aaron@tapjoy.com', 'chris.compeau@tapjoy.com', 'phil.oneill@tapjoy.com', 'sf_devrel@tapjoy.com' ],
        :query => "select r.app_id, r.app_name, r.app_platform, r.acct_mgr, sum(q.featured_offer_requested) as featured_ad_requested, sum(q.featured_offer_shown) as featured_ad_shown, case when sum(q.featured_offer_requested) > 0 then sum(q.featured_offer_shown) / sum(q.featured_offer_requested) else 0 end as fill_rate from ( select app_id, cast(sum(case when path like '%featured_offer_requested%' then 1 else 0 end) as numeric) as featured_offer_requested, cast(sum(case when path like '%featured_offer_shown%' then 1 else 0 end) as numeric) as featured_offer_shown from analytics.views where etl_day >= to_char(date(sysdate) - 1) and time between sysdate - interval '1 hour' and sysdate group by 1 ) q inner join ( select ap.app_id, ap.app_name, ap.app_platform, pam.acct_mgr from ( select app_id, app_name, app_platform, partner_id from analytics.apps_partners ) ap inner join ( select partner_id, acct_mgr from analytics.partner_acct_mgr ) pam on ap.partner_id = pam.partner_id ) r on q.app_id = r.app_id group by 1, 2, 3, 4 having case when sum(q.featured_offer_requested) > 0 then sum(q.featured_offer_shown) / sum(q.featured_offer_requested) else 0 end < .5 and sum(q.featured_offer_shown) > 0 and sum(q.featured_offer_requested) > 100 order by 7",
        :fields => %w( app_id app_name app_platform acct_mgr featured_ad_requested featured_ad_shown fill_rate ),
        :recipients_field => :acct_mgr,
      },
      {
        :message => "Material Rev Drop App Platform",
        :recipients => [ 'aaron@tapjoy.com', 'chris.compeau@tapjoy.com', 'phil.oneill@tapjoy.com', 'sf_devrel@tapjoy.com' ],
        :query => "select a.app_id, app_name, app_platform, acct_mgr, hr1_UTC, hr2_UTC, -.01*gross_rev_hr1 as gross_rev_hr1, -.01*gross_rev_hr2 as gross_rev_hr2, -.01*(gross_rev_hr2 - gross_rev_hr1) as gross_rev_difference, concat(100*round((gross_rev_hr2/gross_rev_hr1)-1, 3.0),'%') as gross_rev_pct_difference, round(-.01*avg_5hr_rev, 2.0) as avg_5hr_rev, round(-.01*(gross_rev_hr2 - avg_5hr_rev), 2.0) as difference_from_avg, concat(100*round((gross_rev_hr2/avg_5hr_rev)-1, 3.0),'%') as pct_difference_from_avg from ( select publisher_app_id as app_id, advertiser_amount as gross_rev_hr2, hour as hr2_UTC, lag(hour) OVER (PARTITION BY publisher_app_id ORDER BY hour) as hr1_UTC, lag(advertiser_amount) OVER (PARTITION BY publisher_app_id ORDER BY hour)::NUMERIC as gross_rev_hr1, zeroifnull(avg(advertiser_amount) OVER (PARTITION BY publisher_app_id ORDER BY hour RANGE BETWEEN interval '5 hours' PRECEDING AND interval '1 hour' PRECEDING))::NUMERIC as avg_5hr_rev from ( select publisher_app_id, date_trunc('hour',time) as hour, sum(advertiser_amount) as advertiser_amount from analytics.actions where etl_day >= to_char(date(sysdate) - 1) and time between sysdate - interval '7 hours' and sysdate group by 1, 2 ) q group by 1, 2, 3 ) a inner join ( select ap.app_id, app_name, ap.partner_id, partner_name, app_platform, acct_mgr from analytics.apps_partners ap inner join analytics.partner_acct_mgr pam on ap.partner_id = pam.partner_id ) b on a.app_id = b.app_id where hr1_UTC = date_trunc('hour',sysdate - interval '3 hours') and -.01*(gross_rev_hr2 - gross_rev_hr1) < -100 and (gross_rev_hr2/gross_rev_hr1)-1 < -.7",
        :fields => %w( app_id app_name app_platform acct_mgr hr1_UTC hr2_UTC gross_rev_hr1 gross_rev_hr2 gross_rev_difference gross_rev_pct_difference avg_5hr_rev difference_from_avg pct_difference_from_avg),
        :recipients_field => :acct_mgr,
      },
      {
        :message => "Material Rev Drop Format Placement",
        :recipients => [ 'aaron@tapjoy.com', 'chris.compeau@tapjoy.com', 'phil.oneill@tapjoy.com', 'sf_devrel@tapjoy.com' ],
        :query => "select case when b.app_platform = 'android' and a.source = 'offerwall' then 'Android In-App Offerwall' when b.app_platform = 'android' and a.source = 'display_ad' then 'Android Display' when b.app_platform = 'android' and a.source = 'featured' then 'Android Featured' when b.app_platform = 'iphone' and a.source = 'offerwall' then 'iOS In-App Offerwall' when b.app_platform = 'iphone' and a.source = 'display_ad' then 'iOS Display' when b.app_platform = 'iphone' and a.source = 'featured' then 'iOS Featured' when a.source = 'tj_games' then 'tapjoy.com' else 'Other' end as source_platform, case when a.type in ('action','featured_action','tjm_action') then 'CPE' when a.type in ('generic', 'featured_generic','tjm_generic') then 'CPA' when a.type in ('install', 'install_jailbroken','featured_install','featured_install_jailbroken','tjm_install_jailbroken') then 'CPI' when a.type = 'video' then 'CPV' when a.type = 'deeplink' then 'Deeplink' else 'Other' end as type, trunc(sysdate - interval '3 hour', 'hh') as hr1_UTC, trunc(sysdate - interval '2 hour', 'hh') as hr2_UTC, -.01*sum(a.gross_revenue_hr1) as gross_revenue_hr1, -.01*sum(a.gross_revenue_hr2) as gross_revenue_hr2, -.01*(sum(a.gross_revenue_hr2) - sum(a.gross_revenue_hr1)) as gross_rev_difference, case when sum(a.gross_revenue_hr1) = 0 then 0 else ((sum(a.gross_revenue_hr2)/sum(a.gross_revenue_hr1))-1) end as gross_rev_pct_difference from ( select publisher_app_id, source, type, cast(sum(case when time between sysdate - interval '2 hour' and sysdate - interval '1 hour' then advertiser_amount else 0 end) as numeric) as gross_revenue_hr2, cast(sum(case when time between sysdate - interval '3 hour' and sysdate - interval '2 hour' then advertiser_amount else 0 end) as numeric) as gross_revenue_hr1 from analytics.actions where etl_day >= to_char(date(sysdate) - 1) and time between sysdate - interval '3 hour' and sysdate - interval '1 hour' group by 1, 2, 3 ) a inner join ( select ap.app_id, ap.app_name, ap.app_platform, ap.partner_id, pam.acct_mgr from ( select app_id, app_name, app_platform, partner_id from analytics.apps_partners ) ap inner join ( select partner_id, acct_mgr from analytics.partner_acct_mgr ) pam on ap.partner_id = pam.partner_id ) b on a.publisher_app_id = b.app_id group by 1, 2, 3, 4 having -.01*(sum(a.gross_revenue_hr2)-sum(a.gross_revenue_hr1)) < -100 and (sum(a.gross_revenue_hr2)/sum(a.gross_revenue_hr1))-1 < -.7 order by 8",
        :fields => %w( source_platform type hr1_UTC hr2_UTC gross_revenue_hr1 gross_revenue_hr2 gross_rev_difference gross_rev_pct_difference ),
        :recipients_field => :acct_mgr,
      },
    ]

    vertica = VerticaCluster.get_connection

    alerts.each do |alert|
      begin
        rows = vertica.query(alert[:query]).rows
      rescue Vertica::Error::QueryError
        next
      end

      if rows.length > 0
        if alert[:recipients_field]
          direct_recipients = rows.collect {|row| row[alert[:recipients_field]] }.uniq

          direct_recipients.each do |recipient|
            TapjoyMailer.deliver_alert(alert, rows.reject {|row| row[alert[:recipients_field]] != recipient}, recipient)
          end
        else
          TapjoyMailer.deliver_alert(alert, rows, alert[:recipients])
        end
      end
    end

    render :text => 'ok'
  end
end
