class Job::MasterLimitAppInstallsController < Job::JobController
  def index
    publisher_app_ids = Currency.for_ios.scoped(:select => :app_id).collect(&:app_id).uniq
    App.set_enabled_free_ios_apps
    
    publisher_app_ids.each do |publisher_app_id|
      Sqs.send_message(QueueNames::LIMIT_APP_INSTALLS, publisher_app_id)
    end
    
    render :text => 'ok'
  end
end
