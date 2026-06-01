# frozen_string_literal: true

say "Configurando identidade base da API por domínio...", :green

def migration_timestamp(offset)
  (Time.now.utc + offset).strftime("%Y%m%d%H%M%S")
end

def create_identity_migration(file_suffix, content, offset:)
  create_file "db/migrate/#{migration_timestamp(offset)}_#{file_suffix}.rb", content, force: true
end

def write_identity_file(path, content)
  empty_directory File.dirname(path)
  create_file path, content, force: true
end

create_identity_migration(
  "create_identity_users",
  <<~RUBY,
    class CreateIdentityUsers < ActiveRecord::Migration[8.1]
      def change
        create_table :identity_users do |t|
          t.string :email, null: false
          t.string :password_digest, null: false
          t.string :status, null: false, default: "pending"
          t.datetime :last_login_at
          t.string :last_login_ip
          t.string :last_login_user_agent
          t.boolean :mfa_required, null: false, default: false
          t.datetime :confirmed_at
          t.timestamps
        end

        add_index :identity_users, :email, unique: true
        add_index :identity_users, :status
      end
    end
  RUBY
  offset: 0
)

create_identity_migration(
  "create_identity_profiles",
  <<~RUBY,
    class CreateIdentityProfiles < ActiveRecord::Migration[8.1]
      def change
        create_table :identity_profiles do |t|
          t.references :user, null: false, foreign_key: { to_table: :identity_users }, index: { unique: true }
          t.string :first_name
          t.string :last_name
          t.string :phone
          t.string :document
          t.string :locale, null: false, default: "pt-BR"
          t.string :timezone, null: false, default: "America/Fortaleza"
          t.timestamps
        end
      end
    end
  RUBY
  offset: 1
)

create_identity_migration(
  "create_identity_roles_and_permissions",
  <<~RUBY,
    class CreateIdentityRolesAndPermissions < ActiveRecord::Migration[8.1]
      def change
        create_table :identity_roles do |t|
          t.string :name, null: false
          t.string :slug, null: false
          t.text :description
          t.timestamps
        end

        create_table :identity_permissions do |t|
          t.string :resource, null: false
          t.string :action, null: false
          t.string :scope, null: false, default: "api"
          t.timestamps
        end

        create_table :identity_roles_users, id: false do |t|
          t.references :role, null: false, foreign_key: { to_table: :identity_roles }
          t.references :user, null: false, foreign_key: { to_table: :identity_users }
        end

        create_table :identity_permissions_roles, id: false do |t|
          t.references :role, null: false, foreign_key: { to_table: :identity_roles }
          t.references :permission, null: false, foreign_key: { to_table: :identity_permissions }
        end

        add_index :identity_roles, :slug, unique: true
        add_index :identity_permissions, %i[resource action scope], unique: true, name: "index_identity_permissions_unique_rule"
        add_index :identity_roles_users, %i[role_id user_id], unique: true
        add_index :identity_permissions_roles, %i[role_id permission_id], unique: true, name: "index_identity_permissions_roles_unique"
      end
    end
  RUBY
  offset: 2
)

create_identity_migration(
  "create_identity_access_sessions",
  <<~RUBY,
    class CreateIdentityAccessSessions < ActiveRecord::Migration[8.1]
      def change
        create_table :identity_access_sessions do |t|
          t.references :user, null: false, foreign_key: { to_table: :identity_users }
          t.string :refresh_token_digest, null: false
          t.string :ip_address
          t.string :user_agent
          t.string :device_type
          t.string :location_hint
          t.datetime :last_seen_at
          t.datetime :expires_at, null: false
          t.datetime :revoked_at
          t.timestamps
        end

        add_index :identity_access_sessions, :refresh_token_digest, unique: true
        add_index :identity_access_sessions, :expires_at
      end
    end
  RUBY
  offset: 3
)

write_identity_file(
  "app/infrastructure/persistence/application_record.rb",
  <<~RUBY
    module Persistence
      class ApplicationRecord < ActiveRecord::Base
        primary_abstract_class
      end
    end
  RUBY
)

