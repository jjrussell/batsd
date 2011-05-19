class HomepageController < WebsiteController
  layout 'homepage'
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
  
  def rest_of_team
    @employees = Employee.active_only
  end
  
  def show_photo
    @employee = Employee.find(params[:id])
    if @employee.photo
      send_data(@employee.photo, :filename => 'mihir_shah.gif', :type => 'image/gif', :disposition => 'inline')
    else
      send_file('public/images/site/blank_image.jpg', :type => 'image/jpg', :disposition => 'inline')
    end
  end

  def privacy
    render :layout => false
  end
  
  def advertisers
    render :layout => 'newcontent'
  end
  
  def app_developers
    render :layout => 'newcontent'
  end
  
  def index
    render :layout => 'newhome'
  end
end
