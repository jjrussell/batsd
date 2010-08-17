class PartnersController < WebsiteController
  layout 'tabbed'
  
  current_tab :tools
  
  filter_access_to :all
  
  before_filter :find_partner, :only => [ :show ]
  
  def index
    if params[:q]
      query = params[:q].gsub("'", '')
      @partners = Partner.search(query).scoped(:include => [ :offers, :users ]).paginate(:page => params[:page])
    else
      @partners = Partner.scoped(:order => 'created_at DESC', :include => [ :offers, :users ]).paginate(:page => params[:page])
    end
  end
  
  def show
  end
  
private
  
  def find_partner
    @partner = Partner.find_by_id(params[:id])
    if @partner.nil?
      flash[:error] = "Could not find partner with ID: #{params[:id]}"
      redirect_to partners_path
    end
  end
  
end
