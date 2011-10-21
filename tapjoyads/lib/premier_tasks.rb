class PremierTasks

  def self.set_exclusivity_and_premier_discounts
    Partner.find_each do |partner|
      save_partner = false

      # expire exclusivity levels
      if partner.needs_exclusivity_expired?
        partner.expire_exclusivity_level
        save_partner = true
      elsif partner.exclusivity_expires_on && partner.exclusivity_expires_on == Date.today + 7
        # spam partner with emails
      end

      # recalculate the premier_discount
      partner.recalculate_premier_discount
      save_partner ||= partner.premier_discount_changed?

      partner.save! if save_partner
    end
  end

end
