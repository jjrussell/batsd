class Dashboard::AppMetadatasController < Dashboard::DashboardController
  layout 'apps'
  current_tab :apps

  filter_access_to :all

  before_filter :setup
  after_filter :save_activity_logs, :only => [ :update, :create ]

  def show
  end

  def update
    log_activity(@app_metadata)
    @orig_app_metadata = @app_metadata

    if params[:store_id].blank?
      flash.now[:error] = 'A live app must be selected.'
      render :action => "show" and return
    end

    AppMetadata.transaction do
      begin
        @app_metadata = @app.update_app_metadata(params[:store_name], params[:store_id])
      rescue
        @error_message = 'Update unsuccessful.'
        raise
      end

      begin
        app_store_data = @app_metadata.update_from_store()
      rescue
        @error_message = "Grabbing app data from app store failed. Please try again."
        raise
      end
    end

    flash[:notice] = 'Distribution was successfully updated.'
    redirect_to app_app_metadata_path(:app_id => @app.id, :id => @app_metadata.id)
  rescue => e
    logger.info e.message
    logger.info e.backtrace.join("\n")
    flash.now[:error] = @error_message ? @error_message : e.message
    @app_metadata = @orig_app_metadata
    render :action => "show" and return
  end

  def new
    @app_metadata = AppMetadata.new
    @store_options = AppStore.android_store_options
  end

  def create
    if params[:store_id].blank?
      flash.now[:error] = 'A live app must be selected.'
      render_new_on_error and return
    end

    if @app.app_metadatas.find_by_store_name(params[:store_name])
      flash.now[:error] = "Failed to create distribution.  There is already a distribution for #{AppStore.find(params[:store_name]).name}."
      render_new_on_error and return
    end

    AppMetadata.transaction do
      begin
        @app_metadata = @app.add_app_metadata(params[:store_name], params[:store_id])
        log_activity(@app_metadata)
      rescue
        @error_message = 'Failed to create distribution.'
        raise
      end

      begin
        app_store_data = @app_metadata.update_from_store()
      rescue
        @error_message = "Grabbing app data from app store failed. Please try again."
        raise
      end
    end

    flash[:notice] = 'Distribution was successfully created.'
    redirect_to app_app_metadata_path(:app_id => @app.id, :id => @app_metadata.id)
  rescue => e
    logger.info e.message
    logger.info e.backtrace.join("\n")
    flash.now[:error] = @error_message ? @error_message : e.message
    render_new_on_error and return
  end

  def remove
    log_activity(@app_metadata)
    if @app.remove_app_metadata(@app_metadata)
      flash[:notice] = "Metadata removed."
    else
      flash[:error] = "Failed to remove metadata."
    end
    redirect_to :action => :new
  end

  private

  def setup
    if permitted_to? :edit, :dashboard_statz
      @app = App.find(params[:app_id])
    else
      @app = current_partner.apps.find(params[:app_id])
    end

    @distribution = @app.app_metadata_mappings.find_by_app_metadata_id(params[:id]) if params[:id]
    @app_metadata = @distribution.app_metadata if @distribution
  end

  def render_new_on_error
    @app_metadata = AppMetadata.new
    @store_options = AppStore.android_store_options
    render :action => :new
  end

end
