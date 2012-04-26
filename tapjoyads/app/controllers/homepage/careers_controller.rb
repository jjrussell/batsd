## Careers Controller
## @description Controls press section of the website
## @help News entries are loaded via constructor. Press/index.html.haml contains the main press view but viewing articles uses press.html.haml as the layout

class Homepage::CareersController < WebsiteController
  def show
    redirect_to 'http://info.tapjoy.com/about-tapjoy/careers', :status => :moved_permanently
  end

  def index
    redirect_to 'http://info.tapjoy.com/about-tapjoy/careers', :status => :moved_permanently
  end
end
