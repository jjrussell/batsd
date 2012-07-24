class Job::JobController < ApplicationController
  include AuthenticationHelper

  before_filter :authenticate
  around_filter :around_job

  private

  def around_job
    params[:concurrency_filename] = nil if params[:concurrency_filename] =~ /\.\.\//
    yield
  rescue => exception
    Airbrake.notify(exception, airbrake_request_data)
    raise exception
  ensure
    if params[:concurrency_filename].present? && File.exists?("#{Job::CONCURRENCY_DIR}/#{params[:concurrency_filename]}")
      File.delete("#{Job::CONCURRENCY_DIR}/#{params[:concurrency_filename]}")
    end
  end

end
