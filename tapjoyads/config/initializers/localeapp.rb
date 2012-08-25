if Rails.env.development?
  require 'localeapp/rails'

  Localeapp.configure do |config|
    config.api_key = 'EcebMF7f8Xu3MaV8DzXHixGxSsUZDihb6EpndNtvmUqjuICCum'
    config.polling_environments = []
    config.sending_environments = [:development]
  end
end
