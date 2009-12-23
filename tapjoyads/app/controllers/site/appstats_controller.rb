class Site::AppstatsController < Site::SiteController
  
  def show
    options = {}
    
    if params[:start_time]
      parts = params[:start_time].split('-')
      options[:start_time] = Time.utc(parts[0], parts[1], parts[2])
    end
    if params[:end_time]
      parts = params[:end_time].split('-')
      options[:end_time] = Time.utc(parts[0], parts[1], parts[2])
    end

    options[:granularity] = params[:granularity].to_sym if params[:granularity]
    
    @appstats = Appstats.new(params[:app_id], options)
  end
  
end