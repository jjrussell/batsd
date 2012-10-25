Tapjoyad::Application.routes.draw do
  # TODO:  non namespaced routing
  namespace :api do
    namespace :client do
      resources :partners, :only => [] do
        resources :ads, :only => [:index]
        resources :campaigns, :only => [:index]
      end
    end
  end
end
