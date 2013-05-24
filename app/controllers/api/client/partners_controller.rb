class Api::Client::PartnersController < Api::ClientController
  before_filter :set_scope, :only => :index

  include ActsAsPageable
  pageable_resource :partners, :only => :index

  include Api::Client::ApiSchema
  api_schema

  def index
  end

  def show
    @partner = Partner.select(%w( id name )).find(params[:id])
  end

  private
  def set_scope
    @partners = Partner.select(%w( id name))
    @partners = @offers.scoped_by_partner_id(params['user_id']) if params['user_id']

    query if params['query']
  end

  def query
    @partners = @partners.where(Partner.arel_table[:name].matches("%#{params['query']}%"))
  end
end
