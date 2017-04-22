Rails.application.routes.draw do
  resources :transfers, only: [:index, :create, :new, :show]

  resources :tickets, only: [:index, :create, :new, :show] do
    get :print, on: :member
    post :reclaim, on: :member
  end

  resources :barcode_items

  resources :dropoff_locations

  resources :items 

  resources :partners

  resources :donations do 
    patch :track, on: :member
    patch :remove_item, on: :member
    patch :complete, on: :member
  end

  resources :inventories

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
