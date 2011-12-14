module ActionView
  module Helpers
    module NumberHelper
      def currency_to_number(currency_string)
        currency_string.gsub(/[,$]/, '').to_f
      end
    end
  end
end
