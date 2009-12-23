xml.appstats do
  xml.app_id appstats.app_key
  xml.granularity appstats.granularity.to_s
  xml.start_time appstats.start_time.to_f
  xml.end_time appstats.end_time.to_f

  xml.logins appstats.stats['logins'].join(',')
  xml.ad_impressions appstats.stats['hourly_impressions'].join(',')
  xml.paid_installs appstats.stats['paid_installs'].join(',')
  xml.installs_spend appstats.stats['installs_spend'].join(',')
  xml.paid_clicks appstats.stats['paid_clicks'].join(',')
end