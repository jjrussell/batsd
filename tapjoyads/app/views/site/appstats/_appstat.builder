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
  
  xml.ratings appstat.stats['ratings'].join(',') if appstat.stats['ratings']
  xml.rewards appstat.stats['rewards'].join(',') if appstat.stats['rewards']
  xml.offers appstat.stats['offers'].join(',') if appstat.stats['offers']
  xml.tag!('rewards-revenue', appstat.stats['rewards_revenue'].join(',')) if appstat.stats['rewards_revenue']
  xml.tag!('offers-revenue', appstat.stats['offers_revenue'].join(',')) if appstat.stats['offers_revenue']
  xml.tag!('installs-revenue', appstat.stats['installs_revenue'].join(',')) if appstat.stats['installs_revenue']
  xml.tag!('published-installs', appstat.stats['published_installs'].join(',')) if appstat.stats['published_installs']
  xml.tag!('rewards-opened', appstat.stats['rewards_opened'].join(',')) if appstat.stats['rewards_opened']
  xml.tag!('offers-opened', appstat.stats['offers_opened'].join(',')) if appstat.stats['offers_opened']
  xml.tag!('installs-opened', appstat.stats['installs_opened'].join(',')) if appstat.stats['installs_opened']
end