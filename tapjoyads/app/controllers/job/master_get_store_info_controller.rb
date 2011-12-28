class Job::MasterGetStoreInfoController < Job::JobController

  def index
    AppMetadata.find_each do |app_metadata|
      Sqs.send_message(QueueNames::GET_STORE_INFO, app_metadata.id)
      sleep(1)
    end

    render :text => 'ok'
  end

end
