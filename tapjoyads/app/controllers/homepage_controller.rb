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
        TapjoyMailer.deliver_publisher_application(params[:info])
      else
        TapjoyMailer.deliver_contact_us(params[:info])
      end
      redirect_to :action => 'contact-thanks'
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

  def index
    render :layout => 'newhome'
  end
end
