class ReportingDataController < ApplicationController
  include Curbit::Controller

  layout false

  before_filter :lookup_user_and_authenticate

  rate_limit :index, :key => proc { |c| "#{c.params[:username]}.#{c.params[:partner_id]}.#{c.params[:page].to_i.to_s}" }, :max_calls => 6, :time_limit => 5.minutes, :wait_time => 1.minute, :status => 420, :unless => proc {|c| c.params[:cache] == '1'}
  rate_limit :udids, :key => proc { |c| "#{c.params[:username]}.#{c.params[:offer_id]}.#{c.params[:date].to_i.to_s}" }, :max_calls => 2, :time_limit => 1.hour, :wait_time => 1.hour, :status => 420

  before_filter :lookup_stats, :only => :index

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

    if params[:date] =~ /^\d{4}-\d{2}$/
      data = UdidReports.get_monthly_report(offer.id, params[:date])
    elsif params[:date] =~ /^\d{4}-\d{2}-\d{2}$/
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
    Time.zone = params[:timezone].to_i if params[:timezone].present?
  end

  def lookup_stats
    start_time = Time.zone.parse(params[:date]) rescue nil
    if !(params[:date] =~ /^\d{4}-\d{2}-\d{2}$/) || start_time.nil?
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

    @total_offers = partners.inject(0) { |sum, partner| sum + partner.offers.size }
    @page_size = params[:page_size].to_i
    @page_size = ( @page_size > 0 ) ? ( @page_size > 200 ? 200 : @page_size ) : 100
    @total_pages = (@total_offers.to_f / @page_size).ceil
    @current_page = params[:page].to_i
    @current_page = (@current_page > 0) ? (@current_page <= @total_pages ? @current_page : @total_pages) : 1

    need_to_skip = (@current_page - 1) * @page_size
    need_to_show = @page_size

    partner_ids = partners.map(&:id)

    Offer.find(:all, :conditions => ["partner_id IN (?)", partner_ids], :limit => "#{need_to_skip},#{need_to_show}").each do |offer|
      appstats = maybe_cache("reporting_data.#{offer.id}.#{start_time.to_i}") do
        Appstats.new(offer.id, {
          :start_time => start_time,
          :end_time   => start_time + 24.hours,
          :stat_types => (Stats::STAT_TYPES - ['ranks']),
        })
      end

      @appstats_list << [ offer, appstats ]
    end
  end

  def maybe_cache(key)
    if params[:cache] == '1'
      Mc.get_and_put(key, false, 2.minutes) do
        yield
      end
    else
      yield
    end
  end
end
