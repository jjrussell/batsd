class EaDataController < ApplicationController
  include AuthenticationHelper

  before_filter 'ea_authenticate'

  def index
    return unless verify_params([:date])

    partner = Partner.find('f2b5ae99-cd46-4b3c-ad27-6d8f12f60ccf')

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
