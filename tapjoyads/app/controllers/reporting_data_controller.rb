class ReportingDataController < WebsiteController
  include TapjoyCurbit::Curbit::Controller
  
  layout false
  
  before_filter :lookup_user_and_authenticate, :lookup_stats
  
  rate_limit :index, :key => proc { |c| c.params[:username] }, :max_calls => 5, :time_limit => 5.minutes, :wait_time => 1.minute, :status => 420
  
  def index
  end
  
private

  def lookup_user_and_authenticate
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
    
    @user.partners.each do |partner|
      partner.offers.each do |offer|
        appstats = Appstats.new(offer.id, {
          :start_time => start_time,
          :end_time => start_time + 24.hours})
        
        @appstats_list << [ offer, appstats ]
      end
    end
  end
  
end