Rails.application.routes.draw do
  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end
  post "/graphql", to: "graphql#execute"
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  # Feature flag management is admin-only:
  # - /admin/feature_flags  → native ActiveAdmin page (see app/admin/feature_flags.rb)
  # - /admin/flipper        → the full Flipper UI, mounted behind Devise auth
  authenticate :admin_user do
    mount Flipper::UI.app(Flipper) => "/admin/flipper", as: :admin_flipper
  end

  # JSON API — user auth (JWT sessions) and platform-admin sessions.
  namespace :api do
    namespace :v1 do
      post "sign_up", to: "users#create"
      post "sign_in", to: "sessions#create"
      get "me", to: "users#me"
      delete "sign_out", to: "sessions#destroy"

      post "admin_sessions", to: "admin_sessions#create"
      get "admin_sessions/validate", to: "admin_sessions#show"
      delete "admin_sessions/current", to: "admin_sessions#destroy"
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
