class ReengagementRewardsController < ApplicationController
  ReengagementOffer

  layout 'mobile'

  def show
    verify_params([:id])
    @reengagement_offer = ReengagementOffer.find_in_cache params[:id]
    raise 'Could not find today\'s re-engagement offer.' if @reengagement_offer.nil?
    @app = App.find_in_cache @reengagement_offer.app_id
    @reengagement_offers = ReengagementOffer.find_list_in_cache @reengagement_offer.app_id
  end

  def index
    verify_params([:udid, :timestamp, :publisher_user_id, :app_id])
    @reengagement_offers = ReengagementOffer.find_list_in_cache params[:app_id]
    raise "No re-engagement offers found in memcache for app #{params[:app_id]}" if @reengagement_offers.nil?
    device = Device.new :key => params[:udid]
    @reengagement_offer = @reengagement_offers.detect{ |r| !device.has_app?(r.id) }
    if @reengagement_offer.present? && @reengagement_offer.enabled? && !@reengagement_offer.hidden?
      puts "&&&&&&&&&&&&&&&&&&&&&& #{@reengagement_offer.day_number} #{@reengagement_offer.id}"
      click = Click.find("#{params[:udid]}.#{@reengagement_offer.id}")
      if click.present? && should_reward?(click)
        puts '&&&&&&&&&&&&&&&&&&&&&& click present, downloading...'
        Downloader.get_with_retry "http://localhost:3000/connect?app_id=#{click.advertiser_app_id}&udid=#{click.udid}&consistent=true"
        next_reengagement_offer = @reengagement_offers.detect{ |r| r.day_number == @reengagement_offer.day_number + 1 }
        puts "&&&&&&&&&&&&&&&&&&&&&& next reengagement offer exists? #{next_reengagement_offer.present?}"
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
    puts '======================== downloader started'
    Downloader.get_with_retry(reengagement_offer.primary_offer.click_url(data)) rescue puts '======================== downloader failed'
    puts '======================== downloader finished'
  end

  def should_reward?(click)
    true
    # seconds_since_last_reengagement_reward = Time.at(params[:timestamp].to_i) - Time.at(click.clicked_at.to_i)
    # click.manually_resolved_at.nil? && seconds_since_last_reengagement_reward > 24.hours && seconds_since_last_reengagement_reward < 48.hours
  end

end
