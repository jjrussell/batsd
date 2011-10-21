##
# A controller that is used to easily tell if the system is up.
#
# Possible future additions:
#  Tell if poller is running
#  Tell if job_runner is running
#  Tell if simpledb inserts are working
#  Give information about sqs queues.

class HealthzController < ActionController::Base

  def index
    render :text => "OK"
  end
  
  def success
    render :template => 'layouts/success'
  end
end
