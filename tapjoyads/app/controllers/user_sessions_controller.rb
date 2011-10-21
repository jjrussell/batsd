class UserSessionsController < WebsiteController
  
  def index
    redirect_to login_path
  end
  
  def new
    if current_user
      redirect_to(default_path) and return
    end
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
    redirect_to login_path
  end

private

  def default_path
    options = { :user => current_user || @user_session.record }
    if has_role_with_hierarchy?(:admin)
      tools_path
    elsif permitted_to?(:index, :statz, options)
      statz_index_path
    elsif permitted_to?(:index, :tools, options)
      tools_path
    elsif permitted_to?(:index, :apps, options)
      apps_path
    else
      login_path
    end
  end

end
