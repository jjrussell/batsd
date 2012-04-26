require 'lib/extensions/i18n_bom_fix'
I18n.backend.class.send(:include, I18n::Backend::Fallbacks)

I18n.backend.send(:init_translations)
I18n.available_locales = I18n.backend.available_locales

AVAILABLE_LOCALES_ARRAY = I18n.backend.send(:translations).keys.collect(&:to_s)
AVAILABLE_LOCALES = Set.new(AVAILABLE_LOCALES_ARRAY)
