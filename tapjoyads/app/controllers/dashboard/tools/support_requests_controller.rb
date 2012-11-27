class Dashboard::Tools::SupportRequestsController < Dashboard::DashboardController
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
      support_request_file = UUIDTools::UUID.random_create.to_s
      S3.bucket(BucketNames::SUPPORT_REQUESTS).objects[support_request_file].write(:data => file_contents)
      Sqs.send_message(QueueNames::RESOLVE_SUPPORT_REQUESTS, { :user_email => current_user.email, :support_requests_file => support_request_file }.to_json)
    rescue
      flash[:error] = "Your file could not be processed. Try uploading it again, or email dev@tapjoy.com if it's continuing to fail."
    end

    flash[:notice] = "Your file has been uploaded. You'll receive an email after your file has been processed."
  end

  # @return [Hash]
  # @option return [App, Offer, nil] :object
  # @option return [Integer] :count
  def index
    @past_hours = params[:past_hours] ? params[:past_hours].to_i : 24
    stats = SupportRequestStats.for_past(@past_hours)
    offers            = stats[:offers]
    publisher_apps    = stats[:publisher_apps]
    udids             = stats[:udids]
    tapjoy_device_ids = stats[:tapjoy_device_ids]
    @total            = stats[:total]
    @last_updated     = stats[:last_updated]
    @end_time = @last_updated
    @start_time = @end_time - @past_hours.hours

    @offers = ActiveSupport::OrderedHash.new
    offers.each do |id, count|
      @offers[id] = { :count => count, :object => nil }
    end
    Offer.find(@offers.keys).each do |o|
      @offers[o.id][:object] = o
    end

    @publisher_apps = ActiveSupport::OrderedHash.new
    publisher_apps.each do |id, count|
      @publisher_apps[id] = { :count => count, :object => nil }
    end
    App.find(@publisher_apps.keys).each do |pa|
      @publisher_apps[pa.id][:object] = pa
    end

    @udids = ActiveSupport::OrderedHash.new
    udids.each do |id, count|
      @udids[id] = { :count => count, :object => id }
    end

    @tapjoy_device_ids = ActiveSupport::OrderedHash.new
    tapjoy_device_ids.each do |id, count|
      @tapjoy_device_ids[id] = { :count => count, :object => id }
    end
  end
end
