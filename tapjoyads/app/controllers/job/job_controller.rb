class Job::JobController < ApplicationController
  include AuthenticationHelper

  before_filter :authenticate
  around_filter :record_errors

  private

  def record_errors
    yield
  rescue => exception
    notify_airbrake(exception)
    raise exception
  end

end
