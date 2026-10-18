Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      get "auth/google", to: "auth#google"
      get "auth/google/callback", to: "auth#callback"
      get "auth/me", to: "auth#me"

      resource :profile, only: %i[show update], controller: "profiles"
      post "profile/avatar", to: "profiles#upload_avatar"
      delete "profile/avatar", to: "profiles#destroy_avatar"

      resources :notes
      resources :videos, only: %i[index show]
      resources :sources, only: %i[index]
      resources :captures, only: %i[index create]

      get "settings/extension_sites", to: "extension_sites#index"
      put "settings/extension_sites/:key", to: "extension_sites#update"

      namespace :admin do
        get "dashboard", to: "dashboard#show"
        get "users", to: "users#index"
        patch "users/:id/premium", to: "users#update_premium"
        post "premium/bulk", to: "premium#bulk"
        get "settings", to: "settings#show"
        patch "settings", to: "settings#update"
        get "sources", to: "sources#index"
        patch "sources", to: "sources#update"
        get "extension_sites", to: "extension_sites#index"
        patch "extension_sites", to: "extension_sites#update"
      end
    end
  end
end
