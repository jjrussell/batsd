class ReportingController < WebsiteController
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper
  
  layout 'tabbed'
  
  filter_access_to :all
  before_filter :find_offer, :only => [ :show, :export, :download_udids ]
  before_filter :setup, :only => [ :show, :export, :aggregate, :export_aggregate ]
  before_filter :set_platform, :only => [ :aggregate, :export_aggregate ]
  before_filter :nag_user_about_payout_info, :only => [:show]

  def index
    unless current_partner_offers.empty?
      if session[:last_shown_app].present?
        app = current_partner.apps.find_by_id(session[:last_shown_app])
        redirect_to reporting_path(app.primary_offer) and return unless app.nil?
      end
      redirect_to reporting_path(current_partner_offers.first)
    end
  end

  def show
    session[:last_shown_app] = @offer.item_id if @offer.item_type == 'App'

    respond_to do |format|
      format.html do
        @udids = UdidReports.get_available_months(@offer.id)
      end
      format.json do
        load_appstats
        render :json => { :data => @appstats.graph_data(:offer => @offer, :admin => false)}.to_json
      end
    end
  end

  def export
    load_appstats
    data = @appstats.to_csv
    send_data(data.join("\n"), :type => 'text/csv', :filename => "#{@offer.id}_#{@start_time.to_s(:yyyy_mm_dd)}_#{@end_time.to_s(:yyyy_mm_dd)}.csv")
  end
  
  def download_udids
    data = UdidReports.get_monthly_report(@offer.id, params[:date])
    send_data(data, :type => 'text/csv', :filename => "#{@offer.id}_#{params[:date]}.csv")
  end
  
  def api
  end
  
  def regenerate_api_key
    current_user.regenerate_api_key
    if current_user.save
      flash[:notice] = "You have successfully regenerated your API key."
    else
      flash[:error] = "Error regenerating the API key. Please try again."
    end
    redirect_to api_reporting_path
  end

  def aggregate
    @partner = current_partner
    respond_to do |format|
      format.html do
        render 'shared/aggregate'
      end
      format.json do
        options = { :start_time => @start_time, :end_time => @end_time, :granularity => @granularity, :include_labels => true, :stat_prefix => get_stat_prefix('partner') }
        @appstats = Appstats.new(@partner.id, options)
        render :json => { :data => @appstats.graph_data }
      end
    end
  end

  def export_aggregate
    @partner = current_partner
    options = { :start_time => @start_time, :end_time => @end_time, :granularity => @granularity, :include_labels => true, :stat_prefix => get_stat_prefix('partner') }
    @appstats = Appstats.new(@partner.id, options)
    data = @appstats.to_csv
    send_data(data.join("\n"), :type => 'text/csv', :filename => "#{@platform}_#{@start_time.to_s(:yyyy_mm_dd)}_#{@end_time.to_s(:yyyy_mm_dd)}.csv")
  end
  
private
  
  def find_offer
    @offer = current_partner.offers.find_by_id(params[:id], :include => 'item')
    if @offer.nil?
      flash[:notice] = 'Unknown offer id'
      redirect_to reporting_index_path and return
    end
  end
  
  def load_appstats
    return @appstats if defined? @appstats
    options = { :start_time => @start_time, :end_time => @end_time, :granularity => @granularity, :include_labels => true }
    @appstats = Appstats.new(@offer.id, options)
  end

  def setup
    @start_time, @end_time, @granularity = Appstats.parse_dates(params[:date], params[:end_date], params[:granularity])
  end
end
