class AdwaysDataController < ApplicationController
  include AuthenticationHelper

  before_filter 'adways_authenticate'

  def index
    return unless verify_params([:date])

    partner = Partner.find('174e61e3-d1e0-42c0-95f5-69fddccea354')

    start_time = Time.zone.parse(params[:date])

    @date = start_time.iso8601[0,10]
    @appstats_list = []

    partner.offers.each do |offer|
      appstats = Appstats.new(offer.id, {
        :start_time => start_time,
        :end_time => start_time + 24.hours})

      @appstats_list << [ offer, appstats ]
    end

    render 'shared/publisher_data'
  end
end
