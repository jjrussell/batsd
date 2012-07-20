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
    unless app.valid?
      render_error(app.errors, 400) and return
    end

    if params[:store_id].present?
      store_name = params[:store_name] ? params[:store_name] : App::PLATFORM_DETAILS[app.platform][:default_store_name]

      unless app_metadata = app.add_app_metadata(store_name, params[:store_id], true)
        render_error("failed to create app metadata", 400) and return
      end
      Sqs.send_message(QueueNames::GET_STORE_INFO, app_metadata.id)
    end

    app.save!

    save_activity_logs
    render_success({ :app_id => app.id, :app_secret_key => app.secret_key })
  end

  def update
    return unless verify_request([ :id ])

    app = App.find_by_id(params[:id])
    unless app.present?
      render_error('app not found', 400) and return
    end

    return unless verify_partner(app.partner_id)

    log_activity(app)
    app.name = params[:name] if params[:name].present?

    unless app.valid?
      render_error(app.errors, 400) and return
    end

    if params[:store_id].present?
      if app.primary_app_metadata
        app_metadata = app.update_app_metadata(app.primary_app_metadata.store_name, params[:store_id])
      else
        store_name = params[:store_name] ? params[:store_name] : App::PLATFORM_DETAILS[app.platform][:default_store_name]
        app_metadata = app.add_app_metadata(store_name, params[:store_id], true)
      end

      unless app_metadata
        render_error("failed to update app metadata", 400) and return
      end
      Sqs.send_message(QueueNames::GET_STORE_INFO, app_metadata.id)
    end

    app.save!

    save_activity_logs
    render_success
  end

end
