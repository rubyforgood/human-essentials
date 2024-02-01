def set_up_flipper
  flipper_app = Flipper::UI.app(Flipper.instance) do |builder|
    builder.use Rack::Auth::Basic do |username, password|
      username == ENV["FLIPPER_USERNAME"] && password == ENV["FLIPPER_PASSWORD"]
    end
  end
  mount flipper_app, at: "/flipper"
end

Rails.application.routes.draw do
  get 'distributions_by_county/report'
  devise_for :users, controllers: {
    sessions: "users/sessions",
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  if Rails.env.production?
    authenticate :user, lambda { |u| u.has_role?(Role::SUPER_ADMIN) } do
      mount Coverband::Reporters::Web.new, at: '/coverage'
    end
  end

  #
  # Mount web interface to see delayed job status and queue length.
  # Visible only to logged in users with the `super_admin` role
  #
  authenticated :user, ->(user) { user.has_role?(Role::SUPER_ADMIN) } do
    mount DelayedJobWeb, at: "/delayed_job"
  end

  set_up_flipper

  # Add route partners/dashboard so that we can define it as partner_user_root
  get 'partners/dashboard' => 'partners/dashboards#show', as: :partner_user_root
  namespace :partners do
    resource :dashboard, only: [:show]
    resource :help, only: [:show]
    resources :requests, only: [:show, :new, :index, :create]
    resources :individuals_requests, only: [:new, :create]
    resources :family_requests, only: [:new, :create]
    resources :users, only: [:index, :new, :create, :edit, :update]
    resource :profile, only: [:show, :edit, :update]
    resource :approval_request, only: [:create]

    resources :children, except: [:destroy] do
      post :active
    end
    resources :families
    resources :authorized_family_members
    resources :distributions, only: [:index] do
      get :print, on: :member
    end
  end

  # This is where a superadmin CRUDs all the things
  get :admin, to: "admin#dashboard"
  namespace :admin do
    get :dashboard
    resources :base_items
    resources :organizations
    resources :partners, except: %i[new create]
    resources :users do
      delete :remove_role
      post :add_role
      get :resource_ids, on: :collection
    end
    resources :barcode_items
    resources :account_requests, only: [:index] do
      post :reject, on: :collection
      get :for_rejection, on: :collection
    end
    resources :questions
    resources :broadcast_announcements
  end

  match "/404", to: "errors#not_found", via: :all
  match "/500", to: "errors#internal_server_error", via: :all

  scope path: ":organization_id" do
    resources :users do
      get :switch_to_role, on: :collection
      post :partner_user_reset_password, on: :collection
    end

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

    namespace :reports do
      resources :annual_reports, only: [:index, :show], param: :year do
        post :recalculate, on: :member
      end
    end

    resources :transfers, only: %i(index create new show destroy)
    resources :storage_locations do
      put :deactivate
      put :reactivate
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
        get :itemized_breakdown
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
    resources :product_drive_participants, except: [:destroy] do
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
        put :deactivate
        put :reactivate
      end
    end

    resources :profiles, only: %i(edit update)
    resources :items do
      patch :restore, on: :member
      patch :remove_category, on: :member
    end
    resources :item_categories, except: [:index]
    resources :partners do
      collection do
        post :import_csv
      end
      member do
        get :profile
        patch :profile
        get :approve_application
        post :invite
        post :single_step_invite_and_approve
        post :invite_partner_user
        post :recertify_partner
        put :deactivate
        put :reactivate
      end
    end

    resources :partner_groups, only: [:new, :create, :edit, :update]

    resources :product_drives
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
    resources :requests, only: %i(index new show) do
      member do
        post :start
      end
    end

    resources :requests, except: %i(destroy) do
      resource :cancelation, only: [:new, :create], controller: 'requests/cancelation'
      get :print, on: :member
      collection do
        get :partner_requests
      end
    end

    get "dashboard", to: "dashboard#index"
    get "historical_trends/distributions", to: "historical_trends/distributions#index"
    get "historical_trends/purchases", to: "historical_trends/purchases#index"
    get "historical_trends/donations", to: "historical_trends/donations#index"
  end

  resources :attachments, only: %i(destroy)
  get "distributions/calendar", to: "distributions#calendar"

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get "help", to: "help#show"
  get "pages/:name", to: "static#page"
  get "/privacypolicy", to: "static#privacypolicy"
  resources :account_requests, only: [:new, :create] do
    collection do
      get 'confirmation'
      get 'confirm'
      get 'received'

      get 'invalid_token'
    end
  end
  resources :broadcast_announcements

  root "static#index"
end
