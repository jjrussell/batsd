class ReengagementRewardsController < ApplicationController
  ReengagementOffer

  layout 'mobile', :only => 'show'

  def show
    verify_params([:id])
    @reengagement_offer = ReengagementOffer.find_in_cache params[:id]
    raise 'Could not find today\'s re-engagement offer.' if @reengagement_offer.nil?
    @app = App.find_in_cache @reengagement_offer.app_id
    @partner = Partner.find @app.partner_id
    @reengagement_offers = ReengagementOffer.find_list_in_cache @reengagement_offer.app_id
    user_agent = request.env['HTTP_USER_AGENT'].downcase
    if user_agent.index('iphone') || user_agent.index('android') || user_agent.index('ipod') || user_agent.index('ipad')
      @button_link = 'http://ok'
    else
      @button_link = ''
    end
  end

  def index
    verify_params([:udid, :timestamp, :publisher_user_id, :app_id])
    @reengagement_offers = ReengagementOffer.find_list_in_cache params[:app_id]
    raise "No re-engagement offers found in memcache for app #{params[:app_id]}" if @reengagement_offers.nil?
    device = Device.new :key => params[:udid]
    @reengagement_offer = @reengagement_offers.detect{ |r| !device.has_app?(r.id) }
    if @reengagement_offer.present? && @reengagement_offer.enabled? && !@reengagement_offer.hidden?
      click = Click.find("#{params[:udid]}.#{@reengagement_offer.id}")
      if @reengagement_offer.day_number == 0 || should_reward?(click)
        Downloader.get_with_retry "#{API_URL}/connect?app_id=#{params[:app_id]}&udid=#{params[:udid]}&consistent=true"
        device.set_last_run_time! @reengagement_offer.id
      end
      if @reengagement_offer.day_number < @reengagement_offers.length
        next_reengagement_offer = @reengagement_offers.detect{ |r| r.day_number == @reengagement_offer.day_number + 1 }
        create_reengagement_click(next_reengagement_offer) if next_reengagement_offer.present?
      end
    else
      @reengagement_offer = nil
    end
  end

  private

  def create_reengagement_click(reengagement_offer)
    data = {
      :publisher_app      =>  App.find_in_cache(params[:app_id]),
      :udid               =>  params[:udid],
      :publisher_user_id  =>  params[:publisher_user_id],
      :source             =>  'reengaement',
      :currency_id        =>  reengagement_offer.currency_id,
      :viewed_at          =>  Time.zone.now
    }
    Downloader.get_with_retry(reengagement_offer.primary_offer.click_url(data))
  end

  def should_reward?(click)
    true
    # seconds_since_last_reengagement_reward = Time.at(params[:timestamp].to_i) - Time.at(click.clicked_at.to_i)
    # click.manually_resolved_at.nil? && seconds_since_last_reengagement_reward > 24.hours && seconds_since_last_reengagement_reward < 48.hours
  end

end
