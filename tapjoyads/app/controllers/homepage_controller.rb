class HomepageController < WebsiteController
  layout 'newcontent'
  protect_from_forgery :except => [:contact]

  def start
    if has_role_with_hierarchy?(:admin)
      redirect_to tools_path
    elsif permitted_to?(:index, :statz)
      redirect_to statz_index_path
    elsif permitted_to?(:index, :apps)
      redirect_to apps_path
    elsif current_partner.nil?
      render :action => 'index', :layout => 'newhome'
    end
  end

  def contact
    if params[:info]
      case params[:info][:source]
      when 'publishers_contact'
        # TODO: this is submitted from /publishing. consolidate with regular contact page
        TapjoyMailer.deliver_publisher_application(params[:info])
        redirect_to :action => 'contact-thanks'
      when 'performance', 'agencies'
        if params[:info][:email] =~ Authlogic::Regex.email
          TapjoyMailer.deliver_advertiser_application(params[:info])
          render :json => nil
        else
          render :json => {:error => 'Invalid email address.'}
        end
      else
        info = params[:info]
        if info[:name].blank? || info[:email].blank? || info[:details].blank? || info[:reason].blank?
          @error_msg = "All fields must be filled out."
        else
          TapjoyMailer.deliver_contact_us(params[:info])
          params[:info] = nil
          @success = true
        end
      end
    end
  end

  def privacy
  end

  def privacy_mobile
    render :layout => false
  end

  def about_us
  end

  def advertisers
  end

  def app_developers
  end

  def team
    @employees = Employee.active_only
  end

  def index
    render :layout => 'newhome'
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
end
