class Site::AppsController < Site::SiteController
  
  def show
    @app = App.new(params[:id])
    
    unless @app.get('name')
      render_not_found
      return
    end
  end
  
  def list
    @apps = []
    partner = Partner.new(params[:partner_id])
    if partner.get('apps')
      Rails.logger.info partner.get('apps')
      app_pairs = JSON.parse(partner.get('apps'))
      app_pairs.each do |app_pair|
        @apps.push(App.new(app_pair[0].downcase))
      end
    end
  end
  
end
