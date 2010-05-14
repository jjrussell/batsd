class Job::MasterSelectVgItemsController < Job::JobController
    include SqsHelper

    def index
      send_to_sqs(QueueNames::SELECT_VG_ITEMS, 'run')
      render :text => "ok"
    end
  end