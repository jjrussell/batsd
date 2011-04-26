## Press Controller
## @description Controls press section of the website
## @help News entries are loaded via constructor. Press/index.html.haml contains the main press view but viewing articles uses press.html.haml as the layout

class Homepage::CareersController < WebsiteController
  layout 'careers'
  def initialize
    @careers_list = [
      [ "Product",
        [
          ["Name", "URL"],
          ["Name2", "URL2"],
          ["Name3", "URL3"],
    ]
      ],
      [ "Engineering",
        [
          ["Name", "URL"],
          ["Name2", "URL2"],
          ["Name3", "URL3"],
      ]
      ]
    ]
  end

  def show
    sanitized_id = params[:id]
    render "homepage/careers/#{sanitized_id}"
  end

  def index
    render :layout => 'newcontent'
  end
end
