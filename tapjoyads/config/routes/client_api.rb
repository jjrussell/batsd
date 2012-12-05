Tapjoyad::Application.routes.draw do
  # TODO:  non namespaced routing
  namespace :api do
    namespace :client, :defaults => { :format => 'json' } do
      resources :ads do
        resource :reports do
          get :sessions
        end
      end
      resources :campaigns do
        resources :ads, :only => [:index] do
        end
      end
      resources :partners, :only => [] do
        resources :ads, :only => [:index]
        resources :campaigns, :only => [:index, :show]
        resource :reports do
          get :sessions
        end
      end
    end
  end
end
