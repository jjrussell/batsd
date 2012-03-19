class BrandOfferMapping < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :offer
  belongs_to :brand

  validates_presence_of :offer, :brand
  validates_numericality_of :allocation, :greater_than => 0, :less_than_or_equal_to => 100
  before_validation :get_new_allocation
  after_commit  :redistribute_allocation, :on => :create

  scope :mappings_by_offer, lambda { |offer_id| {:conditions => [ "offer_id = ?", offer_id ] }}

  private
  def get_new_allocation
    unless self.allocation
      cardinality = BrandOfferMapping.mappings_by_offer(offer).count + 1
      self.allocation = 100 / cardinality
    end
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
