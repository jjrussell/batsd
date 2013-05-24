#
# This patch extends active merchant's CreditCard class to include and validate amounts.
# It also validates that the card type used is an accepted type.
#
module ActiveMerchant
  module Billing
    class CreditCardWithAmount < CreditCard
      ACCEPTED_CARD_TYPES = %w( visa master discover american_express )

      def amount
        @amount ||= 0
      end

      def amount=(value)
        @amount = value.to_i
      end

      alias_method :orig_validate, :validate
      def validate
        orig_validate
        validate_amount
      end

      def validate_amount
        errors.add :amount, "must be at least $5" if amount < 500
      end

      alias_method :orig_validate_card_type, :validate_card_type
      def validate_card_type
        errors.add :number, "does not map to an accepted card type" unless ACCEPTED_CARD_TYPES.include?(type)
      end

      def valid_amount?
        validate_amount
        errors.empty?
      end
    end
  end
end
