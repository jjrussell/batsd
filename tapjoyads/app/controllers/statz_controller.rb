class StatzController < WebsiteController
  include MemcachedHelper
  
  filter_access_to [ :index, :show ]
  
  def index
    @install_count_24hours = get_from_cache('statz.install_count_24hours')
    @last_updated = get_from_cache('statz.last_updated')
    @cached_stats = get_from_cache('statz.cached_stats')
  end
  
  def show
    @app = SdbApp.new :key => params[:id]
    @stats = Appstats.new(@app.key, { :start_time => now - 23.hours, :end_time => now + 1.hour }).stats
  end
end