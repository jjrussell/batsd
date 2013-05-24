class PocketgemsDataController < ApplicationController
  include AuthenticationHelper

  before_filter 'pocketgems_authenticate'

  def index
    return unless verify_params([:date])

    partner = Partner.find('9827ebca-d1ad-4dea-b61b-f38dd0d298c1')

    start_time = Time.zone.parse(params[:date])

    # PST:
    start_time = start_time + 8.hours

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