write_identity_file(
  "app/infrastructure/security/token_service.rb",
  <<~RUBY
    require "digest"

    module Security
      class TokenService
        ACCESS_TOKEN_TTL = 15.minutes
        REFRESH_TOKEN_TTL = 30.days
        ALGORITHM = "HS256"

        def self.issue_pair(user:, session:)
          access_token = JWT.encode(
            {
              sub: user.id,
              sid: session.id,
              type: "access",
              exp: ACCESS_TOKEN_TTL.from_now.to_i
            },
            secret_key,
            ALGORITHM
          )

          refresh_token = SecureRandom.hex(48)

          {
            access_token: access_token,
            refresh_token: refresh_token,
            refresh_token_digest: digest(refresh_token),
            access_token_expires_at: ACCESS_TOKEN_TTL.from_now,
            refresh_token_expires_at: REFRESH_TOKEN_TTL.from_now
          }
        end

        def self.decode_access_token(token)
          payload, = JWT.decode(token, secret_key, true, algorithm: ALGORITHM)
          payload.with_indifferent_access
        rescue JWT::DecodeError, JWT::ExpiredSignature
          nil
        end

        def self.digest(token)
          Digest::SHA256.hexdigest(token.to_s)
        end

        def self.secret_key
          ENV.fetch("API_JWT_SECRET_KEY") { Rails.application.credentials.secret_key_base }
        end
      end
    end
  RUBY
)

write_identity_file(
  "app/infrastructure/security/device_context.rb",
  <<~RUBY
    module Security
      class DeviceContext
        def self.extract(request)
          user_agent = request.user_agent.to_s

          {
            ip_address: forwarded_ip(request),
            user_agent: user_agent,
            device_type: detect_device_type(user_agent),
            location_hint: request.headers["CF-IPCountry"].presence || request.headers["X-App-Location"].presence
          }
        end

        def self.forwarded_ip(request)
          request.headers["X-Forwarded-For"].to_s.split(",").first.presence || request.remote_ip
        end

        def self.detect_device_type(user_agent)
          return "bot" if user_agent.match?(/bot|crawler|spider/i)
          return "mobile" if user_agent.match?(/android|iphone|mobile/i)
          return "tablet" if user_agent.match?(/ipad|tablet/i)

          "desktop"
        end
      end
    end
  RUBY
)

write_identity_file(
  "app/domains/identity/models/user.rb",
  <<~RUBY
    module Identity
      module Models
        class User < ::Persistence::ApplicationRecord
          self.table_name = "identity_users"

          has_secure_password

          has_one :profile, class_name: "::Identity::Models::Profile", foreign_key: :user_id, dependent: :destroy, inverse_of: :user
          has_many :access_sessions, class_name: "::Identity::Models::AccessSession", foreign_key: :user_id, dependent: :destroy, inverse_of: :user
          has_and_belongs_to_many :roles,
                              class_name: "::Identity::Models::Role",
                                  join_table: "identity_roles_users",
                                  association_foreign_key: :role_id,
                                  foreign_key: :user_id

          enum :status, { pending: "pending", active: "active", blocked: "blocked" }, default: :pending

          validates :email, presence: true, uniqueness: true

          normalizes :email, with: ->(value) { value.to_s.strip.downcase }

          def active_for_authentication?
            active?
          end

          def permission_keys
            roles.includes(:permissions).flat_map(&:permission_keys).uniq
          end
        end
      end
    end
  RUBY
)

write_identity_file(
  "app/domains/identity/models/profile.rb",
  <<~RUBY
    module Identity
      module Models
        class Profile < ::Persistence::ApplicationRecord
          self.table_name = "identity_profiles"

          belongs_to :user, class_name: "::Identity::Models::User", inverse_of: :profile

          def full_name
            [first_name, last_name].compact.join(" ").strip
          end
        end
      end
    end
  RUBY
)

write_identity_file(
  "app/domains/identity/models/role.rb",
  <<~RUBY
    module Identity
      module Models
        class Role < ::Persistence::ApplicationRecord
          self.table_name = "identity_roles"

          has_and_belongs_to_many :users,
                              class_name: "::Identity::Models::User",
                                  join_table: "identity_roles_users",
                                  association_foreign_key: :user_id,
                                  foreign_key: :role_id

          has_and_belongs_to_many :permissions,
                              class_name: "::Identity::Models::Permission",
                                  join_table: "identity_permissions_roles",
                                  association_foreign_key: :permission_id,
                                  foreign_key: :role_id

          validates :name, :slug, presence: true
          validates :slug, uniqueness: true

          normalizes :slug, with: ->(value) { value.to_s.parameterize(separator: "_") }

          def permission_keys
            permissions.map(&:key)
          end
        end
      end
    end
  RUBY
)

