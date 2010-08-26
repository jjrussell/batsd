class Job::QueueGetStoreInfoController < Job::SqsReaderController

  def initialize
    super QueueNames::GET_STORE_INFO
  end

private

  def on_message(message)
    app = App.find(message.to_s)

    app_data = AppStore.fetch_app_by_id(app.store_id)

    raise "App store data retrieval failed for #{app.name} (#{app.id})" if app_data.nil?

    app.age_rating = app_data[:age_rating]
    app.save!
  end

end
