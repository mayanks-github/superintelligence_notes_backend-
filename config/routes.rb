Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      get "auth/google", to: "auth#google"
      get "auth/google/callback", to: "auth#callback"
      get "auth/me", to: "auth#me"

      resources :notes
      resources :videos, only: %i[index show]
    end
  end
end