write_identity_file(
  "app/domains/identity/models/permission.rb",
  <<~RUBY
    module Identity
      module Models
        class Permission < ::Persistence::ApplicationRecord
          self.table_name = "identity_permissions"

          has_and_belongs_to_many :roles,
                              class_name: "::Identity::Models::Role",
                                  join_table: "identity_permissions_roles",
                                  association_foreign_key: :role_id,
                                  foreign_key: :permission_id

          validates :resource, :action, :scope, presence: true

          def key
            [scope, resource, action].join(":")
          end
        end
      end
    end
  RUBY
)

write_identity_file(
  "app/domains/identity/models/access_session.rb",
  <<~RUBY
    module Identity
      module Models
        class AccessSession < ::Persistence::ApplicationRecord
          self.table_name = "identity_access_sessions"

          belongs_to :user, class_name: "::Identity::Models::User", inverse_of: :access_sessions

          scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

          def revoke!
            update!(revoked_at: Time.current)
          end

          def revoked?
            revoked_at.present?
          end
        end
      end
    end
  RUBY
)

write_identity_file(
  "app/domains/identity/services/permission_checker.rb",
  <<~RUBY
    module Identity
      module Services
        class PermissionChecker
          def self.allowed?(user, permission_key)
            return false unless user

            user.permission_keys.include?(permission_key)
          end
        end
      end
    end
  RUBY
)

write_identity_file(
  "app/domains/identity/services/user_manager.rb",
  <<~RUBY
    module Identity
      module Services
        class UserManager
          def self.create!(attributes)
            user = ::Identity::Models::User.new(
              email: attributes[:email],
              password: attributes[:password],
              password_confirmation: attributes[:password_confirmation],
              status: attributes[:status].presence || "active",
              mfa_required: ActiveModel::Type::Boolean.new.cast(attributes[:mfa_required])
            )

            user.build_profile(attributes.slice(:first_name, :last_name, :phone, :document, :locale, :timezone))
            assign_roles(user, attributes[:role_ids])
            user.save!
            user
          end

          def self.update!(user, attributes)
            user.assign_attributes(
              email: attributes[:email] || user.email,
              status: attributes[:status] || user.status,
              mfa_required: attributes.key?(:mfa_required) ? ActiveModel::Type::Boolean.new.cast(attributes[:mfa_required]) : user.mfa_required
            )

            if attributes[:password].present?
              user.password = attributes[:password]
              user.password_confirmation = attributes[:password_confirmation]
            end

            profile = user.profile || user.build_profile
            profile.assign_attributes(attributes.slice(:first_name, :last_name, :phone, :document, :locale, :timezone))
            assign_roles(user, attributes[:role_ids]) if attributes.key?(:role_ids)
            user.save!
            user
          end

          def self.destroy!(user)
            user.destroy!
          end

          def self.assign_roles(user, role_ids)
            return unless role_ids

            roles = ::Identity::Models::Role.where(id: Array(role_ids).reject(&:blank?))
            user.roles = roles
          end
        end
      end
    end
  RUBY
)

write_identity_file(
  "app/domains/identity/services/role_manager.rb",
  <<~RUBY
    module Identity
      module Services
        class RoleManager
          def self.create!(attributes)
            role = ::Identity::Models::Role.new(attributes.slice(:name, :slug, :description))
            assign_permissions(role, attributes[:permission_ids])
            role.save!
            role
          end

          def self.update!(role, attributes)
            role.assign_attributes(attributes.slice(:name, :slug, :description))
            assign_permissions(role, attributes[:permission_ids]) if attributes.key?(:permission_ids)
            role.save!
            role
          end

          def self.destroy!(role)
            role.destroy!
          end

          def self.assign_permissions(role, permission_ids)
            permissions = ::Identity::Models::Permission.where(id: Array(permission_ids).reject(&:blank?))
            role.permissions = permissions
          end
        end
      end
    end
  RUBY
)

write_identity_file(
  "app/domains/identity/services/permission_manager.rb",
  <<~RUBY
    module Identity
      module Services
        class PermissionManager
          def self.create!(attributes)
            ::Identity::Models::Permission.create!(attributes.slice(:resource, :action, :scope))
          end

          def self.update!(permission, attributes)
            permission.update!(attributes.slice(:resource, :action, :scope))
            permission
          end

          def self.destroy!(permission)
            permission.destroy!
          end
        end
      end
    end
  RUBY
)

