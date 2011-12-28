class AgencyApi::AppsController < AgencyApiController

  def index
    return unless verify_request([ :partner_id ])
    return unless verify_partner(params[:partner_id])

    apps = @partner.apps.map do |app|
      { :app_id => app.id, :name => app.name, :platform => app.platform, :store_id => app.store_id }
    end

    render_success({ :apps => apps })
  end

  def show
    return unless verify_request([ :id ])

    app = App.find_by_id(params[:id])
    unless app.present?
      render_error('app not found', 400)
      return
    end

    return unless verify_partner(app.partner_id)

    result = {
      :app_id         => app.id,
      :name           => app.name,
      :platform       => app.platform,
      :store_id       => app.store_id,
      :app_secret_key => app.secret_key,
      :integrated     => app.primary_offer.integrated?,
    }
    render_success(result)
  end

  def create
    return unless verify_request([ :partner_id, :name, :platform ])
    return unless verify_partner(params[:partner_id])

    app = App.new
    log_activity(app)
    app.partner = @partner
    app.name = params[:name]
    app.platform = params[:platform]
    if params[:store_id].present?
      app_metadata = app.find_or_initialize_app_metadata(params[:store_id])
      app.app_metadatas << app_metadata
    end
    unless app.save
      render_error(app.errors, 400) and return
    end
    app.update_primary_app_metadata

    save_activity_logs
    render_success({ :app_id => app.id, :app_secret_key => app.secret_key })
  end

  def update
    return unless verify_request([ :id ])

    app = App.find_by_id(params[:id])
    unless app.present?
      render_error('app not found', 400)
      return
    end

    return unless verify_partner(app.partner_id)

    log_activity(app)
    app.name = params[:name] if params[:name].present?
    original_store_id = app.store_id
    app_store_id_changed = false
    if params[:store_id].present?
      app.update_app_metadata(params[:store_id])
      app_store_id_changed = (original_store_id != params[:store_id])
    end
    unless app.save
      render_error(app.errors, 400) and return
    end
    app.primary_app_metadata.update_metadata_from_store if app_store_id_changed

    save_activity_logs
    render_success
  end

end
