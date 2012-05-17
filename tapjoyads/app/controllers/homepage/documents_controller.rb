class Homepage::DocumentsController < Homepage::HomepageController
  layout 'newcontent'
  protect_from_forgery

  def privacy
    redirect_to 'http://info.tapjoy.com/about-tapjoy/privacy-policy', :status => :moved_permanently
  end

  def privacy_mobile
    render :layout => false
  end
end