write_identity_file(
  "app/domains/identity/services/profile_manager.rb",
  <<~RUBY
    module Identity
      module Services
        class ProfileManager
          def self.update!(profile, attributes)
            profile.update!(attributes.slice(:first_name, :last_name, :phone, :document, :locale, :timezone))
            profile
          end
        end
      end
    end
  RUBY
)

write_identity_file(
  "app/domains/identity/services/session_manager.rb",
  <<~RUBY
    module Identity
      module Services
        class SessionManager
          def self.revoke!(session)
            session.revoke!
            session
          end
        end
      end
    end
  RUBY
)

write_identity_file(
  "app/domains/identity/policies/base_policy.rb",
  <<~RUBY
    module Identity
      module Policies
        class BasePolicy
          attr_reader :user, :record

          def initialize(user, record)
            @user = user
            @record = record
          end

          private

          def allowed?(permission_key)
            ::Identity::Services::PermissionChecker.allowed?(user, permission_key)
          end
        end
      end
    end
  RUBY
)

{
  "user" => "users",
  "profile" => "profiles",
  "role" => "roles",
  "permission" => "permissions",
  "access_session" => "access_sessions"
}.each do |policy_name, resource_name|
  write_identity_file(
    "app/domains/identity/policies/#{policy_name}_policy.rb",
    <<~RUBY
      module Identity
        module Policies
          class #{policy_name.camelize}Policy < BasePolicy
            def index?
              allowed?("api:#{resource_name}:read")
            end

            def show?
              allowed?("api:#{resource_name}:read")
            end

            def create?
              allowed?("api:#{resource_name}:create")
            end

            def update?
              allowed?("api:#{resource_name}:update")
            end

            def destroy?
              allowed?("api:#{resource_name}:destroy")
            end
          end
        end
      end
    RUBY
  )
end

write_identity_file(
  "app/domains/identity/jobs/revoke_expired_sessions_job.rb",
  <<~RUBY
    module Identity
      module Jobs
        class RevokeExpiredSessionsJob < ActiveJob::Base
          queue_as :default

          def perform
            ::Identity::Models::AccessSession.where(revoked_at: nil).where("expires_at <= ?", Time.current).find_each do |session|
              session.revoke!
            end
          end
        end
      end
    end
  RUBY
)

write_identity_file(
  "app/domains/identity/jobs/audit_suspicious_session_job.rb",
  <<~RUBY
    module Identity
      module Jobs
        class AuditSuspiciousSessionJob < ActiveJob::Base
          queue_as :default

          def perform(session_id)
            session = ::Identity::Models::AccessSession.find_by(id: session_id)
            return unless session

            Rails.logger.warn("[identity] suspicious_session session_id=\#{session.id} user_id=\#{session.user_id} ip=\#{session.ip_address}")
          end
        end
      end
    end
  RUBY
)

write_identity_file(
  "app/interfaces/http/api/v1/identity/serializers/user_serializer.rb",
  <<~RUBY
    module Api
      module V1
        module Identity
          module Serializers
            class UserSerializer
              def self.render(user)
                {
                  id: user.id,
                  email: user.email,
                  status: user.status,
                  mfa_required: user.mfa_required,
                  confirmed_at: user.confirmed_at,
                  roles: user.roles.map { |role| { id: role.id, slug: role.slug, name: role.name } },
                  profile: user.profile && {
                    id: user.profile.id,
                    first_name: user.profile.first_name,
                    last_name: user.profile.last_name,
                    phone: user.profile.phone,
                    locale: user.profile.locale,
                    timezone: user.profile.timezone
                  }
                }
              end
            end
          end
        end
      end
    end
  RUBY
)

write_identity_file(
  "app/interfaces/http/api/v1/identity/serializers/profile_serializer.rb",
  <<~RUBY
    module Api
      module V1
        module Identity
          module Serializers
            class ProfileSerializer
              def self.render(profile)
                {
                  id: profile.id,
                  user_id: profile.user_id,
                  full_name: profile.full_name,
                  first_name: profile.first_name,
                  last_name: profile.last_name,
                  phone: profile.phone,
                  document: profile.document,
                  locale: profile.locale,
                  timezone: profile.timezone
                }
              end
            end
          end
        end
      end
    end
  RUBY
)

