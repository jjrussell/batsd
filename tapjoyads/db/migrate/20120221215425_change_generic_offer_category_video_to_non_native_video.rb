class ChangeGenericOfferCategoryVideoToNonNativeVideo < ActiveRecord::Migration
  def self.up
    GenericOffer.all.each do |o|
      o.category = 'Non-Native Video' if o.category == 'Video'
      o.category = nil if o.category.blank?
      o.category = 'Non-Native Video' if o.url =~ /youtube\.com/
      o.save(false)
    end
  end

  def self.down
    GenericOffer.update_all({:category => 'Video'}, {:category => 'Non-Native Video'})
  end
end
