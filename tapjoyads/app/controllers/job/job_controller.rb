class Job::JobController < ApplicationController
  include AuthenticationHelper

  before_filter :authenticate
  around_filter :record_errors

  private

  def record_errors
    yield
  rescue => exception
    Airbrake.notify(exception, airbrake_request_data)
    raise exception
  end

end