write_identity_file(
  "app/interfaces/http/api/v1/identity/serializers/role_serializer.rb",
  <<~RUBY
    module Api
      module V1
        module Identity
          module Serializers
            class RoleSerializer
              def self.render(role)
                {
                  id: role.id,
                  name: role.name,
                  slug: role.slug,
                  description: role.description,
                  permission_keys: role.permission_keys
                }
              end
            end
          end
        end
      end
    end
  RUBY
)

write_identity_file(
  "app/interfaces/http/api/v1/identity/serializers/permission_serializer.rb",
  <<~RUBY
    module Api
      module V1
        module Identity
          module Serializers
            class PermissionSerializer
              def self.render(permission)
                {
                  id: permission.id,
                  scope: permission.scope,
                  resource: permission.resource,
                  action: permission.action,
                  key: permission.key
                }
              end
            end
          end
        end
      end
    end
  RUBY
)

write_identity_file(
  "app/interfaces/http/api/v1/identity/serializers/access_session_serializer.rb",
  <<~RUBY
    module Api
      module V1
        module Identity
          module Serializers
            class AccessSessionSerializer
              def self.render(session)
                {
                  id: session.id,
                  user_id: session.user_id,
                  user_email: session.user&.email,
                  ip_address: session.ip_address,
                  device_type: session.device_type,
                  location_hint: session.location_hint,
                  last_seen_at: session.last_seen_at,
                  expires_at: session.expires_at,
                  revoked_at: session.revoked_at
                }
              end
            end
          end
        end
      end
    end
  RUBY
)

write_identity_file(
  "app/interfaces/http/api/v1/identity/sessions_controller.rb",
  <<~RUBY
    module Api
      module V1
        module Identity
          class SessionsController < ::Api::BaseController
            before_action :authenticate_identity_user!, only: %i[destroy kill]

            def create
              user = ::Identity::Models::User.includes(:roles).find_by(email: params[:email].to_s.downcase)

              return render_invalid_credentials unless user&.authenticate(params[:password]) && user.active_for_authentication?

              session = user.access_sessions.create!(
                ::Security::DeviceContext.extract(request).merge(
                  last_seen_at: Time.current,
                  expires_at: ::Security::TokenService::REFRESH_TOKEN_TTL.from_now
                )
              )

              tokens = ::Security::TokenService.issue_pair(user: user, session: session)
              session.update!(refresh_token_digest: tokens[:refresh_token_digest], expires_at: tokens[:refresh_token_expires_at])

              user.update!(
                last_login_at: Time.current,
                last_login_ip: session.ip_address,
                last_login_user_agent: session.user_agent
              )

              render_success(data: auth_payload(user, session, tokens), status: :created)
            end

            def refresh
              refresh_token = params[:refresh_token].to_s
              digest = ::Security::TokenService.digest(refresh_token)
              session = ::Identity::Models::AccessSession.active.find_by(refresh_token_digest: digest)

              return render_invalid_credentials unless session

              tokens = ::Security::TokenService.issue_pair(user: session.user, session: session)
              session.update!(
                refresh_token_digest: tokens[:refresh_token_digest],
                last_seen_at: Time.current,
                expires_at: tokens[:refresh_token_expires_at]
              )

              render_success(data: auth_payload(session.user, session, tokens))
            end

            def destroy
              current_identity_session&.revoke!
              render_success(data: { revoked: true })
            end

            def kill
              session = current_identity_user.access_sessions.find(params[:id])
              ::Identity::Services::SessionManager.revoke!(session)
              render_success(data: { revoked: true, session_id: session.id })
            end

            private

            def render_invalid_credentials
              render_error(
                code: "invalid_credentials",
                message: "Email ou senha inválidos",
                status: :unauthorized
              )
            end

            def auth_payload(user, session, tokens)
              {
                user: {
                  id: user.id,
                  email: user.email,
                  status: user.status,
                  permissions: user.permission_keys
                },
                session: {
                  id: session.id,
                  ip_address: session.ip_address,
                  device_type: session.device_type,
                  location_hint: session.location_hint,
                  last_seen_at: session.last_seen_at
                },
                tokens: {
                  access_token: tokens[:access_token],
                  refresh_token: tokens[:refresh_token],
                  token_type: "Bearer",
                  expires_at: tokens[:access_token_expires_at]
                }
              }
            end
          end
        end
      end
    end
  RUBY
)

