def set_up_sidekiq
  require 'sidekiq/web'
  require 'sidekiq-scheduler/web'

  if Rails.env.production?
    Sidekiq::Web.use Rack::Auth::Basic do |username, password|
      compare = ->(s1, s2) { ActiveSupport::SecurityUtils.secure_compare(s1, s2) }
      compare.call(username, ENV["SIDEKIQ_USERNAME"]) && compare.call(password, ENV["SIDEKIQ_PASSWORD"])
    end
  end

  mount Sidekiq::Web => '/sidekiq'
  Sidekiq::Web.set :session_secret, Rails.application.secrets[:secret_key_base]
end

def set_up_flipper
  flipper_app = Flipper::UI.app(Flipper.instance) do |builder|
    builder.use Rack::Auth::Basic do |username, password|
      username == ENV["FLIPPER_USERNAME"] && password == ENV["FLIPPER_PASSWORD"]
    end
  end
  mount flipper_app, at: "/flipper"
end

Rails.application.routes.draw do
  devise_for :users

  set_up_sidekiq
  set_up_flipper

  # This is where a superadmin CRUDs all the things
  get :admin, to: "admin#dashboard"
  namespace :admin do
    get :dashboard
    resources :base_items
    resources :organizations
    resources :partners, except: %i[new create destroy]
    resources :users
    resources :barcode_items
    resources :feedback_messages do
      get :resolve
    end
  end

  # These are globally accessible
  resources :feedback_message, only: [:create]

  namespace :api, defaults: { format: "json" } do
    namespace :v1 do
      resources :partner_requests, only: %i(create show)
      resources :partner_approvals, only: :create
      resources :family_requests, only: %i(create show)
    end
  end

  scope path: ":organization_id" do
    resources :users

    # Users that are organization admins can manage the organization itself
    resource :organization, only: [:show]
    resource :organization, path: :manage, only: %i(edit update) do
      collection do
        post :invite_user
        put :deactivate_user
        put :reactivate_user
        post :resend_user_invitation
        post :promote_to_org_admin
        post :demote_to_user
      end
    end

    resources :adjustments, except: %i(edit update)
    resources :audits do
      post :finalize
    end
    resources :transfers, only: %i(index create new show destroy)
    resources :storage_locations do
      collection do
        post :import_csv
        post :import_inventory
      end
      member do
        get :inventory
      end
    end

    resources :distributions do
      get :print, on: :member
      collection do
        get :schedule
        get :pickup_day
      end
      patch :picked_up, on: :member
    end

    resources :barcode_items do
      get :find, on: :collection
      get :font, on: :collection
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
    resources :manufacturers, except: [:destroy] do
      collection do
        post :import_csv
      end
    end
    resources :vendors, except: [:destroy] do
      collection do
        post :import_csv
      end
    end
    resources :kits do
      member do
        get :allocations
        post :allocate
      end
    end

    resources :items do
      patch :restore, on: :member
    end
    resources :partners do
      collection do
        post :import_csv
      end
      member do
        get :approve_application
        get :approve_partner
        post :invite
        post :re_invite
        post :recertify_partner
        put :deactivate
        put :reactivate
      end
    end

    resources :partner_groups do
      resources :memberships, controller: :partner_group_memberships, only: %i(create destroy)
    end

    resources :diaper_drives
    resources :donations do
      # collection do
      #   get :scale
      #   post :scale_intake
      # end
      patch :add_item, on: :member
      patch :remove_item, on: :member
    end

    resources :purchases
    # MODIFIED route by adding destroy to
    resources :requests, only: %i(index new show destroy) do
      member do
        post :start
      end
    end

    resources :requests, except: %i(destroy) do
      get :print, on: :member
      post :cancel, on: :member
      collection do
        get :partner_requests
      end
    end

    get "dashboard", to: "dashboard#index"
    get "forecasting/distributions", to: "forecasting/distributions#index"
    get "forecasting/purchases", to: "forecasting/purchases#index"
    get "forecasting/donations", to: "forecasting/donations#index"
  end

  resources :attachments, only: %i(destroy)

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get "pages/:name", to: "static#page"
  get "/register", to: "static#register"
  resources :account_requests, only: [:new, :create] do
    collection do
      get 'confirmation'
      get 'confirm'
      get 'received'

      get 'invalid_token'
    end
  end

  root "static#index"
end
