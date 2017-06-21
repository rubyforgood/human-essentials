Rails.application.routes.draw do

  devise_for :users
  resources :admins, except: [:destroy] do
    collection do
      post :invite_user
    end
  end

  scope path: ':organization_id' do

    resources :users
    resource :organization do
      collection do
        get :manage
      end
    end

    resources :adjustments
    resources :transfers, only: [:index, :create, :new, :show]
    resources :storage_locations do
      member do
        get :inventory
      end
    end

    resources :distributions, only: [:index, :create, :new, :show] do
      get :print, on: :member
      post :reclaim, on: :member
    end

    resources :barcode_items
    resources :dropoff_locations
    resources :diaper_drive_participants, except: [:destroy]
    resources :items
    resources :partners

    resources :donations do
      patch :add_item, on: :member
      patch :remove_item, on: :member
    end

    get 'dashboard', to: 'dashboard#index'

  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get 'pages/:name', to: 'static#page'
  root "static#index"
end
