class Job::MasterAndroidMarketFormatController < Job::JobController

  def index

    with_retries { test_search }
    with_retries { test_fetch  }

    render :text => 'ok'
  end

  private

  def test_search
    fields = [:title, :price, :icon_url, :publisher, :item_id]
    term = 'tapdefense'

    data = AppStore.search_android_market(term)
    if data.blank? || fields.any?{|field| data.first[field].blank?}
      message = 'Search format may have changed'
      Notifier.alert_new_relic(AndroidMarketChanged, message)
    end
  end

  def test_fetch
    fields = [:title, :price, :file_size_bytes, :description, :icon_url,
      :categories, :publisher, :item_id]
    id = 'com.tapjoy.tapjoy'

    data = AppStore.fetch_app_by_id_for_android(id)
    if fields.any?{|field| data[field].blank?}
      message = 'Listing format may have changed'
      Notifier.alert_new_relic(AndroidMarketChanged, message)
    end
  end

  def with_retries
    retries = 0

    begin
      yield
    rescue
      retries += 1
      if retries < 5
        puts "retrying"
        sleep 5
        retry
      else
        Notifier.alert_new_relic(AndroidMarketChanged, 'Site may be down')
      end
    end
  end
end
