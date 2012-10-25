class Api::Client::AdsController < Api::ClientController
  before_filter :set_scope, :only => :index

  def index
    render({ :json => { :count => @offers.length, :offers => @offers } })
  end

  private
  def set_scope
    @offers = Offer.select(%w( offers.id offers.name name_suffix bid item_type device_types self_promote_only )).order(:name)
    @offers = @offers.scoped_by_partner_id(params['partner_id']) if params['partner_id']
    @offers = @offers.active if params['active'] == '1'
  end
end
