class Job::QueueGetStoreInfoController < Job::SqsReaderController

  def initialize
    super QueueNames::GET_STORE_INFO
    @num_reads = 10
  end

  private

  def on_message(message)
    app_metadata = AppMetadata.find(message.body)
    log_activity(app_metadata)

    begin
      app_metadata.update_from_store
    rescue Exception => e
      Rails.logger.info "Exception when fetching app store info: #{e}"
    else
      save_activity_logs(true)
    end
  end

end
