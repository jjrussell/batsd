class Job::MasterAlertsController < Job::JobController
  def index
    alerts = [
      {
        :message => "Fill rate for display ads",
        :query => "select b.*, sum(a.display_ad_requested) as display_ad_requested, sum(a.display_ad_shown) as display_ad_shown, case when sum(a.display_ad_requested) > 0 then sum(a.display_ad_shown) / sum(a.display_ad_requested) else NULL end as display_FR from ( select app_id, cast(sum(case when path like '%display_ad_requested%' then 1 else 0 end) as numeric) as display_ad_requested, cast(sum(case when path like '%display_ad_shown%' then 1 else 0 end) as numeric) as display_ad_shown from analytics.views where etl_day >= to_char(date(sysdate) - 1) and time between sysdate - interval '1 hour' and sysdate group by 1 ) a left join ( select app_id, app_name, app_platform, sales_rep_email as acct_mgr_email, sales_rep_id as acct_mgr_id from analytics.apps_partners ) b on a.app_id = b.app_id group by 1, 2, 3, 4, 5"
      },
      {
        :message => "Fill rate for featured ads",
        :query => "select b.*, sum(a.featured_offer_requested) as featured_ad_requested, sum(a.featured_offer_shown) as featured_ad_shown, case when sum(a.featured_offer_requested) > 0 then sum(a.featured_offer_shown) / sum(a.featured_offer_requested) else NULL end as featured_FR from ( select app_id, cast(sum(case when path like '%featured_offer_requested%' then 1 else 0 end) as numeric) as featured_offer_requested, cast(sum(case when path like '%featured_offer_shown%' then 1 else 0 end) as numeric) as featured_offer_shown from analytics.views where etl_day >= to_char(date(sysdate) - 1) and time between sysdate - interval '1 hour' and sysdate group by 1 ) a left join ( select app_id, app_name, app_platform, sales_rep_email as acct_mgr_email, sales_rep_id as acct_mgr_id from analytics.apps_partners ) b on a.app_id = b.app_id group by 1, 2, 3, 4, 5"
      },
      {
        :message => "Material Rev Drop App Platform (1 Hour)",
        :query => "select sysdate as timestamp, b.*, -.01*a.GR_hr0 as GR_hr0, -.01*a.GR_hr1 as GR_hr1, -.01*(a.GR_hr0 - a.GR_hr1) as GR_delta, case when a.GR_hr1 = 0 then NULL else ((a.GR_hr0/a.GR_hr1)-1) end as GR_pct_change from ( select publisher_app_id, cast(sum(case when time between sysdate - interval '1 hour' and sysdate then advertiser_amount else 0 end) as numeric) as GR_hr0, cast(sum(case when time between sysdate - interval '2 hour' and sysdate - interval '1 hour' then advertiser_amount else 0 end) as numeric) as GR_hr1 from analytics.actions where etl_day >= to_char(date(sysdate) - 1) and time between sysdate - interval '2 hour' and sysdate group by 1 ) a left join ( select app_id, app_name, app_platform, sales_rep_email as acct_mgr_email, sales_rep_id as acct_mgr_id from analytics.apps_partners ) b on a.publisher_app_id = b.app_id where -.01*(a.GR_hr0 - a.GR_hr1) < -100 and ((a.GR_hr0/a.GR_hr1)-1) < -.7 order by 8"
      },
      {
        :message => "Material Rev Drop App Platform (2 Hour)",
        :query => "select sysdate as timestamp, b.*, -.01*a.GR_hr1 as GR_hr1, -.01*a.GR_hr2 as GR_hr2, -.01*(a.GR_hr1 - a.GR_hr2) as GR_delta, case when a.GR_hr2 = 0 then NULL else ((a.GR_hr1/a.GR_hr2)-1) end as GR_pct_change from ( select publisher_app_id, cast(sum(case when time between sysdate - interval '2 hour' and sysdate - interval '1 hour' then advertiser_amount else 0 end) as numeric) as GR_hr1, cast(sum(case when time between sysdate - interval '3 hour' and sysdate - interval '2 hour' then advertiser_amount else 0 end) as numeric) as GR_hr2 from analytics.actions where etl_day >= to_char(date(sysdate) - 1) and time between sysdate - interval '3 hour' and sysdate - interval '1 hour' group by 1 ) a left join ( select app_id, app_name, app_platform, sales_rep_email as acct_mgr_email, sales_rep_id as acct_mgr_id from analytics.apps_partners ) b on a.publisher_app_id = b.app_id where -.01*(a.GR_hr1 - a.GR_hr2) < -100 and ((a.GR_hr1/a.GR_hr2)-1) < -.7 order by 8"
      },
      {
        :message => "Material Rev Drop App Platform (3 Hour)",
        :query => "select sysdate as timestamp, b.*, -.01*a.GR_hr2 as GR_hr2, -.01*a.GR_hr3 as GR_hr3, -.01*(a.GR_hr2 - a.GR_hr3) as GR_delta, case when a.GR_hr3 = 0 then NULL else ((a.GR_hr2/a.GR_hr3)-1) end as GR_pct_change from ( select publisher_app_id, cast(sum(case when time between sysdate - interval '3 hour' and sysdate - interval '2 hour' then advertiser_amount else 0 end) as numeric) as GR_hr2, cast(sum(case when time between sysdate - interval '4 hour' and sysdate - interval '3 hour' then advertiser_amount else 0 end) as numeric) as GR_hr3 from analytics.actions where etl_day >= to_char(date(sysdate) - 1) and time between sysdate - interval '4 hour' and sysdate - interval '2 hour' group by 1 ) a left join ( select app_id, app_name, app_platform, sales_rep_email as acct_mgr_email, sales_rep_id as acct_mgr_id from analytics.apps_partners ) b on a.publisher_app_id = b.app_id where -.01*(a.GR_hr2 - a.GR_hr3) < -100 and ((a.GR_hr2/a.GR_hr3)-1) < -.7 order by 8"
      },
      {
        :message => "Material Rev Drop App Platform (4 Hour)",
        :query => "select sysdate as timestamp, b.*, -.01*a.GR_hr3 as GR_hr3, -.01*a.GR_hr4 as GR_hr4, -.01*(a.GR_hr3 - a.GR_hr4) as GR_delta, case when a.GR_hr4 = 0 then NULL else ((a.GR_hr3/a.GR_hr4)-1) end as GR_pct_change from ( select publisher_app_id, cast(sum(case when time between sysdate - interval '4 hour' and sysdate - interval '3 hour' then advertiser_amount else 0 end) as numeric) as GR_hr3, cast(sum(case when time between sysdate - interval '5 hour' and sysdate - interval '4 hour' then advertiser_amount else 0 end) as numeric) as GR_hr4 from analytics.actions where etl_day >= to_char(date(sysdate) - 1) and time between sysdate - interval '5 hour' and sysdate - interval '3 hour' group by 1 ) a left join ( select app_id, app_name, app_platform, sales_rep_email as acct_mgr_email, sales_rep_id as acct_mgr_id from analytics.apps_partners ) b on a.publisher_app_id = b.app_id where -.01*(a.GR_hr3 - a.GR_hr4) < -100 and ((a.GR_hr3/a.GR_hr4)-1) < -.7 order by 8"
      },
      {
        :message => "Material Rev Drop Format Placement (1 Hour)",
        :query => "select sysdate as timestamp, b.app_id, b.app_name, b.acct_mgr_email, b.acct_mgr_id, case when b.app_platform = 'android' and a.source = 'offerwall' then 'android_in_app' when b.app_platform = 'android' and a.source = 'display_ad' then 'android_display' when b.app_platform = 'android' and a.source = 'featured' then 'android_featured' when b.app_platform = 'android' and a.source = 'video' then 'android_video' when b.app_platform = 'iphone' and a.source = 'offerwall' then 'ios_in_app' when b.app_platform = 'iphone' and a.source = 'display_ad' then 'ios_display' when b.app_platform = 'iphone' and a.source = 'featured' then 'ios_in_app' when b.app_platform = 'iphone' and a.source = 'video' then 'ios_video' when a.source = 'tj_games' then 'tjm' else 'other' end as network, c.item_type, -.01*sum(a.GR_hr0) as GR_hr0, -.01*sum(a.GR_hr1) as GR_hr1, -.01*(sum(a.GR_hr0) - sum(a.GR_hr1)) as GR_delta, case when sum(a.GR_hr1) = 0 then NULL else ((sum(a.GR_hr0)/sum(a.GR_hr1))-1) end as GR_pct_change from ( select publisher_app_id, offer_id, source, cast(sum(case when time between sysdate - interval '1 hour' and sysdate then advertiser_amount else 0 end) as numeric) as GR_hr0, cast(sum(case when time between sysdate - interval '2 hour' and sysdate - interval '1 hour' then advertiser_amount else 0 end) as numeric) as GR_hr1 from analytics.actions where etl_day >= to_char(date(sysdate) - 1) and time between sysdate - interval '2 hour' and sysdate group by 1, 2, 3 ) a left join ( select app_id, app_name, app_platform, sales_rep_email as acct_mgr_email, sales_rep_id as acct_mgr_id from analytics.apps_partners ) b on a.publisher_app_id = b.app_id left join ( select offer_id, item_type from analytics.offers_partners ) c on a.offer_id = c.offer_id group by 1, 2, 3, 4, 5, 6, 7 having -.01*(sum(a.GR_hr0) - sum(a.GR_hr1)) < -100 and ( sum(a.GR_hr0)/sum(a.GR_hr1) ) - 1 < -.7 order by 6, 7"
      },
      {
        :message => "Material Rev Drop Format Placement (2 Hour)",
        :query => "select sysdate as timestamp, b.app_id, b.app_name, b.acct_mgr_email, b.acct_mgr_id, case when b.app_platform = 'android' and a.source = 'offerwall' then 'android_in_app' when b.app_platform = 'android' and a.source = 'display_ad' then 'android_display' when b.app_platform = 'android' and a.source = 'featured' then 'android_featured' when b.app_platform = 'android' and a.source = 'video' then 'android_video' when b.app_platform = 'iphone' and a.source = 'offerwall' then 'ios_in_app' when b.app_platform = 'iphone' and a.source = 'display_ad' then 'ios_display' when b.app_platform = 'iphone' and a.source = 'featured' then 'ios_in_app' when b.app_platform = 'iphone' and a.source = 'video' then 'ios_video' when a.source = 'tj_games' then 'tjm' else 'other' end as network, c.item_type, -.01*sum(a.GR_hr1) as GR_hr1, -.01*sum(a.GR_hr2) as GR_hr2, -.01*(sum(a.GR_hr1) - sum(a.GR_hr2)) as GR_delta, case when sum(a.GR_hr2) = 0 then NULL else ((sum(a.GR_hr1)/sum(a.GR_hr2))-1) end as GR_pct_change from ( select publisher_app_id, offer_id, source, cast(sum(case when time between sysdate - interval '2 hour' and sysdate - interval '1 hour' then advertiser_amount else 0 end) as numeric) as GR_hr1, cast(sum(case when time between sysdate - interval '3 hour' and sysdate - interval '2 hour' then advertiser_amount else 0 end) as numeric) as GR_hr2 from analytics.actions where etl_day >= to_char(date(sysdate) - 1) and time between sysdate - interval '3 hour' and sysdate - interval '1 hour' group by 1, 2, 3 ) a left join ( select app_id, app_name, app_platform, sales_rep_email as acct_mgr_email, sales_rep_id as acct_mgr_id from analytics.apps_partners ) b on a.publisher_app_id = b.app_id left join ( select offer_id, item_type from analytics.offers_partners ) c on a.offer_id = c.offer_id group by 1, 2, 3, 4, 5, 6, 7 having -.01*(sum(a.GR_hr1) - sum(a.GR_hr2)) < -100 and ( sum(a.GR_hr1)/sum(a.GR_hr2) ) - 1 < -.7 order by 6, 7"
      },
      {
        :message => "Material Rev Drop Format Placement (3 Hour)",
        :query => "select sysdate as timestamp, b.app_id, b.app_name, b.acct_mgr_email, b.acct_mgr_id, case when b.app_platform = 'android' and a.source = 'offerwall' then 'android_in_app' when b.app_platform = 'android' and a.source = 'display_ad' then 'android_display' when b.app_platform = 'android' and a.source = 'featured' then 'android_featured' when b.app_platform = 'android' and a.source = 'video' then 'android_video' when b.app_platform = 'iphone' and a.source = 'offerwall' then 'ios_in_app' when b.app_platform = 'iphone' and a.source = 'display_ad' then 'ios_display' when b.app_platform = 'iphone' and a.source = 'featured' then 'ios_in_app' when b.app_platform = 'iphone' and a.source = 'video' then 'ios_video' when a.source = 'tj_games' then 'tjm' else 'other' end as network, c.item_type, -.01*sum(a.GR_hr2) as GR_hr2, -.01*sum(a.GR_hr3) as GR_hr3, -.01*(sum(a.GR_hr2) - sum(a.GR_hr3)) as GR_delta, case when sum(a.GR_hr3) = 0 then NULL else ((sum(a.GR_hr2)/sum(a.GR_hr3))-1) end as GR_pct_change from ( select publisher_app_id, offer_id, source, cast(sum(case when time between sysdate - interval '3 hour' and sysdate - interval '2 hour' then advertiser_amount else 0 end) as numeric) as GR_hr2, cast(sum(case when time between sysdate - interval '4 hour' and sysdate - interval '3 hour' then advertiser_amount else 0 end) as numeric) as GR_hr3 from analytics.actions where etl_day >= to_char(date(sysdate) - 1) and time between sysdate - interval '4 hour' and sysdate - interval '2 hour' group by 1, 2, 3 ) a left join ( select app_id, app_name, app_platform, sales_rep_email as acct_mgr_email, sales_rep_id as acct_mgr_id from analytics.apps_partners ) b on a.publisher_app_id = b.app_id left join ( select offer_id, item_type from analytics.offers_partners ) c on a.offer_id = c.offer_id group by 1, 2, 3, 4, 5, 6, 7 having -.01*(sum(a.GR_hr2) - sum(a.GR_hr3)) < -100 and ( sum(a.GR_hr2)/sum(a.GR_hr3) ) - 1 < -.7 order by 6, 7"
      },
      {
        :message => "Material Rev Drop Format Placement (4 Hour)",
        :query => "select sysdate as timestamp, b.app_id, b.app_name, b.acct_mgr_email, b.acct_mgr_id, case when b.app_platform = 'android' and a.source = 'offerwall' then 'android_in_app' when b.app_platform = 'android' and a.source = 'display_ad' then 'android_display' when b.app_platform = 'android' and a.source = 'featured' then 'android_featured' when b.app_platform = 'android' and a.source = 'video' then 'android_video' when b.app_platform = 'iphone' and a.source = 'offerwall' then 'ios_in_app' when b.app_platform = 'iphone' and a.source = 'display_ad' then 'ios_display' when b.app_platform = 'iphone' and a.source = 'featured' then 'ios_in_app' when b.app_platform = 'iphone' and a.source = 'video' then 'ios_video' when a.source = 'tj_games' then 'tjm' else 'other' end as network, c.item_type, -.01*sum(a.GR_hr3) as GR_hr3, -.01*sum(a.GR_hr4) as GR_hr4, -.01*(sum(a.GR_hr3) - sum(a.GR_hr4)) as GR_delta, case when sum(a.GR_hr4) = 0 then NULL else ((sum(a.GR_hr3)/sum(a.GR_hr4))-1) end as GR_pct_change from ( select publisher_app_id, offer_id, source, cast(sum(case when time between sysdate - interval '4 hour' and sysdate - interval '3 hour' then advertiser_amount else 0 end) as numeric) as GR_hr3, cast(sum(case when time between sysdate - interval '5 hour' and sysdate - interval '4 hour' then advertiser_amount else 0 end) as numeric) as GR_hr4 from analytics.actions where etl_day >= to_char(date(sysdate) - 1) and time between sysdate - interval '5 hour' and sysdate - interval '3 hour' group by 1, 2, 3 ) a left join ( select app_id, app_name, app_platform, sales_rep_email as acct_mgr_email, sales_rep_id as acct_mgr_id from analytics.apps_partners ) b on a.publisher_app_id = b.app_id left join ( select offer_id, item_type from analytics.offers_partners ) c on a.offer_id = c.offer_id group by 1, 2, 3, 4, 5, 6, 7 having -.01*(sum(a.GR_hr4) - sum(a.GR_hr4)) < -100 and ( sum(a.GR_hr3)/sum(a.GR_hr4) ) - 1 < -.7 order by 6, 7"
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
