class ToolsController < WebsiteController
  include MemcachedHelper
  
  filter_access_to [ :new_order, :create_order, :payouts, :create_payout, :money ]
  
  def index
  end
  
  def payouts
    @partners = Partner.to_payout
  end
  
  def create_payout
    partner = Partner.find(params[:id])
    cutoff_date = partner.payout_cutoff_date - 1.day
    amount = (params[:amount].to_f * 100).to_i
    payout = partner.payouts.build(:amount => amount, :month => cutoff_date.month, :year => cutoff_date.year)
    render :json => { :success => payout.save }
  end
  
  def new_order
  end
  
  def create_order
    order = Order.new(params[:order])
    order.amount = (params[:order][:amount].to_f * 100).to_i
    if order.save
      flash[:notice] = 'The order was successfully created.'
    else
      flash[:error] = 'The order could not be created.'
    end
    redirect_to new_order_tools_path
  end
  
  def money
    @money_stats = get_from_cache('statz.money') || render(:text => "Not Available") and return
    @time_ranges = @money_stats.keys
    
    @stat_types = @money_stats[@time_ranges.first].keys
    
    @last_updated = get_from_cache('statz.last_updated') || Time.at(8.hours.to_i)
    
  end
  
end
