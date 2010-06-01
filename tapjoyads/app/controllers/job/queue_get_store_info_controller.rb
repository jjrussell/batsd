class Job::QueueGetStoreInfoController < Job::SqsReaderController
  
  include NewRelicHelper
  
  def initialize
    super QueueNames::GET_STORE_INFO
  end
  
private
  
  def on_message(message)
    
    @app = SdbApp.new(:key => message.to_s)
    
    begin
      store_id = @app.get_store_id
      app_data = AppStore.fetch_app_by_id(store_id)
    
      @app.age_rating = app_data.age_rating
      @app.save
      
    rescue Exception => e
      Rails.logger.info "App store data retrieval error: #{e}"
      alert_new_relic(GetStoreInfoError, "App store data retrieval for #{message.to_s} error: #{e}")
    end
    
  end
  
  
end
