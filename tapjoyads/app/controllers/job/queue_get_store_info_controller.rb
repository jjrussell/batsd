class Job::QueueGetStoreInfoController < Job::SqsReaderController

  def initialize
    super QueueNames::GET_STORE_INFO
  end

private

  def on_message(message)
    app = App.find(message.to_s)
    log_activity(app)

    return if app.store_id.nil?
    app_data = AppStore.fetch_app_by_id(app.store_id)

    return if app_data.nil?

    app.age_rating = app_data[:age_rating]
    app.file_size_bytes = app_data[:file_size_bytes]
    app.supported_devices = app_data[:supported_devices].to_json
    app.price = app_data[:price]
    app.save!
    
    save_activity_logs
  end

end
