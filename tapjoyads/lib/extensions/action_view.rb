module ActionView
  module Helpers
    module TranslationHelper

      def translate_with_rescue_interpolation_errors(key, options = {})
        begin
          translate_without_rescue_interpolation_errors(key, options)
        rescue I18n::MissingInterpolationArgument
          translate_without_rescue_interpolation_errors(key, options.merge(:locale => I18n.default_locale))
        end
      end

      alias_method_chain :translate, :rescue_interpolation_errors
      alias :t :translate

    end
  end
end
