class Job::MasterGetStoreInfoController < Job::JobController
  include SqsHelper
  
  def initialize
    @now = Time.now.utc
  end
  
  def index
    App.find_each(:conditions => "store_id is not null and platform='iphone'") do |app|
      
      send_to_sqs(QueueNames::GET_STORE_INFO, app.id)
    end
    
    render :text => 'ok'
  end
end