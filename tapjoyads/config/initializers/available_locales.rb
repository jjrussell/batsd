I18n.backend.class.send(:include, I18n::Backend::Fallbacks)

I18n.backend.send(:init_translations)
AVAILABLE_LOCALES_ARRAY = I18n.backend.send(:translations).keys.collect(&:to_s)
AVAILABLE_LOCALES = Set.new(AVAILABLE_LOCALES_ARRAY)

AVAILABLE_LOCALES_HASHES = {}

AVAILABLE_LOCALES_ARRAY.each do |locale|
  path = "config/locales/#{locale}.yml"

  raise "Missing localization file for: #{locale}. Expected to find: #{path}" unless File.exists? path

  File.open(path) do |f|
    AVAILABLE_LOCALES_HASHES[locale] = f.mtime.to_i
  end
end
