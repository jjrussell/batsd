class LooptDataController < ApplicationController
  include AuthenticationHelper

  before_filter 'loopt_authenticate'

  def index
    return unless verify_params([:date])

    partner = Partner.find('f6e76e3f-9d7b-426c-948f-18f1cb160789')

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
