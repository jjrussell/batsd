class Tools::BrandOffersController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  def create_brand
    brand_name = params[:name]
    brand = Brand.new(:name => brand_name)
    success = brand.save
    json = { :success => success, :brand => { :name => brand.name, :id => brand.id } }
    json.merge!({:error => brand.errors.first}) unless success
    render(:json => json)
  end

  def add_offer
    brand = Brand.find(params[:brand])
    brand.offers << Offer.find(params[:offer])
    json = { :success => brand.save}.to_json
    render(:json => json)
  end

  def remove_offer
    brand = Brand.find(params[:brand])
    brand.offers.delete(Offer.find(params[:offer]))
    json = { :success => brand.save}.to_json
    render(:json => json)
  end

  def offers
    brand = Brand.find(params[:id])
    offers = []
    brand.offers.each do |offer|
      offers << {:id => offer.id, :name => offer.search_result_name }
    end
    render(:json => offers.to_json)
  end
end
