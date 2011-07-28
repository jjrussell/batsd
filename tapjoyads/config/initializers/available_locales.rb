I18n.backend.send(:init_translations)
AVAILABLE_LOCALES = I18n.backend.send(:translations).keys.collect(&:to_s)
