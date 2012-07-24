## Press Controller
## @description Controls press section of the website
## @help News entries are loaded via constructor. Press/index.html.haml contains the main press view but viewing articles uses press.html.haml as the layout

class Homepage::PressController < Homepage::HomepageController
  layout 'press'

  def show
    redirect_to 'http://info.tapjoy.com/about-tapjoy/company-news', :status => :moved_permanently
  end

  def glu
    redirect_to 'http://blog.tapjoy.com/uncategorized/tapjoy-helps-fuel-the-growth-of-glus-gun-bros-app', :status => :moved_permanently
  end

  def index
    redirect_to 'http://info.tapjoy.com/about-tapjoy/company-news', :status => :moved_permanently
  end
end
