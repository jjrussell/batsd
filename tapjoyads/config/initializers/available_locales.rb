I18n.backend.class.send(:include, I18n::Backend::Fallbacks)

I18n.backend.send(:init_translations)
AVAILABLE_LOCALES_ARRAY = I18n.backend.send(:translations).keys.collect(&:to_s)
AVAILABLE_LOCALES = Set.new(AVAILABLE_LOCALES_ARRAY)
