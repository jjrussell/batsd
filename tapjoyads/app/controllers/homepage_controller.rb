class HomepageController < WebsiteController
  layout 'homepage'
  protect_from_forgery :except => [:contact]

  def start
    if permitted_to?(:index, :statz)
      redirect_to statz_index_path
    elsif permitted_to?(:index, :apps)
      redirect_to apps_path
    elsif current_partner.nil?
      render :action => 'index'
    end
  end

  def contact
    if (params[:info])
      TapjoyMailer.deliver_contact_us(params[:info])
      redirect_to :action => 'contact-thanks'
    end
  end

  def privacy
    render :layout => false
  end

  def press
    redirect_to '/press/'
  end
end
