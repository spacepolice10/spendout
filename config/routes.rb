Rails.application.routes.draw do
  root "budgets#current"
  get "landing" => "home#show", as: :landing
  get "once" => "home#once", as: :once
  get "tour(/:feature)" => "home#tour", as: :tour,
    constraints: { feature: /#{Regexp.union([ *Tour::FEATURES.keys, "finish" ])}/ }
  resource :currency_reference, only: :show
  resource :locale, only: :update
  resource :user, only: :show

  resources :budgets, only: %i[ new create destroy ] do
    resources :features, only: [] do
      patch :favorite, on: :member
    end
    resource :report, only: :show
    resources :categories, only: %i[ index show update destroy ]
    resources :allocations, shallow: true do
      patch :finish, on: :member
      patch :reopen, on: :member
    end
    resources :expenses, only: %i[ index new create show destroy ], shallow: true
    resources :incomes, only: %i[ index new create show destroy ], shallow: true
    resources :records, only: :index
    resources :exchanges, only: %i[ new create ]
    resources :recurrences, only: %i[ index new create show edit update ], shallow: true do
      patch :finish, on: :member
    end
    resources :lenses, only: %i[ index new destroy ] do
      get :edit, on: :collection
      patch :move, on: :member
    end
    resource :rollover, only: :create
    resource :most_expensive_categories, only: %i[ new create ]
    resource :rate_info, only: %i[ new create edit update ]
    resource :upcoming_recurrences, only: :create
    resources :sources, shallow: true do
      resources :exchanges, only: %i[ new create ]
    end
  end

  resource :session, only: %i[ new create destroy ] do
    scope module: :sessions do
      resource :auth_code, only: %i[ show create ]
    end
  end
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
