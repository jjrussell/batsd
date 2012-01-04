class ReengagementRewardsController < ApplicationController
  ReengagementOffer

  def show
    verify_params([:id])
    todays_reengagement_offer = ReengagementOffer.find_in_cache params[:id]
    raise 'Could not find today\'s re-engagement offer in memcache with id #{params[:id]}' if todays_reengagement_offer.nil?
    @todays_day_number = todays_reengagement_offer.day_number
    app = App.find_in_cache todays_reengagement_offer.app_id
    @app_icon_url = app.get_icon_url
    puts @app_icon_url
    @partner_name = app.partner.name
    @reengagement_offers = ReengagementOffer.find_list_in_cache todays_reengagement_offer.app_id
    @currencies = @reengagement_offers.collect {|r| Currency.find_in_cache r.currency_id}
  end

  def index
    verify_params([:udid, :local_timestamp, :publisher_user_id, :app_id])

    @reengagement_offers = ReengagementOffer.find_list_in_cache params[:app_id]
    raise "No re-engagement offers found in memcache for app #{params[:app_id]}" if @reengagement_offers.nil?
    device = Device.new :key => params[:udid]
    @reengagement_offer = @reengagement_offers.detect{ |r| !device.has_app?(r.id) }
    
    unless @reengagement_offer.nil?# && should_reward?
      click = Click.new(:key => "#{params[:udid]}.#{@reengagement_offer.id}", :consistent => true)
      Downloader.get_with_retry "#{API_URL}/connect?app_id=#{click.offer_id}&udid=#{click.udid}&consistent=true"

      next_reengagement_offer = @reengagement_offers[@reengagement_offer.day_number]
      Click.new(:key => "#{params[:udid]}.#{next_reengagement_offer.id}") unless next_reengagement_offer.nil?
    end
  end

  private

  def should_reward?
    seconds_since_last_reengagement_reward = Time.at(params[:local_timestamp].to_i) - Time.at(@click.clicked_at.to_i)
    @click.manually_resolved_at.nil? && seconds_since_last_reengagement_reward > 23.hours && seconds_since_last_reengagement_reward < 48.hours
  end

end
