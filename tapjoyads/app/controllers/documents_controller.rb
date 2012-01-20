class DocumentsController < WebsiteController
  layout 'newcontent'
  protect_from_forgery

  def privacy
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
