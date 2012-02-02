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
    if user_agent =~ /iphone|android|ipod|ipad/
      @button_link = 'http://ok'
    else
      @button_link = ''
    end
  end

  def index
    verify_params([:udid, :timestamp, :publisher_user_id, :app_id])
    @reengagement_offers = ReengagementOffer.find_list_in_cache params[:app_id]
    if @reengagement_offers.length > 1
      raise "No re-engagement offers found in memcache for app #{params[:app_id]}" if @reengagement_offers.nil?
      device = Device.new :key => params[:udid]
      @reengagement_offer = @reengagement_offers.detect{ |r| !device.has_app?(r.id) }
      Rails.logger.info "&&&&& reengagement #{@reengagement_offer.day_number} #{@reengagement_offer.id}" if @reengagement_offer.present?
      if @reengagement_offer.present? && @reengagement_offer.enabled? && !@reengagement_offer.hidden?
        click = Click.find("#{params[:udid]}.#{@reengagement_offer.id}")
        if @reengagement_offer.day_number == 0 || click.present? && !click.successfully_rewarded? && should_reward?(click)
          click.resolve! if click.present?
          device.set_last_run_time! @reengagement_offer.id
          Rails.logger.info "&&&&& click resolved!" if click.present?
        end
        if @reengagement_offer.day_number < @reengagement_offers.length
          next_reengagement_offer = @reengagement_offers.detect{ |r| r.day_number == @reengagement_offer.day_number + 1 }
          create_reengagement_click(next_reengagement_offer, Time.at(params[:timestamp].to_f)) if next_reengagement_offer.present?
        end
      else
        @reengagement_offer = nil
      end
    end
  end

  private

  def create_reengagement_click(reengagement_offer, timestamp=Time.zone.now)
    data = {
      :publisher_app      =>  App.find_in_cache(params[:app_id]),
      :udid               =>  params[:udid],
      :publisher_user_id  =>  params[:publisher_user_id],
      :source             =>  'reengagement',
      :currency_id        =>  reengagement_offer.currency_id,
      :viewed_at          =>  timestamp
    }
    Downloader.get_with_retry(reengagement_offer.primary_offer.click_url(data))
  end

  def should_reward?(click)
    # daylight-savings weirdness and leap years are not accounted for
    (Time.at(params[:timestamp].to_i) - Time.at(click.clicked_at.to_i)) / 1.day == 1
  end

end
