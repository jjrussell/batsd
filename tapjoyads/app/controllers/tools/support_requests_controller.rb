class Tools::SupportRequestsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  after_filter :save_activity_logs, :only => [ :mass_resolve ]

  def mass_resolve
    @request_not_awarded = []
    @request_successfully_awarded = 0
    return if params[:upload_support_requests].blank?
    file_contents = params[:upload_support_requests].read
    if file_contents.blank?
      flash[:error] = 'The given file was empty'
      return
    end

    file_contents.each do |support_request_id|
      support_request_id.strip!
      next if support_request_id.empty?

      support_request = SupportRequest.new(:key => support_request_id)
      if support_request.new_record?
        @request_not_awarded.push([support_request_id, "Invalid support_request_id: #{support_request_id}"])
        next
      end

      click = support_request.click
      if click.nil?
        @request_not_awarded.push([support_request_id, "Unable to find a suitable click for: #{support_request_id}"])
        next
      end

      begin
        log_activity(click)
        click.resolve!
      rescue Exception => error
        @request_not_awarded.push([support_request_id, error])
        next
      end
      @request_successfully_awarded += 1
    end
    flash[:error] = 'Some errors were encountered while processing the rows.' if @request_not_awarded.size > 0
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
