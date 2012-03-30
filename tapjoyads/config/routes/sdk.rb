Tapjoyad::Application.routes.draw do
  match 'healthz' => 'healthz#index'

  namespace :agency_api do
    resources :apps, :only => [:index, :show, :create, :update]
    resources :partners, :only => [:index, :show, :create, :update] do
      collection do
        post :link
      end
    end
    resources :currencies, :only => [:index, :show, :create, :update]
  end

  resources :reporting_data, :only => :index do
    collection do
      get :udids
    end
  end

  resources :sdk, :only => [:index, :show] do
    collection do
      get :license
      get :popup
    end
  end

  match 'adways_data' => 'adways_data#index'
  match 'brooklyn_packet_data' => 'brooklyn_packet_data#index'
  match 'ea_data' => 'ea_data#index'
  match 'fluent_data' => 'fluent_data#index'
  match 'glu_data' => 'glu_data#index'
  match 'gogii_data' => 'gogii_data#index'
  match 'loopt_data' => 'loopt_data#index'
  match 'ngmoco_data' => 'ngmoco_data#index'
  match 'pinger_data' => 'pinger_data#index'
  match 'pocketgems_data' => 'pocketgems_data#index'
  match 'sgn_data' => 'sgn_data#index'
  match 'zynga_data' => 'zynga_data#index'
  match 'tapulous_marketing' => 'tapulous_marketing#index'
end
