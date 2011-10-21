class Tools::PremierPartnersController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  before_filter :get_account_managers
  filter_access_to :all

  def index
    if params[:q].present?
      query = params[:q].gsub("'", '')
      @partners = Partner.premier.search(query)
    elsif params[:account_manager_id].present? && params[:account_manager_id] == "none"
      @partners = Partner.premier.reject { |partner| partner.account_managers.present? }
    elsif params[:account_manager_id].present? && params[:account_manager_id] != "all"
      @partners = User.find(params[:account_manager_id]).partners.premier
    else
      @partners = Partner.premier.scoped(:include => :offer_discounts)
    end
  end

private

  def get_account_managers
    @account_managers = User.account_managers.map{|u|[u.email, u.id]}.sort
    @account_managers.unshift(["All", "all"])
    @account_managers.push(["Not assigned", "none"])
  end

end
