class Games::MyAppsController < GamesController
  rescue_from Mogli::Client::ClientException, :with => :handle_mogli_exceptions
  rescue_from Errno::ECONNRESET, :with => :handle_errno_exceptions
  rescue_from Errno::ETIMEDOUT, :with => :handle_errno_exceptions
  before_filter :require_gamer, :except => [ ]

  def index
    device_id = current_device_id
    @device = Device.new(:key => device_id) if device_id.present?
    if @device.present?
      @external_publishers = ExternalPublisher.load_all_for_device(@device)
      if params[:load] == 'earn'
        currency = Currency.find_by_id(params[:currency_id])
        @show_offerwall = @device.has_app?(currency.app_id) if currency
        @offerwall_external_publisher = ExternalPublisher.new(currency) if @show_offerwall
      end
    end

    render :layout => "games"
  end

  def show
    device_id = current_device_id
    @device = Device.new(:key => device_id) if device_id.present?
    @currency = Currency.find_by_id(params[:id])
    @external_publisher = ExternalPublisher.new(@currency)

    respond_to do |f|
      f.html { render :layout => "games" } 
      f.js { render :layout => false }
    end
  end

  def share
  end

end
