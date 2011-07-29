## Careers Controller
## @description Controls press section of the website
## @help News entries are loaded via constructor. Press/index.html.haml contains the main press view but viewing articles uses press.html.haml as the layout

class Homepage::CareersController < WebsiteController
  layout 'careers'
  def initialize
    @careers_list = [
      {
        :name => "Engineering",
        :list => [
          { :title => "Software Engineer", :href => "/careers/software_engineer"},
          { :title => "Sales Technical Support Engineer", :href => "/careers/sales_technical_support_engineer"},
        ]
      },
      {
        :name => "Developer Relations",
        :list => [
          { :title => "Developer Outreach Associate", :href => "/careers/developer_outreach_associate"},
          ]
      },
      {
        :name => "Sales",
        :list => [
          { :title => "Director, Advertising Sales", :href => "/careers/director_advertising_sales"},
          { :title => "Sales Development Rep", :href => "/careers/sales_development_rep"},
        ]
      },
      {
        :name => "Finance",
        :list => [
          { :title => "Financial Controller", :href => "/careers/financial_controller"}
          { :title => "Senior Accountant", :href => "/careers/senior_accountant"}
          { :title => "Accounting Operations Manager", :href => "/careers/accounting_operations"},
        ]
      },
      {
        :name => "PeopleOps",
        :list => [
          { :title => "Senior Technical Recruiter", :href => "/careers/technical_recruiter"},
        ]
      },
    ]
  end

  def show
    render "homepage/careers/#{params[:id]}"
  end

  def index
    render :layout => 'newcontent'
  end
end
