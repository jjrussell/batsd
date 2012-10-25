class Api::Client::CampaignsController < Api::ClientController
  before_filter :set_scope, :only => :index

  def index
    @campaigns = @offers.map {|o| {:campaign => { :name => o.name, :id => o.id } } }
    render({ :json => { :count => @campaigns.length, :campaigns => @campaigns } })
  end

  private
  def set_scope
    @offers = Offer.select(%w( offers.id offers.name)).campaigns
    @offers = @offers.scoped_by_partner_id(params['partner_id']) if params['partner_id']
    @offers = @offers.active if params['active'] == '1'
  end
end
