class Job::MasterAndroidMarketFormatController < Job::JobController

  MAX_RETRIES = 5
  def index

    test_search
    test_fetch

    render :text => 'ok'
  end

  def test_search
    fields = [:title, :price, :icon_url, :publisher, :item_id]
    term = 'tapdefense'
    retries = 0

    begin
      data = AppStore.search_android_market(term)
      if data.blank? || fields.any?{|field| data.first[field].blank?}
        message = 'Search format may have changed'
        Notifier.alert_new_relic(AndroidMarketChanged, message)
      end
    rescue
      retries += 1
      if retries < MAX_RETRIES
        puts "retrying"
        sleep 5
        retry
      else
        Notifier.alert_new_relic(AndroidMarketChanged, 'Site may be down')
      end
    end
  end

  def test_fetch
    fields = [:title, :price, :file_size_bytes, :description, :icon_url,
      :categories, :publisher, :item_id]
    id = 'com.tapjoy.tapjoy'
    retries = 0

    begin
      data = AppStore.fetch_app_by_id_for_android(id)
      if fields.any?{|field| data[field].blank?}
        message = 'Listing format may have changed'
        Notifier.alert_new_relic(AndroidMarketChanged, message)
      end
    rescue
      retries += 1
      if retries < MAX_RETRIES
        puts "retrying"
        sleep 5
        retry
      else
        Notifier.alert_new_relic(AndroidMarketChanged, 'Site may be down')
      end
    end
  end
end
