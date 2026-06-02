# frozen_string_literal: true

say "Configurando Autenticação, Perfis e Permissões...", :green

def application_record_path
  "app/models/application_record.rb"
end

def ensure_application_record_exists
  return if File.exist?(application_record_path)

  empty_directory File.dirname(application_record_path)
  create_file application_record_path, <<~RUBY
    class ApplicationRecord < ActiveRecord::Base
      primary_abstract_class
    end
  RUBY
end

ensure_application_record_exists

generate "devise:install"
generate "devise User"
generate "model JwtDenylist jti:string:index exp:datetime --no-test-framework"

inject_into_file "app/models/jwt_denylist.rb", after: "class JwtDenylist < ApplicationRecord\n" do
  <<~RUBY
    include Devise::JWT::RevocationStrategies::Denylist

    self.table_name = 'jwt_denylists'
  RUBY
end

inject_into_file "app/models/user.rb", after: "devise :database_authenticatable, :registerable,\n         :recoverable, :rememberable, :validatable" do
  ",\n         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist"
end

inject_into_file "config/initializers/devise.rb", before: /^end$/ do
  <<~RUBY

    config.jwt do |jwt|
      jwt.secret = ENV.fetch('DEVISE_JWT_SECRET_KEY') { Rails.application.credentials.secret_key_base }
      jwt.dispatch_requests = [
        ['POST', %r{^/login$}]
      ]
      jwt.revocation_requests = [
        ['DELETE', %r{^/logout$}]
      ]
      jwt.expiration_time = 1.day.to_i
    end
  RUBY
end

generate "rolify Role User"
generate "model Profile user:references first_name:string last_name:string phone:string document:string --no-test-framework"

inject_into_file "app/models/user.rb", after: "class User < ApplicationRecord\n" do
  "  has_one :profile, dependent: :destroy\n  accepts_nested_attributes_for :profile\n\n"
end

inject_into_file "app/models/user.rb", before: /^end$/ do
  <<~RUBY

    after_create :build_default_profile

    private

    def build_default_profile
      create_profile unless profile
    end
  RUBY
end

if @selected_template_preset.to_s == "ddd"
  IDENTITY_MODELS_ROOT = "app/domains/identity/infrastructure/active_record/models"
  SHARED_MODELS_ROOT = "app/domains/shared/infrastructure/active_record/models"

  def relocate_identity_model(file_name)
    source_path = "app/models/#{file_name}.rb"
    destination_path = "#{IDENTITY_MODELS_ROOT}/#{file_name}.rb"

    return unless File.exist?(source_path)

    empty_directory IDENTITY_MODELS_ROOT
    create_file destination_path, File.read(source_path), force: true
    remove_file source_path
  end
  
  def relocate_shared_model(file_name)
    source_path = "app/models/#{file_name}.rb"
    destination_path = "#{SHARED_MODELS_ROOT}/#{file_name}.rb"

    return unless File.exist?(source_path)

    empty_directory SHARED_MODELS_ROOT
    create_file destination_path, File.read(source_path), force: true
    remove_file source_path
  end

  def require_identity_models_in_routes
    routes_path = "config/routes.rb"
    return unless File.exist?(routes_path)

    routes_requirements = <<~RUBY
      require Rails.root.join("app/domains/identity/infrastructure/active_record/models/jwt_denylist")
      require Rails.root.join("app/domains/identity/infrastructure/active_record/models/role")
      require Rails.root.join("app/domains/identity/infrastructure/active_record/models/profile")
      require Rails.root.join("app/domains/identity/infrastructure/active_record/models/user")

    RUBY

    routes_content = File.read(routes_path)
    return if routes_content.include?('app/domains/identity/infrastructure/active_record/models/user')

    create_file routes_path, "#{routes_requirements}#{routes_content}", force: true
  end

  %w[user jwt_denylist role profile].each do |model_name|
    relocate_identity_model(model_name)
  end
  
  relocate_shared_model("application_record")

  require_identity_models_in_routes
end

say "Autenticação, Perfis e Permissões configurados com sucesso!", :blue
