class Api::Client::AdsController < Api::ClientController
  before_filter :set_scope, :only => :index

  include ActsAsPageable
  pageable_resource :offers, :only => :index

  include Api::Client::ApiSchema
  api_schema

  def index
  end

  private
  def set_scope
    if can? :read, Offer
      @offers = Offer.select(%w( offers.id offers.name name_suffix bid item_type device_types self_promote_only )).order(:name)
      if params['campaign_id']
        @offers = @offers.scoped_by_item_id(params['campaign_id'])
      elsif params['partner_id']
        @offers = @offers.scoped_by_partner_id(params['partner_id'])
      end
      @offers = @offers.active if params['active'] == '1'
    end
  end
end
