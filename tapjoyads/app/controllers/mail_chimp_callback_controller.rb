class MailChimpCallbackController < WebsiteController
  layout ''
  after_filter :save_activity_logs
  filter_access_to :none

  # http://www.mailchimp.com/api/webhooks/
  def callback
    raise unless params[:key] == MAIL_CHIMP_SECRET_KEY
    if params[:type] == "upemail" && params[:data][:list_id] == MAIL_CHIMP_PARTNERS_LIST_ID
      @user = User.find_by_email(params[:data][:old_email])
      log_activity(@user)
      @user.email = params[:data][:new_email]
      @user.save
    end
    render :nothing => true
  end
end
