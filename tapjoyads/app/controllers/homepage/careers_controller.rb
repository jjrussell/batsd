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
        ]
      },
      {
        :name => "Engineering",
        :list => [
          { :title => "Software Engineers", :href => "/careers/software_engineers"},
          { :title => "Sales Technical Support Engineer", :href => "/careers/sales_technical_support_engineer"},
        ]
      },
      {
        :name => "Finance",
        :list => [
          { :title => "Senior Manager/Director, Financial Planning & Analysis (FP&A)", :href => "/careers/senior_managerdirector_financial_planning_analysis"},
          { :title => "Senior Accountant", :href => "/careers/senior_accountant"},
        ]
      },
      {
        :name => "Sales",
        :list => [
          { :title => "Director, Advertising Sales (San Francisco and New York)", :href => "/careers/director_advertising_sales"},
          { :title => "Sales Development Rep", :href => "/careers/sales_development_rep"},
        ]
      },
      {
        :name => "HR",
        :list => [
          { :title => "Lead Recruiter (Contract)", :href => "/careers/lead_recruiter_contract"},
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
