class Tools::SupportRequestsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

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