write_identity_file(
  "app/interfaces/http/api/v1/identity/registrations_controller.rb",
  <<~RUBY
    module Api
      module V1
        module Identity
          class RegistrationsController < ::Api::BaseController
            def create
              user = ::Identity::Services::UserManager.create!(registration_params.to_h.symbolize_keys)

              render_success(
                data: ::Api::V1::Identity::Serializers::UserSerializer.render(user),
                status: :created
              )
            end

            private

            def registration_params
              params.require(:user).permit(
                :email,
                :password,
                :password_confirmation,
                :status,
                :mfa_required,
                :first_name,
                :last_name,
                :phone,
                :document,
                :locale,
                :timezone,
                role_ids: []
              )
            end
          end
        end
      end
    end
  RUBY
)

write_identity_file(
  "app/interfaces/http/api/v1/identity/profiles_controller.rb",
  <<~RUBY
    module Api
      module V1
        module Identity
          class ProfilesController < ::Api::BaseController
            before_action :authenticate_identity_user!
            before_action :set_profile, only: %i[show update]

            def show_current
              render_success(
                data: {
                  user: {
                    id: current_identity_user.id,
                    email: current_identity_user.email,
                    status: current_identity_user.status,
                    permissions: current_identity_user.permission_keys
                  },
                  profile: current_identity_user.profile && ::Api::V1::Identity::Serializers::ProfileSerializer.render(current_identity_user.profile)
                }
              )
            end

            def index
              authorize_policy!(::Identity::Policies::ProfilePolicy, :index, ::Identity::Models::Profile)
              profiles = ::Identity::Models::Profile.includes(:user).order(:id)
              render_success(data: profiles.map { |profile| ::Api::V1::Identity::Serializers::ProfileSerializer.render(profile) })
            end

            def show
              authorize_policy!(::Identity::Policies::ProfilePolicy, :show, @profile)
              render_success(data: ::Api::V1::Identity::Serializers::ProfileSerializer.render(@profile))
            end

            def update
              authorize_policy!(::Identity::Policies::ProfilePolicy, :update, @profile)
              profile = ::Identity::Services::ProfileManager.update!(@profile, profile_params.to_h.symbolize_keys)
              render_success(data: ::Api::V1::Identity::Serializers::ProfileSerializer.render(profile))
            end

            private

            def set_profile
              @profile = ::Identity::Models::Profile.find(params[:id])
            end

            def profile_params
              params.require(:profile).permit(:first_name, :last_name, :phone, :document, :locale, :timezone)
            end
          end
        end
      end
    end
  RUBY
)

write_identity_file(
  "app/interfaces/http/api/v1/identity/users_controller.rb",
  <<~RUBY
    module Api
      module V1
        module Identity
          class UsersController < ::Api::BaseController
            before_action :authenticate_identity_user!
            before_action :set_user, only: %i[show update destroy]

            def index
              authorize_policy!(::Identity::Policies::UserPolicy, :index, ::Identity::Models::User)
              users = ::Identity::Models::User.includes(:roles, :profile).order(:id)
              render_success(data: users.map { |user| ::Api::V1::Identity::Serializers::UserSerializer.render(user) })
            end

            def show
              authorize_policy!(::Identity::Policies::UserPolicy, :show, @user)
              render_success(data: ::Api::V1::Identity::Serializers::UserSerializer.render(@user))
            end

            def create
              authorize_policy!(::Identity::Policies::UserPolicy, :create, ::Identity::Models::User)
              user = ::Identity::Services::UserManager.create!(user_params.to_h.symbolize_keys)
              render_success(data: ::Api::V1::Identity::Serializers::UserSerializer.render(user), status: :created)
            end

            def update
              authorize_policy!(::Identity::Policies::UserPolicy, :update, @user)
              user = ::Identity::Services::UserManager.update!(@user, user_params.to_h.symbolize_keys)
              render_success(data: ::Api::V1::Identity::Serializers::UserSerializer.render(user))
            end

            def destroy
              authorize_policy!(::Identity::Policies::UserPolicy, :destroy, @user)
              ::Identity::Services::UserManager.destroy!(@user)
              render_success(data: { deleted: true })
            end

            private

            def set_user
              @user = ::Identity::Models::User.includes(:roles, :profile).find(params[:id])
            end

            def user_params
              params.require(:user).permit(
                :email,
                :password,
                :password_confirmation,
                :status,
                :mfa_required,
                :first_name,
                :last_name,
                :phone,
                :document,
                :locale,
                :timezone,
                role_ids: []
              )
            end
          end
        end
      end
    end
  RUBY
)

