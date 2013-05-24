class Job::MasterSelectVgItemsController < Job::JobController
  def index
    Sqs.send_message(QueueNames::SELECT_VG_ITEMS, 'run')
    render :text => "ok"
  end
end
