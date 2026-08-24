Rails.application.routes.draw do
  root "budgets#current"
  get "landing" => "home#show", as: :landing
  resource :currency_reference, only: :show

  resources :budgets, only: %i[ new create destroy ] do
    resources :allocations, shallow: true
    resources :expenses, shallow: true
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

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
