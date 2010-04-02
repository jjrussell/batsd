class Site::AppsController < Site::SiteController
  
  def show
    @app = App.new(:key => params[:id])
    respond_to do |format|
      if @app.get('name')
        format.xml #show.builder
      else
        format.xml {not_found("app")} 
      end
    end
  end
  
  def index
    @apps = Array.new
    partner = SdbPartner.new(:key => params[:partner_id])
    if partner.get('apps')
      Rails.logger.info partner.get('apps')
      app_pairs = JSON.parse(partner.get('apps'))
      app_pairs.each do |app_pair|
        @apps.push(App.new(:key => app_pair[0].downcase))
      end
    end
    
    respond_to do |format|
      format.xml #index.builder
    end      
  end
  
end
