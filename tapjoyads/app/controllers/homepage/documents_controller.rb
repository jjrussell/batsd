class Homepage::DocumentsController < Homepage::HomepageController
  layout 'newcontent'
  protect_from_forgery

  def privacy
    redirect_to 'http://info.tapjoy.com/about-tapjoy/privacy-policy', :status => :moved_permanently
  end

  def privacy_mobile
    render :layout => false
  end

  def tos_advertiser
    render :layout => false
  end

  def tos_publisher
    render :layout => false
  end

  def publisher_guidelines
    render :layout => false
  end
end
