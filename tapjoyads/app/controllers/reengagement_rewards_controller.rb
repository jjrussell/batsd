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
      Rails.logger.info "&&&&&&&&&&&&&&&&&&&&&& #{@reengagement_offer.day_number} #{@reengagement_offer.id}"
      click = Click.find("#{params[:udid]}.#{@reengagement_offer.id}")
      if click.present? && should_reward?(click)
        Rails.logger.info '&&&&&&&&&&&&&&&&&&&&&& click present, downloading...'
        Downloader.get_with_retry "#{API_URL}/connect?app_id=#{click.advertiser_app_id}&udid=#{click.udid}&consistent=true"
        next_reengagement_offer = @reengagement_offers.detect{ |r| r.day_number == @reengagement_offer.day_number + 1 }
        Rails.logger.info "&&&&&&&&&&&&&&&&&&&&&& next reengagement offer exists? #{next_reengagement_offer.present?}"
        create_reengagement_click(next_reengagement_offer) if next_reengagement_offer.present?
      elsif @reengagement_offer.day_number == 0
        next_reengagement_offer = @reengagement_offers.detect{ |r| r.day_number == 1 }
        create_reengagement_click next_reengagement_offer
      else
        @reengagement_offer = nil
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
    Rails.logger.info '======================== downloader started'
    Downloader.get_with_retry(reengagement_offer.primary_offer.click_url(data)) rescue Rails.logger.info '======================== downloader failed'
    Rails.logger.info '======================== downloader finished'
  end

  def should_reward?(click)
    true
    # seconds_since_last_reengagement_reward = Time.at(params[:timestamp].to_i) - Time.at(click.clicked_at.to_i)
    # click.manually_resolved_at.nil? && seconds_since_last_reengagement_reward > 24.hours && seconds_since_last_reengagement_reward < 48.hours
  end

end
