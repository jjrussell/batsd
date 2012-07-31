class Job::MasterAlertsController < Job::JobController
  def index
    alerts = [
      {
        :message => "Fill rate for display ads",
        :recipients => [ 'aaron@tapjoy.com', 'chris.compeau@tapjoy.com', 'phil.oneill@tapjoy.com', 'sf_devrel@tapjoy.com' ],
        :query => "select r.app_id, r.app_name, r.app_platform, r.acct_mgr, sum(q.display_ad_requested) as display_ad_requested, sum(q.display_ad_shown) as display_ad_shown, case when sum(q.display_ad_requested) > 0 then sum(q.display_ad_shown) / sum(q.display_ad_requested) else 0 end as fill_rate from ( select app_id, cast(sum(case when path like '%display_ad_requested%' then 1 else 0 end) as numeric) as display_ad_requested, cast(sum(case when path like '%display_ad_shown%' then 1 else 0 end) as numeric) as display_ad_shown from analytics.views where etl_day >= to_char(date(sysdate) - 1) and time between sysdate - interval '1 hour' and sysdate group by 1 ) q inner join ( select ap.app_id, ap.app_name, ap.app_platform, pam.acct_mgr from ( select app_id, app_name, app_platform, partner_id from analytics.apps_partners ) ap inner join ( select partner_id, acct_mgr from analytics.partner_acct_mgr ) pam on ap.partner_id = pam.partner_id ) r on q.app_id = r.app_id group by 1, 2, 3, 4 having case when sum(q.display_ad_requested) > 0 then sum(q.display_ad_shown) / sum(q.display_ad_requested) else 0 end < .9 and sum(q.display_ad_requested) > 100 order by 7",
        :fields => %w( app_id app_name app_platform acct_mgr display_ad_requested display_ad_shown fill_rate ),
      },
      {
        :message => "Fill rate for featured ads",
        :recipients => [ 'aaron@tapjoy.com', 'chris.compeau@tapjoy.com', 'phil.oneill@tapjoy.com', 'sf_devrel@tapjoy.com' ],
        :query => "select r.app_id, r.app_name, r.app_platform, r.acct_mgr, sum(q.featured_offer_requested) as featured_ad_requested, sum(q.featured_offer_shown) as featured_ad_shown, case when sum(q.featured_offer_requested) > 0 then sum(q.featured_offer_shown) / sum(q.featured_offer_requested) else 0 end as fill_rate from ( select app_id, cast(sum(case when path like '%featured_offer_requested%' then 1 else 0 end) as numeric) as featured_offer_requested, cast(sum(case when path like '%featured_offer_shown%' then 1 else 0 end) as numeric) as featured_offer_shown from analytics.views where etl_day >= to_char(date(sysdate) - 1) and time between sysdate - interval '1 hour' and sysdate group by 1 ) q inner join ( select ap.app_id, ap.app_name, ap.app_platform, pam.acct_mgr from ( select app_id, app_name, app_platform, partner_id from analytics.apps_partners ) ap inner join ( select partner_id, acct_mgr from analytics.partner_acct_mgr ) pam on ap.partner_id = pam.partner_id ) r on q.app_id = r.app_id group by 1, 2, 3, 4 having case when sum(q.featured_offer_requested) > 0 then sum(q.featured_offer_shown) / sum(q.featured_offer_requested) else 0 end < .9 and sum(q.featured_offer_requested) > 100 order by 7",
        :fields => %w( app_id app_name app_platform acct_mgr featured_ad_requested featured_ad_shown fill_rate ),
      },
      {
        :message => "Material Rev Drop App Platform",
        :recipients => [ 'aaron@tapjoy.com', 'chris.compeau@tapjoy.com', 'phil.oneill@tapjoy.com', 'sf_devrel@tapjoy.com' ],
        :query => "select a.publisher_app_id as app_id, b.app_name, b.app_platform, b.acct_mgr, trunc(sysdate - interval '3 hour', 'hh') as hr1_UTC, trunc(sysdate - interval '2 hour', 'hh') as hr2_UTC, -.01*a.gross_rev_hr1 as gross_rev_hr1, -.01*a.gross_rev_hr2 as gross_rev_hr2, -.01*(a.gross_rev_hr2 - a.gross_rev_hr1) as gross_rev_difference, case when a.gross_rev_hr1 = 0 then NULL else ((a.gross_rev_hr2/a.gross_rev_hr1)-1) end as gross_rev_pct_difference from ( select publisher_app_id, cast(sum(case when time between sysdate - interval '2 hour' and sysdate - interval '1 hour' then advertiser_amount else 0 end) as numeric) as gross_rev_hr2, cast(sum(case when time between sysdate - interval '3 hour' and sysdate - interval '2 hour' then advertiser_amount else 0 end) as numeric) as gross_rev_hr1 from analytics.actions where etl_day >= to_char(date(sysdate) - 1) and time between sysdate - interval '3 hour' and sysdate - interval '1 hour' group by 1 ) a inner join ( select ap.app_id, ap.app_name, ap.app_platform, pam.acct_mgr from ( select app_id, app_name, app_platform, partner_id from analytics.apps_partners ) ap inner join ( select partner_id, acct_mgr from analytics.partner_acct_mgr ) pam on ap.partner_id = pam.partner_id ) b on a.publisher_app_id = b.app_id where -.01*(a.gross_rev_hr2 - a.gross_rev_hr1) < -100 and ((a.gross_rev_hr2/a.gross_rev_hr1)-1) < -.7 order by 8",
        :fields => %w( app_id app_name app_platform acct_mgr hr1_UTC hr2_UTC gross_rev_hr1 gross_rev_hour2 gross_rev_difference gross_rev_pct_difference ),
      },
      {
        :message => "Material Rev Drop Format Placement",
        :recipients => [ 'aaron@tapjoy.com', 'chris.compeau@tapjoy.com', 'phil.oneill@tapjoy.com', 'sf_devrel@tapjoy.com' ],
        :query => "select case when b.app_platform = 'android' and a.source = 'offerwall' then 'Android In-App Offerwall' when b.app_platform = 'android' and a.source = 'display_ad' then 'Android Display' when b.app_platform = 'android' and a.source = 'featured' then 'Android Featured' when b.app_platform = 'iphone' and a.source = 'offerwall' then 'iOS In-App Offerwall' when b.app_platform = 'iphone' and a.source = 'display_ad' then 'iOS Display' when b.app_platform = 'iphone' and a.source = 'featured' then 'iOS Featured' when a.source = 'tj_games' then 'tapjoy.com' else 'Other' end as source_platform, case when a.type in ('action','featured_action','tjm_action') then 'CPE' when a.type in ('generic', 'featured_generic','tjm_generic') then 'CPA' when a.type in ('install', 'install_jailbroken','featured_install','featured_install_jailbroken','tjm_install_jailbroken') then 'CPI' when a.type = 'video' then 'CPV' when a.type = 'deeplink' then 'Deeplink' else 'Other' end as type, trunc(sysdate - interval '3 hour', 'hh') as hr1_UTC, trunc(sysdate - interval '2 hour', 'hh') as hr2_UTC, -.01*sum(a.gross_revenue_hr1) as gross_revenue_hr1, -.01*sum(a.gross_revenue_hr2) as gross_revenue_hr2, -.01*(sum(a.gross_revenue_hr2) - sum(a.gross_revenue_hr1)) as gross_rev_difference, case when sum(a.gross_revenue_hr1) = 0 then 0 else ((sum(a.gross_revenue_hr2)/sum(a.gross_revenue_hr1))-1) end as gross_rev_pct_difference from ( select publisher_app_id, source, type, cast(sum(case when time between sysdate - interval '2 hour' and sysdate - interval '1 hour' then advertiser_amount else 0 end) as numeric) as gross_revenue_hr2, cast(sum(case when time between sysdate - interval '3 hour' and sysdate - interval '2 hour' then advertiser_amount else 0 end) as numeric) as gross_revenue_hr1 from analytics.actions where etl_day >= to_char(date(sysdate) - 1) and time between sysdate - interval '3 hour' and sysdate - interval '1 hour' group by 1, 2, 3 ) a inner join ( select ap.app_id, ap.app_name, ap.app_platform, ap.partner_id, pam.acct_mgr from ( select app_id, app_name, app_platform, partner_id from analytics.apps_partners ) ap inner join ( select partner_id, acct_mgr from analytics.partner_acct_mgr ) pam on ap.partner_id = pam.partner_id ) b on a.publisher_app_id = b.app_id group by 1, 2, 3, 4 having -.01*(sum(a.gross_revenue_hr2)-sum(a.gross_revenue_hr1)) < -100 and (sum(a.gross_revenue_hr2)/sum(a.gross_revenue_hr1))-1 < -.7 order by 8",
        :fields => %w( source_platform type hr1_UTC hr2_UTC gross_revenue_hr1 gross_revenue_h2 gross_rev_difference gross_rev_pct_difference ),
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
        TapjoyMailer.deliver_alert(alert, rows)
      end
    end

    render :text => 'ok'
  end
end
