class Dashboard::Tools::BrandOffersController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  def create
    brand_offer = BrandOfferMapping.new(:offer_id => params[:offer], :brand_id => params[:brand])
    json = { :success => brand_offer.save}.to_json
    render(:json => json)
  end

  def delete
    brand_offer = BrandOfferMapping.find_by_brand_id_and_offer_id(params[:brand], params[:offer])
    json = { :success => brand_offer.destroy}.to_json
    render(:json => json)
  end
end
