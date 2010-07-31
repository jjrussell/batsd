class PartnersController < WebsiteController
  layout 'tabbed'
  
  current_tab :tools
  
  filter_access_to :all
  
  before_filter :find_partner, :only => [ :show ]

  def index
  end

  def show
  end
  
private
  def find_partner
    @partner = Partner.find(params[:id]) rescue nil
    if @partner.nil?
      flash[:error] = "Could not find an partner with ID: #{params[:id]}"
      redirect_to tools_index_path
    end
  end
end