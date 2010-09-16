#
# This patch extends active merchant's CreditCard class to include and validate amounts.
# It also validates that the card type used is an accepted type.
#
module ActiveMerchant
  module Billing
    class CreditCardWithAmount < CreditCard
      ACCEPTED_CARD_TYPES = %w( visa master discover american_express )
      
      attr_accessor :amount
      
      alias_method :orig_before_validate, :before_validate
      def before_validate
        orig_before_validate
        self.amount = amount.to_i
      end
      
      alias_method :orig_validate, :validate
      def validate
        orig_validate
        errors.add :amount, "must be at least $5" if amount < 500
      end
      
      alias_method :orig_validate_card_type, :validate_card_type
      def validate_card_type
        errors.add :type, "is required" if type.blank?
        errors.add :type, "is not accepted" unless ACCEPTED_CARD_TYPES.include?(type)
      end
    end
  end
end
