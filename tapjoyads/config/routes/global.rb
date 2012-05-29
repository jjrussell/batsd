Tapjoyad::Application.routes.draw do
  match 'healthz' => 'healthz#index'
  get 'rails/info' => 'rails#info'
end
