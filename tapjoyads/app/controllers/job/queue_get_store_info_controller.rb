class Job::QueueGetStoreInfoController < Job::SqsReaderController

  def initialize
    super QueueNames::GET_STORE_INFO
  end

  private

  def on_message(message)
    app = App.find(message.body)
    log_activity(app)

    return unless app.store_id.present?
    # HACK: android search from EC2 is (hopefully) temporarily blocked
    return if app.platform == 'android'

    begin
      app.fill_app_store_data
    rescue Exception => e
      Rails.logger.info "Exception when fetching app store info: #{e}"
    else
      app.save!
      save_activity_logs(true)
    end
  end

end
