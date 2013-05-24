class Api::Client::CampaignsController < Api::ClientController
  before_filter :set_scope, :only => :index

  include ActsAsPageable
  pageable_resource :offers, :only => :index

  include Api::Client::ApiSchema
  api_schema

  def index
  end

  def show
    @campaign = Offer.select(%w( id name item_id bid )).find(params[:id])
  end

  private
  def set_scope
    if can? :read, Offer
      @offers = Offer.select(%w( offers.id offers.name bid )).campaigns
      @offers = @offers.scoped_by_partner_id(params['partner_id']) if params['partner_id']
      @offers = @offers.active if params['active'] == '1'
    end
  end
end
