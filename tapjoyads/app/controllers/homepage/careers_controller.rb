## Careers Controller
## @description Controls press section of the website
## @help News entries are loaded via constructor. Press/index.html.haml contains the main press view but viewing articles uses press.html.haml as the layout

class Homepage::CareersController < WebsiteController
  def show
    redirect_to('http://tapjoy.jobscore.com/list')
  end

  def index
    render :layout => 'newcontent'
  end
end
