class OfferPrerequisitesValidator < ActiveModel::Validator
  def validate(record)
    if record.prerequisite_offer_id.present?
      record.errors[:prerequisite_offer_id] << 'prerequisite offer must come from same partner.' if record.prerequisite_offer.present? && (record.partner_id != record.prerequisite_offer.partner_id)
      record.errors[:prerequisite_offer_id] << 'prerequisite offer can not be the same as negative prerequisite offer.' if record.get_negative_prerequisite_offer_ids.include?(record.prerequisite_offer_id)
    end
    if record.get_negative_prerequisite_offer_ids.present?
      record.get_negative_prerequisite_offer_ids.each do |id|
        if Offer.find_by_id(id).nil?
          record.errors[:negative_prerequisite_offer_ids] << 'can not find one of the negative prerequisite offers.'
          break
        elsif record.partner_id != Offer.find_by_id(id).partner_id
          record.errors[:negative_prerequisite_offer_ids] << 'negative prerequisite offers must come from same partner.'
          break
        end
      end
    end
  end
end
