class Tools::BrandOffersController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

#  def index
#  end
  def create_brand
    puts "\n\n\n\n\n\n\n\n#{params.inspect}\n\n\n\n\n\n\n\n\n\n"
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
    offers = brand.offers
    render(:json => offers.to_json)
  end
end
