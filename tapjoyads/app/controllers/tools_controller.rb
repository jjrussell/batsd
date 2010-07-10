class ToolsController < WebsiteController
  
  filter_access_to [ :new_order, :create_order, :payouts, :create_payout, :money, :new_transfer, :create_transfer ]
  
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
  
  def new_transfer
  end
  
  def create_transfer
    
    begin
      Partner.transaction do      
        partner = Partner.find(params[:partner_id])
        amount = (params[:transfer_amount].to_f * 100).to_i
        payout = partner.payouts.build(:amount => amount, :month => Time.zone.now.month, :year => Time.zone.now.year, :payment_method => 3)
        payout.save!
    
        order = Order.new(:partner_id => partner.id, :amount => amount, :status => 1, :payment_method => 3)
        order.save!
      
        if params[:marketing_amount].to_f > 0
          marketing_order = Order.new(:partner_id => partner.id, 
            :amount => (params[:marketing_amount].to_f * 100).to_i, :status => 1, :payment_method => 2)
          marketing_order.save!
        end
      
      end
    
      flash[:notice] = 'The transfer was successfully created.'
    
    # rescue Exception => e
    #       Rails.logger.info e
    #       flash[:error] = 'The transfer could not be created.'
    end
  
    redirect_to new_transfer_tools_path
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
    @money_stats = Mc.get('statz.money') || (render(:text => "Not Available") and return)
    @time_ranges = @money_stats.keys
    
    @stat_types = @money_stats[@time_ranges.first].keys
    
    @last_updated = Mc.get('statz.last_updated') || Time.at(8.hours.to_i)
    
    @total_balance = Mc.get('statz.balance') || 'Not Available'
    @total_pending_earnings = Mc.get('statz.pending_earnings') || 'Not Available'
    
  end
  
end
