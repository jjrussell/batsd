class Site::AppstatsController < Site::SiteController
  
  def index
    @appstat_list = []
    
    partner = Partner.new(params[:partner_id])
    if partner.get('apps')
      Rails.logger.info partner.get('apps')
      app_pairs = JSON.parse(partner.get('apps'))
      app_pairs.each do |app_pair|
        @appstat_list.push(Appstats.new(app_pair[0].downcase, get_appstats_options_from_params))
      end
    end
    
    respond_to do |format|
      format.xml #index.builder
    end
  end
  
  def show
    @appstat = Appstats.new(params[:id], get_appstats_options_from_params)
    
    respond_to do |format|
      unless @appstat.blank?
        format.xml #show.builder
      else
        format.xml{not_found('appstat')}
      end  
    end
  end
  
  private
  
  def get_appstats_options_from_params
    options = {}
    
    options[:start_time] = Time.at(params[:start_time].to_f).utc if params[:start_time]
    options[:end_time] = Time.at(params[:end_time].to_f).utc if params[:end_time]
    options[:granularity] = params[:granularity].to_sym if params[:granularity]
    options[:type] = params[:type].to_sym if params[:type]
    options[:stat_types] = params[:stat_types] if params[:stat_types]
    
    return options
  end
  
end