# frozen_string_literal: true

gsub_file "config/application.rb", 'config.autoload_lib(ignore: %w[assets tasks])', 'config.autoload_lib(ignore: %w[assets tasks generators])'
gsub_file "config/application.rb",
          'config.autoload_lib(ignore: %w[assets tasks generators])',
          <<~RUBY.chomp
            config.autoload_lib(ignore: %w[assets tasks generators])
            config.autoload_paths << Rails.root.join("app/domains/identity/infrastructure/active_record/models")
            config.eager_load_paths << Rails.root.join("app/domains/identity/infrastructure/active_record/models")
            config.autoload_paths << Rails.root.join("app/domains/shared/infrastructure/active_record/models")
            config.eager_load_paths << Rails.root.join("app/domains/shared/infrastructure/active_record/models")
            
            # Autoload Presentation Controllers
            config.autoload_paths << Rails.root.join("app/domains/identity/presentation/controllers")
            config.eager_load_paths << Rails.root.join("app/domains/identity/presentation/controllers")
            config.autoload_paths << Rails.root.join("app/domains/shared/presentation/controllers")
            config.eager_load_paths << Rails.root.join("app/domains/shared/presentation/controllers")
          RUBY

initializer "zeitwerk_ddd_roots.rb", <<~RUBY
  domains_root = Rails.root.join("app/domains")
  identity_models_root = Rails.root.join("app/domains/identity/infrastructure/active_record/models")
  shared_models_root = Rails.root.join("app/domains/shared/infrastructure/active_record/models")
  
  identity_controllers_root = Rails.root.join("app/domains/identity/presentation/controllers")
  shared_controllers_root = Rails.root.join("app/domains/shared/presentation/controllers")

  Rails.autoloaders.main.ignore(domains_root)
  Rails.autoloaders.main.ignore(identity_models_root)
  Rails.autoloaders.main.ignore(shared_models_root)
  Rails.autoloaders.main.ignore(identity_controllers_root)
  Rails.autoloaders.main.ignore(shared_controllers_root)

  Rails.autoloaders.main.push_dir(domains_root)
  Rails.autoloaders.main.push_dir(identity_controllers_root)
  Rails.autoloaders.main.push_dir(shared_controllers_root)

  Rails.application.config.to_prepare do
    Dir[Rails.root.join("app/domains/*/presentation/controllers/**/*.rb")].sort.each { |path| require_dependency path }
    Dir[Rails.root.join("app/domains/*/presentation/serializers/**/*.rb")].sort.each { |path| require_dependency path }
    Dir[Rails.root.join("app/domains/*/presentation/forms/**/*.rb")].sort.each { |path| require_dependency path }
  end
RUBY
