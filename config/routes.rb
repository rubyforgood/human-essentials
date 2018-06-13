Rails.application.routes.draw do
  devise_for :users
  resources :admins do
    collection do
      post :invite_user
    end
  end
  resources :canonical_items

  scope path: ":organization_id" do
    resources :users
    resource :organization do
      collection do
        get :manage
      end
    end

    resources :adjustments, except: %i(edit update)
    resources :transfers, only: %i(index create new show)
    resources :storage_locations do
      collection do
        post :import_csv
        post :import_inventory
      end
      member do
        get :inventory
      end
    end

    resources :distributions, only: %i(index create new show) do
      get :print, on: :member
      post :reclaim, on: :member
    end

    resources :barcode_items do
      get :find, on: :collection
    end
    resources :donation_sites do
      collection do
        post :import_csv
      end
    end
    resources :diaper_drive_participants, except: [:destroy] do
      collection do
        post :import_csv
      end
    end
    resources :items
    resources :partners do
      collection do
        post :import_csv
      end
    end

    resources :donations do
      collection do
        get :scale
        post :scale_intake
      end
      patch :add_item, on: :member
      patch :remove_item, on: :member
    end

    resources :purchases

    get "dashboard", to: "dashboard#index"
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get "pages/:name", to: "static#page"
  root "static#index"
end
