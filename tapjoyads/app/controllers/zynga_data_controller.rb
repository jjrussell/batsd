class ZyngaDataController < ApplicationController
  include AuthenticationHelper

  ZYNGA_PARTNER_ID = "64e40a83-4724-4ba4-9b38-1c8ca906777a"
  @@zynga_partner = nil

  before_filter 'zynga_authenticate'

  def index
    return unless verify_params([:date])

    @@zynga_partner = Partner.find(ZYGNA_PARTNER_ID) unless @@zynga_partner

    start_time = Time.zone.parse(params[:date])

    @date = start_time.iso8601[0,10]
    @appstats_list = []

    @@zynga_partner.offers.each do |offer|
      appstats = Appstats.new(offer.id, {
        :start_time => start_time,
        :end_time => start_time + 24.hours})

      @appstats_list << [ offer, appstats ]
    end

    render 'shared/publisher_data'
  end
end
