# frozen_string_literal: true

def rewrite_api_routes
  routes_content = String.new(<<~RUBY)
    Rails.application.routes.draw do
      scope :api do
        scope :v1 do
  RUBY

  if @include_user_setup
    routes_content << <<~RUBY
          scope :identity do
            post "login", to: "api/v1/identity/sessions#create"
            post "refresh", to: "api/v1/identity/sessions#refresh"
            delete "logout", to: "api/v1/identity/sessions#destroy"
            delete "kill-session/:id", to: "api/v1/identity/sessions#kill", as: :kill_session
            post "signup", to: "api/v1/identity/registrations#create"
            get "me", to: "api/v1/identity/profiles#show_current"
            resources :users, controller: "api/v1/identity/users", except: %i[new edit]
            resources :profiles, controller: "api/v1/identity/profiles", only: %i[index show update]
            resources :roles, controller: "api/v1/identity/roles", except: %i[new edit]
            resources :permissions, controller: "api/v1/identity/permissions", except: %i[new edit]
            resources :access_sessions, controller: "api/v1/identity/access_sessions", only: %i[index show destroy]
          end

    RUBY
  end

  routes_content << <<~RUBY
        end
      end
    end
  RUBY

  create_file "config/routes.rb", routes_content, force: true
end

say "Normalizando estrutura final da API por domínio...", :green

apply_template "presets/api_lite/structure.rb"
apply_template "presets/api_lite/foundation.rb"
apply_template "presets/api_lite/zeitwerk.rb"
apply_template "presets/api_lite/api_cleanup.rb"

%w[
  app/controllers
  app/helpers
  app/assets
  app/views
  app/mailers
  app/jobs
  app/models
].each do |path|
  remove_dir path if Dir.exist?(path)
end

rewrite_api_routes

say "Estrutura final da API organizada por domínio.", :blue
