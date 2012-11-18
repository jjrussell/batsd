if defined? Localeapp
  require 'localeapp/rails'

  Localeapp.configure do |config|
    config.api_key = 'EcebMF7f8Xu3MaV8DzXHixGxSsUZDihb6EpndNtvmUqjuICCum'
    config.polling_environments = [:development]
    config.sending_environments = []
    config.reloading_environments = []
  end
end
