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
    @start_time = params[:start_time] || 1.day.ago
    @end_time   = params[:end_time] || Time.zone.now
    offer_id_count         = Hash.new(0)
    publisher_app_id_count = Hash.new(0)
    udid_count             = Hash.new(0)
    @total                 = 0

    SupportRequest.select(:where => "`updated-at` >= '#{@start_time.to_f}' AND `updated-at` < '#{@end_time.to_f}'") do |sr|
      offer_id_count[sr.offer_id] += 1
      publisher_app_id_count[sr.app_id] += 1
      udid_count[sr.udid] += 1
      @total += 1
    end

    @offers = ActiveSupport::OrderedHash.new
    # Generate a hash ordered by the most frequently counted id
    # Slower equivalent: offer_id_count.sort_by( |k,v| v}[0...25]
    top_offer_ids = offer_id_count.sort{ |a,b| b[1] <=> a[1] }[0...25]
    top_offer_ids.each do |id, count|
      @offers[id] = { :count => count, :object => nil }
    end
    Offer.find(@offers.keys).each do |o|
      @offers[o.id][:object] = o
    end

    @publisher_apps = ActiveSupport::OrderedHash.new
    top_publisher_app_ids = publisher_app_id_count.sort{ |a,b| b[1] <=> a[1] }[0...25]
    top_publisher_app_ids.each do |id, count|
      @publisher_apps[id] = { :count => count, :object => nil }
    end
    App.find(@publisher_apps.keys).each do |pa|
      @publisher_apps[pa.id][:object] = pa
    end

    @udids = ActiveSupport::OrderedHash.new
    top_udids = udid_count.sort{ |a,b| b[1] <=> a[1] }[0...25]
    top_udids.each do |id, count|
      @udids[id] = { :count => count, :object => id }
    end
  end
end
