class ReportingDataController < WebsiteController
  include Curbit::Controller
  
  layout false
  
  before_filter :lookup_user_and_authenticate
  before_filter :lookup_stats, :only => :index
  
  rate_limit :index, :key => proc { |c| c.params[:username] }, :max_calls => 5, :time_limit => 5.minutes, :wait_time => 1.minute, :status => 420
  rate_limit :udids, :key => proc { |c| "#{c.params[:username]}.#{c.params[:offer_id]}" }, :max_calls => 2, :time_limit => 1.hour, :wait_time => 1.hour, :status => 420
  
  def index
    respond_to do |format|
      format.xml
      format.json
    end
  end
  
  def udids
    offer = Offer.find(:first, :conditions => ["id = ? AND partner_id IN (?)", params[:offer_id], @user.partners])
    unless offer.present?
      render :text => "Unknown offer id", :status => 404
      return
    end
    
    if params[:date] =~ /^[0-9]{4}-[0-9]{2}$/
      data = UdidReports.get_monthly_report(offer.id, params[:date])
    elsif params[:date] =~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/
      data = UdidReports.get_daily_report(offer.id, params[:date])
    else
      render :text => "Invalid date", :status => 404
      return
    end
    
    if data.blank?
      render :text => "No UDID report exists for this date", :status => 404
      return
    end
    
    send_data(data, :type => 'text/csv', :filename => "#{offer.id}_#{params[:date]}.csv")
  end
  
private

  def lookup_user_and_authenticate
    params[:username] = params[:email] if params[:username].blank?
    return unless verify_params([:date, :username, :api_key])
    
    @user = User.find_by_username(params[:username])
    
    if @user.nil? || @user.api_key != params[:api_key]
      render :text => "Unknown user or invalid api key", :status => 403
      return
    end
    
    Time.zone = @user.time_zone
  end

  def lookup_stats
    start_time = Time.zone.parse(params[:date]) rescue nil
    if start_time.nil?
      render :text => "Invalid date", :status => 400
      return
    end

    @date = start_time.strftime("%Y-%m-%d")
    @appstats_list = []
    
    if params[:partner_id].present?
      partners = []
      p = @user.partners.find_by_id(params[:partner_id])
      partners << p unless p.nil?
    else
      partners = @user.partners
    end
    
    partners.each do |partner|
      partner.offers.each do |offer|
        appstats = Appstats.new(offer.id, {
          :start_time => start_time,
          :end_time => start_time + 24.hours})
        
        @appstats_list << [ offer, appstats ]
      end
    end
  end
  
end