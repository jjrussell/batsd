## Press Controller
## @description Controls press section of the website
## @help News entries are loaded via constructor. Press/index.html.haml contains the main press view but viewing articles uses press.html.haml as the layout

class Homepage::PressController < Homepage::HomepageController
  layout 'press'

  def show
    redirect_to 'http://info.tapjoy.com/about-tapjoy/company-news'
  end

  def glu
    redirect_to :action => 'show', :id => '201103030'
  end

  def index
    redirect_to 'http://info.tapjoy.com/about-tapjoy/company-news'
  end
end
