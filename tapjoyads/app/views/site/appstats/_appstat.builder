xml.appstat do
  xml.tag!('app-id', appstat.app_key)
  xml.granularity appstat.granularity.to_s
  xml.tag!('start-time', appstat.start_time.to_f)
  xml.tag!('end-time', appstat.end_time.to_f)

  xml.logins appstat.stats['logins'].join(',') if appstat.stats['logins']
  xml.users '' # TODO, get real number of users.
  xml.tag!('new-users', appstat.stats['new_users'].join(',')) if appstat.stats['new_users']
  xml.tag!('ad-impressions', appstat.stats['hourly_impressions'].join(',')) if appstat.stats['hourly_impressions']
  xml.tag!('paid-installs', appstat.stats['paid_installs'].join(',')) if appstat.stats['paid_installs']
  xml.tag!('installs-spend', appstat.stats['installs_spend'].join(',')) if appstat.stats['installs_spend']
  xml.tag!('paid-clicks', appstat.stats['paid_clicks'].join(',')) if appstat.stats['paid_clicks']
  xml.cvr appstat.stats['cvr'].join(',') if appstat.stats['cvr']
end