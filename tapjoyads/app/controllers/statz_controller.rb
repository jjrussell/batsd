class StatzController < WebsiteController
  include MemcachedHelper
  
  filter_access_to [ :index, :show, :search ]
  
  def index
    @install_count_24hours = get_from_cache('statz.install_count_24hours') || "Not Available"
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
    @app = SdbApp.new :key => params[:id]
    @stats = Appstats.new(@app.key, { :start_time => @start_time, :end_time => @end_time }).stats
  end
  
  def search
    results = App.all(
      :conditions => "name LIKE '%#{params[:q]}%'",
      :select => 'id, name',
      :limit => params[:limit]
    ).collect { |a| "#{a.name}|#{a.id}" }
    
    render(:text => results.join("\n"))  
  end
end
