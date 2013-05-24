require 'cached_app'

class PopularApp

  MAX_APPS = 10

  def self.get_ios
    Mc.distributed_get('cached_apps.popular_ios') || []
  end

  def self.get_android
    Mc.distributed_get('cached_apps.popular_android') || []
  end

  def self.cache
    now = Time.zone.now
    start_time = now - 23.hours
    end_time = now + 1.hour

    top_offers_ios, top_offers_android = [], []
    Offer.find_each do |offer|
      if offer.get_platform == 'iOS'
        top_offers = top_offers_ios
      elsif offer.get_platform == 'Android'
        top_offers = top_offers_android
      else
        next
      end

      next if offer.item_type != 'App'
      next if offer.item.store_id.blank?
      next if top_offers.any? { |o| o[1].item.store_id == offer.item.store_id }

      appstats = Appstats.new(offer.id, { :start_time => start_time, :end_time => now + 1.hour, :stat_types => [ 'new_users' ] }).stats
      new_users = appstats['new_users'].sum

      if top_offers.size < MAX_APPS || top_offers.last[0] < new_users
        index = top_offers.index { |o| new_users > o[0] } || 0
        top_offers.insert(index, [new_users, offer])
        top_offers.slice!(MAX_APPS, top_offers.length)
      end
    end

    cached_apps_ios = top_offers_ios.map { |o| CachedApp.new(o[1]) }
    cached_apps_android = top_offers_android.map { |o| CachedApp.new(o[1]) }

    Mc.distributed_put('cached_apps.popular_ios', cached_apps_ios)
    Mc.distributed_put('cached_apps.popular_android', cached_apps_android)
  end
end
