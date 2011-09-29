class UserSessionsController < WebsiteController
  
  def new
    @user_session = UserSession.new
    @goto = params[:goto]
  end
  
  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      redirect_to(params[:goto] || default_path)
    else
      @goto = params[:goto]
      render :action => 'new'
    end
  end
  
  def destroy
    user_session = UserSession.find
    unless user_session.nil?
      user_session.destroy
    end
    redirect_to dashboard_root_path
  end

private

  def default_path
    options = { :user => @user_session.record }
    if has_role_with_hierarchy?(:admin)
      tools_path
    elsif permitted_to?(:index, :statz, options)
      statz_index_path
    elsif permitted_to?(:index, :tools, options)
      tools_path
    elsif permitted_to?(:index, :apps, options)
      apps_path
    else
      dashboard_root_path
    end
  end

end
