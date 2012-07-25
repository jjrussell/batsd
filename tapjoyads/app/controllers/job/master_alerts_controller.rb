class Job::MasterAlertsController < Job::JobController
  def index
    alerts = [
      {
        :message => "Fill rate for display ads",
        :query => "select r.app_id, r.app_name, r.app_platform, r.acct_mgr, sum(q.display_ad_requested) as display_ad_requested, sum(q.display_ad_shown) as display_ad_shown, case when sum(q.display_ad_requested) > 0 then sum(q.display_ad_shown) / sum(q.display_ad_requested) else NULL end as fill_rate from ( select app_id, cast(sum(case when path like '%display_ad_requested%' then 1 else 0 end) as numeric) as display_ad_requested, cast(sum(case when path like '%display_ad_shown%' then 1 else 0 end) as numeric) as display_ad_shown from analytics.views where etl_day >= to_char(date(sysdate) - 1) and time between sysdate - interval '1 hour' and sysdate group by 1 ) q left join ( select ap.app_id, ap.app_name, ap.app_platform, pam.acct_mgr from ( select app_id, app_name, app_platform, partner_id from analytics.apps_partners ) ap inner join ( select partner_id, acct_mgr from analytics.partner_acct_mgr ) pam on ap.partner_id = pam.partner_id ) r on q.app_id = r.app_id group by 1, 2, 3, 4 having case when sum(q.display_ad_requested) > 0 then sum(q.display_ad_shown) / sum(q.display_ad_requested) else NULL end < .9 and sum(q.display_ad_requested) > 100"
      },
      {
        :message => "Fill rate for featured ads",
        :query => "select r.app_id, r.app_name, r.app_platform, r.acct_mgr, sum(q.featured_offer_requested) as featured_ad_requested, sum(q.featured_offer_shown) as featured_ad_shown, case when sum(q.featured_offer_requested) > 0 then sum(q.featured_offer_shown) / sum(q.featured_offer_requested) else NULL end as fill_rate from ( select app_id, cast(sum(case when path like '%featured_offer_requested%' then 1 else 0 end) as numeric) as featured_offer_requested, cast(sum(case when path like '%featured_offer_shown%' then 1 else 0 end) as numeric) as featured_offer_shown from analytics.views where etl_day >= to_char(date(sysdate) - 1) and time between sysdate - interval '1 hour' and sysdate group by 1 ) q left join ( select ap.app_id, ap.app_name, ap.app_platform, pam.acct_mgr from ( select app_id, app_name, app_platform, partner_id from analytics.apps_partners ) ap inner join ( select partner_id, acct_mgr from analytics.partner_acct_mgr ) pam on ap.partner_id = pam.partner_id ) r on q.app_id = r.app_id group by 1, 2, 3, 4 having case when sum(q.featured_offer_requested) > 0 then sum(q.featured_offer_shown) / sum(q.featured_offer_requested) else NULL end < .9 and sum(q.featured_offer_requested) > 100"
      },
      {
        :message => "Material Rev Drop App Platform",
        :query => "select sysdate as timestamp, a.publisher_app_id, b.app_name, b.app_platform, b.acct_mgr, -.01*a.GR_hr1 as gross_rev_hr1, -.01*a.GR_hr2 as gross_rev_hr2, -.01*(a.GR_hr1 - a.GR_hr2) as gross_rev_delta, case when a.GR_hr2 = 0 then NULL else ((a.GR_hr1/a.GR_hr2)-1) end as gross_rev_pct_change from ( select publisher_app_id, cast(sum(case when time between sysdate - interval '2 hour' and sysdate - interval '1 hour' then advertiser_amount else 0 end) as numeric) as gross_rev_hr1, cast(sum(case when time between sysdate - interval '3 hour' and sysdate - interval '2 hour' then advertiser_amount else 0 end) as numeric) as gross_rev_hr2 from analytics.actions where etl_day >= to_char(date(sysdate) - 1) and time between sysdate - interval '3 hour' and sysdate - interval '1 hour' group by 1 ) a left join ( select ap.app_id, ap.app_name, ap.app_platform, pam.acct_mgr from ( select app_id, app_name, app_platform, partner_id from analytics.apps_partners ) ap inner join ( select partner_id, acct_mgr from analytics.partner_acct_mgr ) pam on ap.partner_id = pam.partner_id ) b on a.publisher_app_id = b.app_id where -.01*(a.GR_hr1 - a.GR_hr2) < -100 and ((a.GR_hr1/a.GR_hr2)-1) < -.7 order by 8  "
      },
      {
        :message => "Material Rev Drop Format Placement",
        :query => "select sysdate as timestamp, a.publisher_app_id, b.app_name, b.acct_mgr, case when b.app_platform = 'android' and a.source = 'offerwall' then 'android_in_app' when b.app_platform = 'android' and a.source = 'display_ad' then 'android_display' when b.app_platform = 'android' and a.source = 'featured' then 'android_featured' when b.app_platform = 'android' and a.source = 'video' then 'android_video' when b.app_platform = 'iphone' and a.source = 'offerwall' then 'ios_in_app' when b.app_platform = 'iphone' and a.source = 'display_ad' then 'ios_display' when b.app_platform = 'iphone' and a.source = 'featured' then 'ios_in_app' when b.app_platform = 'iphone' and a.source = 'video' then 'ios_video' when a.source = 'tj_games' then 'tjm' else 'other' end as network, c.item_type, -.01*sum(a.GR_hr1) as GR_hr1, -.01*sum(a.GR_hr2) as GR_hr2, -.01*(sum(a.GR_hr1) - sum(a.GR_hr2)) as GR_delta, case when sum(a.GR_hr2) = 0 then NULL else ((sum(a.GR_hr1)/sum(a.GR_hr2))-1) end as GR_pct_change from ( select publisher_app_id, offer_id, source, cast(sum(case when time between sysdate - interval '2 hour' and sysdate - interval '1 hour' then advertiser_amount else 0 end) as numeric) as GR_hr1, cast(sum(case when time between sysdate - interval '3 hour' and sysdate - interval '2 hour' then advertiser_amount else 0 end) as numeric) as GR_hr2 from analytics.actions where etl_day >= to_char(date(sysdate) - 1) and time between sysdate - interval '3 hour' and sysdate - interval '1 hour' group by 1, 2, 3 ) a left join ( select ap.app_id, ap.app_name, ap.app_platform, ap.partner_id, pam.acct_mgr from ( select app_id, app_name, app_platform, partner_id from analytics.apps_partners ) ap inner join ( select partner_id, acct_mgr from analytics.partner_acct_mgr ) pam on ap.partner_id = pam.partner_id ) b on a.publisher_app_id = b.app_id left join ( select offer_id, item_type from analytics.offers_partners ) c on a.offer_id = c.offer_id group by 1, 2, 3, 4, 5, 6 having -.01*(sum(a.GR_hr1) - sum(a.GR_hr2)) < -100 and ( sum(a.GR_hr1)/sum(a.GR_hr2) ) - 1 < -.7 order by 6, 7"
      }
    ]

    vertica = VerticaCluster.get_connection

    alerts.each do |alert|
      begin
        rows = vertica.query(alert[:query]).rows
      rescue Vertica::Error::QueryError
        next
      end

      if rows.length > 0
        TapjoyMailer.deliver_alert(alert[:message], rows)
      end
    end

    render :text => 'ok'
  end
end
