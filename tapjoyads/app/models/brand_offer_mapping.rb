class BrandOfferMapping < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :offer
  belongs_to :brand

  validates_presence_of :offer, :brand
  before_create :get_new_allocation
  after_commit_on_create  :redistribute_allocation
  after_commit_on_destroy :redistribute_allocation

  named_scope :mappings_by_offer, lambda { |offer_id| {:conditions => [ "offer_id = ?", offer_id ] }}

  private
  def get_new_allocation
    cardinality = BrandOfferMapping.mappings_by_offer(offer).count + 1
    self.allocation = 100 / cardinality
  end

  def redistribute_allocation
    offer_mappings = BrandOfferMapping.mappings_by_offer(offer)
    cardinality = offer_mappings.count
    return true if cardinality == 0

    base_allocation = 100 / cardinality
    excess = (100 - (base_allocation * cardinality))

    offer_mappings.each do |brand_offer|
      next if brand_offer.id == self.id
      brand_offer.allocation = base_allocation + ( (excess -= 1) >= 0 ? 1 : 0 )
      brand_offer.save!
    end
  end
end
