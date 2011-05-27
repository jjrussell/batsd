## Careers Controller
## @description Controls press section of the website
## @help News entries are loaded via constructor. Press/index.html.haml contains the main press view but viewing articles uses press.html.haml as the layout

class Homepage::CareersController < WebsiteController
  layout 'careers'
  def initialize
    @careers_list = [
      {
        :name => "Product",
        :list => [
          { :title => "Sr. Product Marketing Mgr.",
            :href => "/careers/senior_product_marketing_manager" },
          { :title => "Name2", :href => "URL2"},
          { :title => "Name3", :href => "URL3"},
        ]
      },
      {
        :name => "Engineering",
        :list => [
          { :title => "Name", :href => "URL"},
          { :title => "Name2", :href => "URL2"},
          { :title => "Name3", :href => "URL3"},
        ]
      }
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
