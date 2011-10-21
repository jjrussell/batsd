class AndroidfundController < WebsiteController
  layout 'androidfund'

  def index
  end

  def apply
    if params[:info]
      info = params[:info]
      if info[:first_name].blank? || info[:last_name].blank? || info[:email_address].blank?
        @error_msg = "All fields must be filled out."
      elsif info[:email_address] !~ Authlogic::Regex.email
        @error_msg = "You must enter a valid email address."
      else
        @success_msg = "Your application has been received."
        TapjoyMailer.deliver_androidfund_application(params[:info])
      end
    else
      params[:info] = {}
    end
  end
end
