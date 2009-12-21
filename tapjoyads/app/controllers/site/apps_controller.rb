class Site::AppsController < Site::SiteController
  
  def show
    @app = App.new(params[:id])
    
    unless @app.get('name')
      render_not_found
      return
    end
  end
  
  def list
    # Create @apps, using params[:partner_id]
  end
  
end
