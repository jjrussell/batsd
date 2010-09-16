module ActiveMerchant
  module Billing
    class CreditCardWithAmount < CreditCard
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
    end
  end
end
