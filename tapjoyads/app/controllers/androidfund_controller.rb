class AndroidfundController < WebsiteController
  layout 'androidfund'

  def index
  end
  
  def apply
    if params[:info]
      info = params[:info]
      if info[:first_name].blank? || info[:last_name].blank? || info[:email_address].blank?
        @error_msg = "All fields must be filled out."
      else
        TapjoyMailer.deliver_androidfund_application(params[:info])
      end
    end
    render :layout => 'androidfund'
  end
end
