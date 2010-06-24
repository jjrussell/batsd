class StatzController < WebsiteController
  include MemcachedHelper
  
  filter_access_to [ :index, :show, :edit, :update, :search ]
  
  def index
    money_stats = get_from_cache('statz.money') || {'24_hours' => {}}
    @cvr_count_24hours = money_stats['24_hours']['conversions'] || "Not Available"
    @ad_spend_24hours =  money_stats['24_hours']['advertiser_spend'] || "Not Available"
    @publisher_earnings_24hours =  money_stats['24_hours']['publisher_earnings'] || "Not Available"
    
    @last_updated = get_from_cache('statz.last_updated') || Time.at(8.hours.to_i)
    @cached_stats = get_from_cache('statz.cached_stats') || {}
  end
  
  def show
    now = Time.zone.now
    @start_time = now.beginning_of_hour - 23.hours
    @end_time = now
    unless params[:date].blank?
      now = Time.zone.parse(params[:date])
      @start_time = now.beginning_of_day
      @end_time = @start_time + 24.hours
    end
    @offer = Offer.find(params[:id])
    @stats = Appstats.new(@offer.id, { :start_time => @start_time, :end_time => @end_time }).stats
  end
  
  def edit
    @offer = Offer.find(params[:id])
  end
  
  def update
    @offer = Offer.find(params[:id])
    params[:offer][:device_types] = params[:offer][:device_types].to_json
    if @offer.update_attributes(params[:offer])
      flash[:notice] = "Successfully updated #{@offer.name}"
      redirect_to statz_path(@offer)
    else
      render :action => :edit
    end
  end
  
  def search
    results = Offer.find(:all,
      :conditions => "name LIKE '%#{params[:q]}%'",
      :select => 'id, name',
      :limit => params[:limit]
    ).collect { |o| "#{o.name}|#{o.id}" }
    
    render(:text => results.join("\n"))  
  end
end
