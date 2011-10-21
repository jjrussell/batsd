class Job::MasterGetStoreInfoController < Job::JobController

  def index
    App.find_each(:conditions => "store_id is not null and store_id != ''") do |app|
      Sqs.send_message(QueueNames::GET_STORE_INFO, app.id)
      sleep(1)
    end

    render :text => 'ok'
  end

end
