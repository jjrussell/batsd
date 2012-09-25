Tapjoyad::Application.routes.draw do
  match 'healthz' => 'healthz#index'
  get 'rails/info' => 'rails#info'
  if (app = Rails.application).config.assets.compile
    mount app.assets => app.config.assets.prefix
  end
end
