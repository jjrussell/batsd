class RaffleManagerController < WebsiteController
  layout 'tabbed'
  
  current_tab :tools
  
  filter_access_to :all
  
  before_filter :find_raffle_ticket, :only => [ :edit, :update ]
  
  def index
    if params[:type].blank?
      @raffles = RaffleTicket.get_active_raffles
      @subtab = 'Active'
    else
      now_epoch = Time.zone.now.to_f.to_s
      if params[:type] == 'complete'
        condition = "type = 'R' and ends_at < '#{now_epoch}'"
        @subtab = 'Complete'
      elsif params[:type] == 'upcoming'
        condition = "type = 'R' and starts_at > '#{now_epoch}'"
        @subtab = 'Upcoming'
      else
        condition = "type = 'R'"
        @subtab = 'All'
      end
      @raffles = []
      RaffleTicket.select(:where => condition) { |r| @raffles << r }
    end
    
  end
  
  def new
    @page_title = 'Create new raffle'
    @raffle_ticket = RaffleTicket.new unless defined? @raffle_ticket
    @form_action = :create
    @form_method = :post
    render :action => :edit
  end
  
  def create
    @raffle_ticket = RaffleTicket.new
    @raffle_ticket.has_icon = false
    # @raffle_ticket.app_id = # TODO: Put Tap n win app_id here
    
    if update_raffle
      RaffleTicket.cache_active_raffles
      flash[:notice] = 'Sucessfully created raffle'
      redirect_to "/raffle_manager/#{@raffle_ticket.key}/edit"
    else
      new()
    end
  end
  
  def edit
    @page_title = 'Edit raffle'
    @form_action = :update
    @form_method = :put
  end
  
  def update
    if update_raffle
      flash[:notice] = 'Sucessfully updated raffle'
      redirect_to "/raffle_manager/#{@raffle_ticket.key}/edit"
    else
      edit()
    end
  end
  
private

  def update_raffle
    starts_at = Time.zone.parse(params[:raffle_ticket][:starts_at])
    ends_at = Time.zone.parse(params[:raffle_ticket][:ends_at])
    
    @raffle_ticket.name = params[:raffle_ticket][:name]
    @raffle_ticket.description = params[:raffle_ticket][:description]
    @raffle_ticket.prize_value = params[:raffle_ticket][:prize_value]
    @raffle_ticket.prize_url = params[:raffle_ticket][:prize_url]
    @raffle_ticket.starts_at = starts_at
    @raffle_ticket.ends_at = ends_at
    @raffle_ticket.email_status = params[:raffle_ticket][:email_status]
    @raffle_ticket.distribution_status = params[:raffle_ticket][:distribution_status]
    
    if params[:raffle_ticket][:icon]
      bucket = S3.bucket(BucketNames::VIRTUAL_GOODS)
      bucket.put("icons/#{@raffle_ticket.key}.png", params[:raffle_ticket][:icon].read, {}, 'public-read')
      @raffle_ticket.has_icon = true
    end
    
    if params[:raffle_ticket][:name].blank?
      flash[:error] = 'Name cannot be blank'
    elsif starts_at.nil? || ends_at.nil?
      flash[:error] = 'Invalid date'
    else
      @raffle_ticket.save!
      return true
    end

    return false
  end

  def find_raffle_ticket
    @raffle_ticket = RaffleTicket.new(:key => params[:id])
    if @raffle_ticket.is_new
      flash[:error] = "Could not find an raffle with ID: #{params[:id]}"
      redirect_to raffle_manager_index_path
    end
  end
  
end