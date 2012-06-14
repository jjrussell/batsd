# TODO: does this controller still get used? didn't want to remove it here
class HomepageController < WebsiteController
  layout 'newcontent'
  protect_from_forgery :except => [:contact]
  before_filter :legacy_redirect, :only => [:advertisers_contact, :advertiser_contact, :contact_us, :publishers_contact, :gaming_platforms]

  def contact
    redirect_to 'http://info.tapjoy.com/contact-us', :status => :moved_permanently
  end

  def about_us
    redirect_to 'http://info.tapjoy.com/about-tapjoy', :status => :moved_permanently
  end

  def advertisers
    redirect_to 'http://advertisers.tapjoy.com', :status => :moved_permanently
  end

  def app_developers
    redirect_to 'http://developers.tapjoy.com', :status => :moved_permanently
  end

  def team
    redirect_to 'http://info.tapjoy.com/about-tapjoy/leadership/executive-team', :status => :moved_permanently
  end

  def index
    redirect_to root_path
  end

  def index_redirect
    redirect_to WEBSITE_URL
  end

  def careers
    redirect_to '/careers' and return
  end

  def events
    render :layout => false
  end

  def advertiser_contact
    render :layout => false
  end

  def whitepaper
    if params[:info]
      if params[:info][:email].present?
        if params[:info][:email] =~ Authlogic::Regex.email
          TapjoyMailer.deliver_whitepaper_request(params[:info])
          flash.now[:message] = 'Success!'
        else
          flash.now[:error] = 'Invalid email address.'
        end
      else
        flash.now[:error] = 'Email address is required.'
      end
    end
  end

  private

  def legacy_redirect
    redirect_to 'http://info.tapjoy.com/contact-us', :status => :moved_permanently
  end

end
