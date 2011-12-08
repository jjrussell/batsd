class Tools::SupportRequestsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  after_filter :save_activity_logs, :only => [ :mass_resolve ]

  def mass_resolve
    return if params[:upload_support_requests].blank?
    file_contents = params[:upload_support_requests].read
    if file_contents.blank?
      flash[:error] = 'The given file was empty'
      return
    end

    begin
      support_request_file = "#{(Time.now.to_f * 1000).to_i}_mass_resolve_support_requests_list"
      S3.bucket(BucketNames::SUPPORT_REQUESTS).objects[support_request_file].write(:data => file_contents)
      Sqs.send_message(QueueNames::RESOLVE_SUPPORT_REQUESTS, { :user_email => current_user.email, :support_requests_file => support_request_file }.to_json)
    rescue
      flash[:error] = 'Unable to upload the file for processing.'
    end

    flash[:notice] = 'The request has been submitted. An email confirmation will be mailed to you.'
  end

  def index
    @end_time   = params[:end_time] || Time.zone.now
    @start_time = params[:start_time] || 1.day.ago

    offer_ids         = Hash.new(0)
    publisher_app_ids = Hash.new(0)
    @udids            = Hash.new(0)
    @offers           = Hash.new(0)
    @publisher_apps   = Hash.new(0)
    @total            = 0

    SupportRequest.select(:where => "`updated-at` >= '#{@start_time.to_f}' AND `updated-at` < '#{@end_time.to_f}'") do |sr|
      offer_ids[sr.offer_id] += 1
      publisher_app_ids[sr.app_id] += 1
      @udids[sr.udid] += 1
      @total += 1
    end

    offer_ids.each do |k,v|
      @offers[Offer.find(k)] = v unless k.nil?
    end

    publisher_app_ids.each do |k,v|
      @publisher_apps[App.find(k)] = v unless k.nil?
    end
  end
end
