class HomepageController < WebsiteController
  layout 'newcontent'
  protect_from_forgery :except => [:contact]
  before_filter :legacy_redirect, :only => [:advertisers_contact, :contact_us, :publishers_contact, :gaming_platforms]

  def start
    render :action => 'index', :layout => 'newhome'
  end

  def contact
    redirect_to 'http://info.tapjoy.com/contact-us'
  end

  def about_us
    redirect_to 'http://info.tapjoy.com/about-tapjoy'
  end

  def advertisers
    redirect_to 'http://advertisers.tapjoy.com'
  end

  def app_developers
    redirect_to 'http://developers.tapjoy.com'
  end

  def team
    redirect_to 'http://info.tapjoy.com/about-tapjoy/leadership/executive-team'
  end

  def index
    render :layout => 'newhome'
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
    redirect_to :action => 'contact'
  end

end
