## Press Controller
## @description Controls press section of the website
## @help News entries are loaded via constructor. Press/index.html.haml contains the main press view but viewing articles uses press.html.haml as the layout

class Homepage::PressController < Homepage::HomepageController
  layout 'press'

  def show
    @sanitized_id = params[:id].split('-').first
    @press_release = PressRelease.find_by_link_id(@sanitized_id)
    redirect_to '/press' and return unless @press_release && @press_release.content_body.present?

    @recent_press = PressRelease.ordered.not_future
    @recent_news = NewsCoverage.ordered.not_future
  end

  def glu
    redirect_to :action => 'show', :id => '201103030'
  end

  def index
    redirect_to "/press/" + PressRelease.most_recent_and_not_future.link_href
  end
end