write_identity_file(
  "app/interfaces/http/api/v1/identity/roles_controller.rb",
  <<~RUBY
    module Api
      module V1
        module Identity
          class RolesController < ::Api::BaseController
            before_action :authenticate_identity_user!
            before_action :set_role, only: %i[show update destroy]

            def index
              authorize_policy!(::Identity::Policies::RolePolicy, :index, ::Identity::Models::Role)
              roles = ::Identity::Models::Role.includes(:permissions).order(:id)
              render_success(data: roles.map { |role| ::Api::V1::Identity::Serializers::RoleSerializer.render(role) })
            end

            def show
              authorize_policy!(::Identity::Policies::RolePolicy, :show, @role)
              render_success(data: ::Api::V1::Identity::Serializers::RoleSerializer.render(@role))
            end

            def create
              authorize_policy!(::Identity::Policies::RolePolicy, :create, ::Identity::Models::Role)
              role = ::Identity::Services::RoleManager.create!(role_params.to_h.symbolize_keys)
              render_success(data: ::Api::V1::Identity::Serializers::RoleSerializer.render(role), status: :created)
            end

            def update
              authorize_policy!(::Identity::Policies::RolePolicy, :update, @role)
              role = ::Identity::Services::RoleManager.update!(@role, role_params.to_h.symbolize_keys)
              render_success(data: ::Api::V1::Identity::Serializers::RoleSerializer.render(role))
            end

            def destroy
              authorize_policy!(::Identity::Policies::RolePolicy, :destroy, @role)
              ::Identity::Services::RoleManager.destroy!(@role)
              render_success(data: { deleted: true })
            end

            private

            def set_role
              @role = ::Identity::Models::Role.includes(:permissions).find(params[:id])
            end

            def role_params
              params.require(:role).permit(:name, :slug, :description, permission_ids: [])
            end
          end
        end
      end
    end
  RUBY
)

write_identity_file(
  "app/interfaces/http/api/v1/identity/permissions_controller.rb",
  <<~RUBY
    module Api
      module V1
        module Identity
          class PermissionsController < ::Api::BaseController
            before_action :authenticate_identity_user!
            before_action :set_permission, only: %i[show update destroy]

            def index
              authorize_policy!(::Identity::Policies::PermissionPolicy, :index, ::Identity::Models::Permission)
              permissions = ::Identity::Models::Permission.order(:scope, :resource, :action)
              render_success(data: permissions.map { |permission| ::Api::V1::Identity::Serializers::PermissionSerializer.render(permission) })
            end

            def show
              authorize_policy!(::Identity::Policies::PermissionPolicy, :show, @permission)
              render_success(data: ::Api::V1::Identity::Serializers::PermissionSerializer.render(@permission))
            end

            def create
              authorize_policy!(::Identity::Policies::PermissionPolicy, :create, ::Identity::Models::Permission)
              permission = ::Identity::Services::PermissionManager.create!(permission_params.to_h.symbolize_keys)
              render_success(data: ::Api::V1::Identity::Serializers::PermissionSerializer.render(permission), status: :created)
            end

            def update
              authorize_policy!(::Identity::Policies::PermissionPolicy, :update, @permission)
              permission = ::Identity::Services::PermissionManager.update!(@permission, permission_params.to_h.symbolize_keys)
              render_success(data: ::Api::V1::Identity::Serializers::PermissionSerializer.render(permission))
            end

            def destroy
              authorize_policy!(::Identity::Policies::PermissionPolicy, :destroy, @permission)
              ::Identity::Services::PermissionManager.destroy!(@permission)
              render_success(data: { deleted: true })
            end

            private

            def set_permission
              @permission = ::Identity::Models::Permission.find(params[:id])
            end

            def permission_params
              params.require(:permission).permit(:resource, :action, :scope)
            end
          end
        end
      end
    end
  RUBY
)

