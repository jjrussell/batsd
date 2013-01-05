class Job::JobController < ApplicationController
  include AuthenticationHelper

  before_filter { ActiveRecordDisabler.enable_queries! } unless Rails.env.production?
  before_filter :authenticate
  around_filter :around_job unless Rails.env.test?

  private

  def around_job
    worker_name = $0
    params[:concurrency_filename] = nil if params[:concurrency_filename] =~ /\.\.\//
    $0 = "#{worker_name[0..worker_name.index('-')]} #{self.class.to_s}"
    yield
  rescue => exception
    Airbrake.notify(exception, airbrake_request_data)
    raise exception
  ensure
    if params[:concurrency_filename].present? && File.exists?("#{Job::CONCURRENCY_DIR}/#{params[:concurrency_filename]}")
      File.delete("#{Job::CONCURRENCY_DIR}/#{params[:concurrency_filename]}")
    end
    $0 = worker_name
  end

end
