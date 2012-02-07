I18n.backend.class.send(:include, I18n::Backend::Fallbacks)

I18n.backend.send(:init_translations)
AVAILABLE_LOCALES = Set.new(I18n.backend.send(:translations).keys.collect(&:to_s))
