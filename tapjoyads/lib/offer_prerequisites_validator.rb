class OfferPrerequisitesValidator < ActiveModel::Validator
  def validate(record)
    if record.prerequisite_offer_id.present?
      record.errors[:prerequisite_offer_id] << 'prerequisite offer must come from same partner.' if record.prerequisite_offer.present? && (record.partner_id != record.prerequisite_offer.partner_id)
      record.errors[:prerequisite_offer_id] << 'prerequisite offer found in exclusion prerequisite offers.' if record.get_exclusion_prerequisite_offer_ids.include?(record.prerequisite_offer_id)
    end
    if record.get_exclusion_prerequisite_offer_ids.present?
      record.get_exclusion_prerequisite_offer_ids.each do |id|
        if Offer.find_by_id(id).nil?
          record.errors[:exclusion_prerequisite_offer_ids] << 'can not find one of the exclusion prerequisite offers.'
          break
        elsif record.partner_id != Offer.find_by_id(id).partner_id
          record.errors[:exclusion_prerequisite_offer_ids] << 'exclusion prerequisite offers must come from same partner.'
          break
        end
      end
    end
    if record.x_partner_prerequisites.present?
      record.errors[:x_partner_prerequisites] << 'prerequisite offers found in exclusion prerequisite offers.' if (record.get_x_partner_prerequisites & record.get_x_partner_exclusion_prerequisites).any?
    end
    if record.x_partner_exclusion_prerequisites.present?
      record.errors[:x_partner_exclusion_prerequisites] << 'prerequisite offer found in exclusion prerequisite offers.' if record.get_x_partner_exclusion_prerequisites.include?(record.prerequisite_offer_id)
    end
  end
end
