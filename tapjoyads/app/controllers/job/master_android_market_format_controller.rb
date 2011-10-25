class Job::MasterAndroidMarketFormatController < Job::JobController

  def index

    id = 'com.tapjoy.tapjoy'
    retries = 0

    begin
      data = AppStore.fetch_app_by_id_for_android(id)
      changed = [:title, :price, :file_size_bytes, :description, :icon_url,
        :categories, :publisher, :item_id].any?{|field| data[field].blank?}
      Notifier.alert_new_relic(AndroidMarketChanged, 'Format may have changed') if changed
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


    render :text => 'ok'
  end
end
