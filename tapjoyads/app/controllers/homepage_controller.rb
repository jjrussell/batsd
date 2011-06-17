class HomepageController < WebsiteController
  layout 'newcontent'
  protect_from_forgery :except => [:contact]

  def start
    if permitted_to?(:index, :statz)
      redirect_to statz_index_path
    elsif permitted_to?(:index, :apps)
      redirect_to apps_path
    elsif current_partner.nil?
      render :action => 'index', :layout => 'newhome'
    end
  end

  def contact
    if params[:info]
      if params[:info][:source] == 'publishers_contact'
        # TODO: this is submitted from /publishing. consolidate with regular contact page
        TapjoyMailer.deliver_publisher_application(params[:info])
        redirect_to :action => 'contact-thanks'
      else
        info = params[:info]
        if info[:name].blank? || info[:email].blank? || info[:details].blank? || info[:reason].blank?
          @error_msg = "All fields must be filled out."
        else
          TapjoyMailer.deliver_contact_us(params[:info])
        end
      end
    end
  end

  def privacy
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
end
