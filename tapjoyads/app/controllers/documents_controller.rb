class DocumentsController < WebsiteController
  layout 'newcontent'
  protect_from_forgery

  def privacy
  end

  def privacy_mobile
    render :layout => false
  end
end
