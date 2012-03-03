class Tools::BrandOffersController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  def create_brand
    brand_name = params[:name]
    puts brand_name
    brand = Brand.new(:name => brand_name)
    brand.save!
    render(:json => brand.to_json)
  end

  def add_offer
    brand = Brand.find(params[:brand])
    brand.offers << Offer.find(params[:offer])
    render(:json => brand.save.to_json)
  end

  def remove_offer
    brand = Brand.find(params[:brand])
    brand.offers.delete(Offer.find(params[:offer]))
    render(:json => brand.save.to_json)
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