write_identity_file(
  "app/interfaces/http/api/v1/identity/access_sessions_controller.rb",
  <<~RUBY
    module Api
      module V1
        module Identity
          class AccessSessionsController < ::Api::BaseController
            before_action :authenticate_identity_user!
            before_action :set_access_session, only: %i[show destroy]

            def index
              authorize_policy!(::Identity::Policies::AccessSessionPolicy, :index, ::Identity::Models::AccessSession)
              sessions = ::Identity::Models::AccessSession.includes(:user).order(last_seen_at: :desc)
              render_success(data: sessions.map { |session| ::Api::V1::Identity::Serializers::AccessSessionSerializer.render(session) })
            end

            def show
              authorize_policy!(::Identity::Policies::AccessSessionPolicy, :show, @access_session)
              render_success(data: ::Api::V1::Identity::Serializers::AccessSessionSerializer.render(@access_session))
            end

            def destroy
              authorize_policy!(::Identity::Policies::AccessSessionPolicy, :destroy, @access_session)
              ::Identity::Services::SessionManager.revoke!(@access_session)
              render_success(data: { revoked: true, session_id: @access_session.id })
            end

            private

            def set_access_session
              @access_session = ::Identity::Models::AccessSession.includes(:user).find(params[:id])
            end
          end
        end
      end
    end
  RUBY
)

create_file "db/seeds.rb", <<~RUBY, force: true
  admin_role = ::Identity::Models::Role.find_or_create_by!(slug: "admin") do |role|
    role.name = "Administrador"
    role.description = "Acesso total à API"
  end

  default_role = ::Identity::Models::Role.find_or_create_by!(slug: "default") do |role|
    role.name = "Padrão"
    role.description = "Acesso básico autenticado"
  end

  permission_definitions = [
    { scope: "api", resource: "auth", action: "login" },
    { scope: "api", resource: "auth", action: "refresh" },
    { scope: "api", resource: "auth", action: "logout" },
    { scope: "api", resource: "profile", action: "read" },
    { scope: "api", resource: "users", action: "read" },
    { scope: "api", resource: "users", action: "create" },
    { scope: "api", resource: "users", action: "update" },
    { scope: "api", resource: "users", action: "destroy" },
    { scope: "api", resource: "profiles", action: "read" },
    { scope: "api", resource: "profiles", action: "update" },
    { scope: "api", resource: "roles", action: "read" },
    { scope: "api", resource: "roles", action: "create" },
    { scope: "api", resource: "roles", action: "update" },
    { scope: "api", resource: "roles", action: "destroy" },
    { scope: "api", resource: "permissions", action: "read" },
    { scope: "api", resource: "permissions", action: "create" },
    { scope: "api", resource: "permissions", action: "update" },
    { scope: "api", resource: "permissions", action: "destroy" },
    { scope: "api", resource: "access_sessions", action: "read" },
    { scope: "api", resource: "access_sessions", action: "destroy" }
  ]

  permission_definitions.each do |permission_attributes|
    permission = ::Identity::Models::Permission.find_or_create_by!(permission_attributes)
    admin_role.permissions << permission unless admin_role.permissions.exists?(permission.id)
  end

  default_permissions = permission_definitions.select do |rule|
    [["auth", "login"], ["auth", "refresh"], ["auth", "logout"], ["profile", "read"]].include?([rule[:resource], rule[:action]])
  end

  default_permissions.each do |permission_attributes|
    permission = ::Identity::Models::Permission.find_or_create_by!(permission_attributes)
    default_role.permissions << permission unless default_role.permissions.exists?(permission.id)
  end

  admin_email = ENV.fetch("DEFAULT_ADMIN_EMAIL", "admin@example.com")
  admin_password = ENV.fetch("DEFAULT_ADMIN_PASSWORD", "ChangeMe123!")

  admin_user = ::Identity::Models::User.find_or_initialize_by(email: admin_email)
  admin_user.password = admin_password
  admin_user.password_confirmation = admin_password
  admin_user.status = "active"
  admin_user.build_profile(first_name: "Admin", last_name: "Sistema") unless admin_user.profile
  admin_user.save!
  admin_user.roles << admin_role unless admin_user.roles.exists?(admin_role.id)
RUBY

inject_into_file "config/application.rb", after: "config.api_only = true\n" do
  <<~RUBY

        config.generators do |generators|
          generators.helper false
          generators.assets false
          generators.orm :active_record, primary_key_type: :uuid
        end
  RUBY
end unless File.read("config/application.rb").include?("primary_key_type: :uuid")

say "Identidade base da API configurada diretamente por domínio.", :blue
