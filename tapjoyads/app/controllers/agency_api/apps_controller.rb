class AgencyApi::AppsController < AgencyApiController
  
  def index
    return unless verify_request([ :partner_id ])
    return unless verify_partner(params[:partner_id])
    
    apps = @partner.apps.map do |app|
      { :app_id => app.id, :name => app.name, :platform => app.platform, :store_id => app.store_id }
    end
    
    render_success({ :apps => apps })
  end
  
  def create
    return unless verify_request([ :partner_id, :name, :platform ])
    return unless verify_partner(params[:partner_id])
    
    app = App.new
    log_activity(app)
    app.partner = @partner
    app.name = params[:name]
    app.platform = params[:platform]
    app.store_id = params[:store_id] if params[:store_id].present?
    unless app.valid?
      render_error(app.errors, 400)
      return
    end
    app.save!
    
    save_activity_logs
    render_success({ :app_id => app.id })
  end
  
end
