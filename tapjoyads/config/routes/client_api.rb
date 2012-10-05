Tapjoyad::Application.routes.draw do
  # TODO:  non namespaced routing
  [ 'client_api' ].each do |s|
    namespace :client_api, :as => nil, :path => s do
      resources :partners, :only => [] do
        resources :ads, :only => [:index]
      end
    end
  end
end
